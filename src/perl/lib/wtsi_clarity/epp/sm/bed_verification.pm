package wtsi_clarity::epp::sm::bed_verification;

use Moose;
use Carp;
use Readonly;
use File::Spec::Functions;
use File::Slurp;
use JSON;
use Try::Tiny;
#use List::MoreUtils qw / uniq /;

use wtsi_clarity::util::config;
use wtsi_clarity::process_checks::bed_verification;

our $VERSION = '0.0';

Readonly::Scalar my $INPUT_OUTPUT_MAP_PATH  => q[ //input-output-map ];
Readonly::Scalar my $INPUT_URI_PATH         => q[ input/@uri ];
Readonly::Scalar my $OUTPUT_URI_PATH        => q[ output/@uri ];
Readonly::Scalar my $ANALYTE_PATH           => q[ //art:artifact ];
Readonly::Scalar my $ANALYTE_CONTAINER_PATH => q[ //location/container/@uri ];
Readonly::Scalar my $CONTROL_PATH           => q[ //control-type ];
Readonly::Scalar my $CONTAINER_NAME         => q[ //name ];

Readonly::Scalar my $BED_VERIFICATION_CONFIG => q[bed_verification.json];

extends 'wtsi_clarity::epp';

has '_container_layout' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container_layout {
  my $self = shift;
  
  return [];
}

has '_bed_layout' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__bed_layout {
  my $self = shift;
  
  return [];
}

has '_bed_config_file' => (
  isa        => 'WtsiClarityReadableFile',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__bed_config_file {
  my $self = shift;
  return catfile($self->config->dir_path, $BED_VERIFICATION_CONFIG);
}

has '_bed_config_file' => (
  isa        => 'WtsiClarityReadableFile',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__bed_config_file {
  my $self = shift;
  return catfile($self->config->dir_path, $BED_VERIFICATION_CONFIG);
}

override 'run' => sub {
  my $self = shift;
  super();
  
  my $container_map = $self->_fetch_container_map();
  my $container_map_barcodes = $self->_fetch_barcodes_for_map($container_map);

  my $verified = 0;
  try {
    $verified = $self->verify();
  } catch {
    $self->epp_log("Bed verification error $_");
  };

  if {
    $self->_update_step();
  } else {
    warn 'Bed veryfication has failed for ' . $self->toString;
  }
  
  return;
};

sub _verify {
  my $self = shift;
  my $conf = decode_json(read_file($self->bed_config_file));
  my $v = wtsi_clarity::process_checks::bed_verification->new($conf);
  return $v->verify($self->_process_name4bebver, $self->_robot_id, $self->_bed_layout);
}

sub _update_step {
  my $self = shift;
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

sub _fetch_barcodes_for_map {
  my ($self, $container_map_barcodes) = @_;
  my $barcodes_map;

  foreach my $input_url (keys %{$container_map_barcodes}) {
    my $input_container = $self->fetch_and_parse($input_url);
    my $input_barcode = $input_container->findnodes($CONTAINER_NAME)->pop()->textContent;
    
    foreach my $output_url (keys %{$container_map_barcodes->{$input_url}}) {
      my $output_container = $self->fetch_and_parse($container_map_barcodes->{$output_url});
      my $output_barcode = $output_container->findnodes($CONTAINER_NAME)->pop()->textContent;
      push @{$barcodes_map->{$input_barcode}}, $output_barcode;
    }
  }

  return $barcodes_map;
}

sub _fetch_process_beds {
  my $self = shift;

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
