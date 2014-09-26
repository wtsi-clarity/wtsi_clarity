package wtsi_clarity::epp::generic::bed_verifier;

use Moose;
use Carp;
use Readonly;
use File::Spec::Functions;
use File::Slurp;
use English qw( -no_match_vars );
use JSON;
use Try::Tiny;

use wtsi_clarity::util::config;
use wtsi_clarity::process_checks::bed_verifier;

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
Readonly::Scalar my $SUCCESS_PATH           => q[ /prc:process/udf:field[@name="Bed Verification Successful"]];
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

  if ($rbc eq q{}) {
    croak qq[Robot ID must be set for bed verification\n];
  }

  return $rbc;
}

has 'step_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

sub _get_input_plates {
  my $self = shift;
  my $nodes = $self->process_doc->findnodes($BEDS_PATH);

  if ($nodes->size() == 0) {
    croak qq[Could not find any input plates\n];
  }

  my %h = ();
  my @plates = ();

  foreach my $plate ($nodes->get_nodelist) {
    my $plate_name = $self->_extract_plate_name($plate->findvalue('@name'), 0);

    # If it has a letter at the end
    if ($plate_name =~ /[[:lower:]]$/sxm) {
      # Pop the letter off
      chop $plate_name;

      # Add name as a key to some hash
      if (exists $h{$plate_name} ) {
        next;
      }

      # Search for other plates with "same" name
      my $grouped_plates =
        $self
          ->process_doc
          ->findnodes(qq[/prc:process/udf:field[starts-with(\@name, "Bed") and contains(\@name, "$plate_name")]]);

      # Add result as list on hash value
      $h{ $plate_name } = $grouped_plates;

    # else just add it to the array
    } else {
      push @plates, [$plate];
    }
  }

  foreach my $plate_set (values %h) {
    push @plates, $plate_set;
  }

  return \@plates;
}

# Get plate name from between brackets
sub _extract_plate_name {
  my ($self, $bed_name, $chop_end) = @_;

  if ( $bed_name =~ /[(](.*?)[)]/sxm ) {
    my $input_plate_name = $1;

    # Pop the letter off if it ends with one
    if ($chop_end && $input_plate_name =~ /[[:lower:]]$/sxm) {
      chop $input_plate_name;
    }

    return $input_plate_name;
  }

  croak qq[Could not find matching plate name for $bed_name\n];
}

sub _extract_bed_number {
  my ($self, $bed_name) = @_;
  my $plate_number;

  if ( $bed_name =~ /(\d+)/sxm ) {
    $plate_number = $1;
  } else {
    croak qq[Plate number not found\n];
  }

  return $plate_number;
}

sub _get_output_plate_from_input {
  my ($self, $input_plate_name) = @_;

  # Search and replace to find the output
  $input_plate_name =~ s/Input/Output/gsm;

  # my $output_path = qq [ /prc:process/udf:field[starts-with(\@name, 'Bed') and contains(\@name, '$input_plate_name')] ];
  my $output_path = qq [ /prc:process/udf:field[contains(\@name, '$input_plate_name')] and starts-with(\@name, 'Bed')];

  my $output_plate_list = $self->process_doc->findnodes($output_path);

  if ($output_plate_list->size() == 0) {
    croak "Could not find output plate $input_plate_name\n";
  }

  return $output_plate_list;
}

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
  my $beds = $self->_get_input_plates();

  foreach my $node_list (@{ $beds }) {

    my @source = map {
      {
        bed => $self->_extract_bed_number($_->findvalue('@name')),
        barcode => $_->textContent()
      }
    } @{$node_list};

    my $input_plate_name = $self->_extract_plate_name(@{$node_list}[0]->findvalue('@name'), 1);
    my $output_plates = $self->_get_output_plate_from_input($input_plate_name);

    my @destination = map {
      {
        bed     => $self->_extract_bed_number($_->findvalue('@name')),
        barcode => $_->textContent()
      };
    } $output_plates->get_nodelist();

    push @mappings, { source => \@source, destination => \@destination };
  }

  return \@mappings;
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
    or croak qq[Could not retrive the configuration file at $file_path\n];
  local $RS = undef;
  my $json_text = <$fh>;
  close $fh
    or croak qq[Could not close handle to $file_path\n];
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
    $container_input_output_map->{$input_container_uri}->{$output_container_uri} = 1;
  }

  return $container_input_output_map;
}

override 'run' => sub {
  my $self = shift;
  super();

  my $verified = 0;
  try {
    $verified = $self->_verify();
  } catch {
    $self->epp_log("Bed verification error $_");
  };

  if (!$verified) {
    $self->_punish_user_by_resetting_everything();
    croak "Bed verification has failed\n";
  }

  return;
};

sub _verify {
  my $self = shift;

  my $v = wtsi_clarity::process_checks::bed_verifier->new(config => $self->_bed_config_file);

  return $v->verify($self->step_name, $self->_robot_barcode, $self->_bed_container_pairs)
          && $self->_verify_plates_positioned_correctly();
}

sub _verify_plates_positioned_correctly {
  my $self = shift;
  my $barcode_map = $self->_barcode_map();

  foreach my $input_plate (keys %{$barcode_map}) {
    my $input_elem = $self->process_doc->findnodes( qq[ prc:process/udf:field[text()='$input_plate']]);

    if ($input_elem->size() == 0) {
      croak qq[Could not find plate with barcode $input_plate\n];
    }

    my $input_elem_name = $input_elem->pop()->findvalue('@name');
    # Convert to output
    $input_elem_name =~ s/Input/Output/gsm;
    my $output_elem_value = $self->process_doc->findvalue( qq[ prc:process/udf:field[\@name='$input_elem_name']]);

    if ($output_elem_value eq q{}) {
      croak qq[Could not find the field for plate $input_elem_name\n];
    }

    my $output_plate = $barcode_map->{ $input_plate }[0];

    if ($output_elem_value ne $output_plate) {
      return 0;
    }
  }

  return 1;
}

sub _punish_user_by_resetting_everything {
  my $self = shift;

  my $all_plates = $self->process_doc->findnodes($ALL_PLATES);

  map { $self->update_text($_, q{}); } $all_plates->get_nodelist();

  $self->request->put($self->process_url, $self->process_doc->toString);

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::bed_verifier

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::bed_verifier->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Checks that plates have been placed in the correct beds for various processes

=head1 SUBROUTINES/METHODS

=head2 run - callback for the bed_verifier action

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
