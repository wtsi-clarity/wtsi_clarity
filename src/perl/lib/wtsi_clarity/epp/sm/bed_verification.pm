package wtsi_clarity::epp::sm::bed_verification;

use Moose;
use Carp;
use Readonly;
use File::Spec::Functions;
use File::Slurp;
use English qw( -no_match_vars );
use JSON;
use Try::Tiny;

use wtsi_clarity::util::config;
use wtsi_clarity::process_checks::bed_verification;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_OUTPUT_MAP_PATH  => q[ //input-output-map ];
Readonly::Scalar my $INPUT_URI_PATH         => q[ input/@uri ];
Readonly::Scalar my $OUTPUT_URI_PATH        => q[ output/@uri ];
Readonly::Scalar my $ANALYTE_PATH           => q[ //art:artifact ];
Readonly::Scalar my $ANALYTE_CONTAINER_PATH => q[ //location/container/@uri ];
Readonly::Scalar my $CONTROL_PATH           => q[ //control-type ];
Readonly::Scalar my $CONTAINER_NAME         => q[ //name ];
Readonly::Scalar my $ROBOT_BARCODE_PATH     => q[ /prc:process/udf:field[@name="Robot ID"] ];
Readonly::Scalar my $BEDS_PATH              => q[ /prc:process/udf:field[starts-with(@name, "Bed") and contains(@name, "Input Plate")] ];
Readonly::Scalar my $ALL_PLATES             => q[ /prc:process/udf:field[contains(@name, "Input Plate") or contains(@name, "Output Plate")] ];
## use critic

Readonly::Scalar my $BED_VERIFICATION_CONFIG => q[bed_verification.json];

with 'wtsi_clarity::util::clarity_elements';
extends 'wtsi_clarity::epp';

has '_robot_barcode' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__robot_barcode {
  my $self = shift;
  my $rbc = $self->process_doc->findvalue($ROBOT_BARCODE_PATH);

  ## no critic(ValuesAndExpressions::ProhibitEmptyQuotes)
  if ($rbc eq '') {
    croak q[Robot ID must be set for bed verification];
  }
  ## use critic

  return $rbc;
}

has 'step_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_bed_container_pairs' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__bed_container_pairs {
  my $self = shift;
  my @mappings = ();

  # get all wtsi fields having 'Bed', get barcodes of beds
  my $beds = $self->process_doc->findnodes($BEDS_PATH);

  foreach my $node ($beds->get_nodelist) {
    my %pair = ();
    my $bed_name = $node->findvalue('@name');
    my $input_plate_name;
    my $input_plate_number;

    # Get plate name from between brackets
    if ( $bed_name =~ /[(](.*?)[)]/sxm ) {
      $input_plate_name = $1;
    } else {
      croak qq[Could not find matching plate name for $bed_name];
    }

    # Get the plate number
    $input_plate_number = $self->_get_plate_number($bed_name);

    # Search and replace to find the output
    $input_plate_name =~ s/Input/Output/gsm;

    my $output_path = qq [ /prc:process/udf:field[contains(\@name, '$input_plate_name') and starts-with(\@name, 'Bed')] ];

    my $output_plate = $self
                        ->process_doc
                        ->findnodes($output_path)
                        ->pop();

    my $output_plate_number = $self->_get_plate_number($output_plate->findvalue('@name'));

    my @source = ({
      bed => $input_plate_number,
      barcode => $node->textContent()
    });

    my @destination = ({
      bed => $output_plate_number,
      barcode => $output_plate->textContent()
    });

    push @mappings, { source => \@source, destination => \@destination };
  }

  return \@mappings;
}

sub _get_plate_number {
  my ($self, $bed_name) = @_;
  my $plate_number;

  if ( $bed_name =~ /(\d+)/sxm ) {
    $plate_number = $1;
  } else {
    croak q[Plate number not found];
  }

  return $plate_number;
}

has '_bed_config_file' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__bed_config_file {
  my $self = shift;
  my $file_path = catfile($self->config->dir_path, $BED_VERIFICATION_CONFIG);
  open my $fh, '<:encoding(UTF-8)', $file_path
    or croak qq[Could not retrive the configuration file at $file_path];
  local $RS = undef;
  my $json_text = <$fh>;
  close $fh
    or croak qq[Could not close handle to $file_path];
  return decode_json($json_text);
}

has '_barcode_map' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__barcode_map {
  my $self = shift;
  my $container_map_barcodes = $self->_fetch_container_map;
  my $barcodes_map;

  foreach my $input_url (keys %{$container_map_barcodes}) {
    my $input_container = $self->fetch_and_parse($input_url);
    my $input_barcode = $input_container->findnodes($CONTAINER_NAME)->pop()->textContent;

    foreach my $output_url (keys %{$container_map_barcodes->{$input_url}}) {
      my $output_container = $self->fetch_and_parse($output_url);
      my $output_barcode = $output_container->findnodes($CONTAINER_NAME)->pop()->textContent;
      push @{$barcodes_map->{$input_barcode}}, $output_barcode;
    }
  }

  return $barcodes_map;
}

override 'run' => sub {
  my $self = shift;
  super();

  $self->_punish_user_by_resetting_everything();
  die;

  my $verified = 0;
  try {
    $verified = $self->_verify();
  } catch {
    $self->epp_log("Bed verification error $_");
  };

  if ($verified) {
    $self->_update_step(); #tick the box
  } else {
    $self->_punish_user_by_resetting_everything();
    carp 'Bed verification has failed for ' . $self->toString;
  }

  return;
};

sub _verify {
  my $self = shift;

  my $v = wtsi_clarity::process_checks::bed_verification->new(config => $self->_bed_config_file);

  return $v->verify($self->step_name, $self->_robot_barcode, $self->_bed_container_pairs)
          && $self->_verify_plates_positioned_correctly();
}

sub _verify_plates_positioned_correctly {
  my $self = shift;
  my $barcode_map = $self->_barcode_map();

  foreach my $input_plate (keys %{$barcode_map}) {
    my $input_elem = $self->process_doc->findnodes( qq[ prc:process/udf:field[text()='$input_plate']]);

    if ($input_elem->size() == 0) {
      croak qq[Could not find plate with barcode $input_plate];
    }

    my $input_elem_name = $input_elem->pop()->findvalue('@name');
    # Convert to output
    $input_elem_name =~ s/Input/Output/gsm;
    my $output_elem_value = $self->process_doc->findvalue( qq[ prc:process/udf:field[\@name='$input_elem_name']]);

    ## no critic(ValuesAndExpressions::ProhibitEmptyQuotes)
    if ($output_elem_value eq '') {
      croak qq[Could not find the field for plate $input_elem_name];
    }
    ## use critic

    my $output_plate = $barcode_map->{ $input_plate }[0];

    if ($output_elem_value ne $output_plate) {
      return 0;
    }
  }

  return 1;
}

sub _update_step {
  my $self = shift;
  return;
}

sub _punish_user_by_resetting_everything {
  my $self = shift;

  my $all_plates = $self->process_doc->findnodes($ALL_PLATES);

  foreach my $plate ($all_plates->get_nodelist()) {
    $self->update_text($plate, '');
  }

  $self->request->update($self->process_url, $self->process_doc);

  return;
}

sub _fetch_container_map {
  my $self = shift;
  my $container_input_output_map;

  foreach my $input_output_map ($self->process_doc->findnodes($INPUT_OUTPUT_MAP_PATH)) {
    my $input_uri = $input_output_map->findnodes($INPUT_URI_PATH)->pop()->getValue();
    my $input = $self->fetch_and_parse($input_uri);
    if ($input->findnodes($CONTROL_PATH)->size() > 0) { #Ignore analyte if it's a control
      next;
    }
    my $output_uri = $input_output_map->findnodes($OUTPUT_URI_PATH)->pop()->getValue();
    my $output = $self->fetch_and_parse($output_uri);

    my $input_container_uri = $input->findnodes($ANALYTE_CONTAINER_PATH)->pop()->getValue();
    my $output_container_uri = $output->findnodes($ANALYTE_CONTAINER_PATH)->pop()->getValue();
    $container_input_output_map->{ $input_container_uri }->{$output_container_uri} = 1;
  }

  return $container_input_output_map;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::bed_verification

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::bed_verification->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Checks that plates have been placed in the correct beds for various processes

=head1 SUBROUTINES/METHODS

=head2 run - callback for the bed_verification action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item File::Spec::Functions

=item JSON

=item Try::Tiny

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
