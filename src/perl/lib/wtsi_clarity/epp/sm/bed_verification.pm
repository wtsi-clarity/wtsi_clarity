package wtsi_clarity::epp::sm::bed_verification;

use Moose;
use Carp;
use Readonly;
use List::MoreUtils qw / uniq /;

our $VERSION = '0.0';

Readonly::Scalar my $INPUT_OUTPUT_MAP_PATH  => q [ //input-output-map ];
Readonly::Scalar my $INPUT_URI_PATH         => q [ input/@uri ];
Readonly::Scalar my $OUTPUT_URI_PATH        => q [ output/@uri ];
Readonly::Scalar my $ANALYTE_PATH           => q [ //art:artifact ];
Readonly::Scalar my $ANALYTE_CONTAINER_PATH => q [ //location/container/@uri ];
Readonly::Scalar my $CONTROL_PATH           => q [ //control-type ];
Readonly::Scalar my $CONTAINER_NAME         => q [ //name ];

extends 'wtsi_clarity::epp';

override 'run' => sub {
  my $self = shift;
  super();

  use Data::Dumper;
  
  my $container_map = $self->_fetch_container_map();
  my $container_map_barcodes = $self->_fetch_barcodes_for_map($container_map);

  #my $beds = $self->_fetch_beds();

  return 1;
};

sub _fetch_container_map {
  my $self = shift;
  my %container_input_output_map;

  foreach my $input_output_map ($self->process_doc->findnodes($INPUT_OUTPUT_MAP_PATH)) {
    my $input_uri = $input_output_map->findnodes($INPUT_URI_PATH)->pop()->getValue();
    my $output_uri = $input_output_map->findnodes($OUTPUT_URI_PATH)->pop()->getValue();

    my $input = $self->fetch_and_parse($input_uri);
    my $output = $self->fetch_and_parse($output_uri);

    # Ignore analyte if it's a control
    if ($input->findnodes($CONTROL_PATH)->size() > 0) {
      next;
    }

    my $input_container_uri = $input->findnodes($ANALYTE_CONTAINER_PATH)->pop()->getValue();
    my $output_container_uri = $output->findnodes($ANALYTE_CONTAINER_PATH)->pop()->getValue();

    if (exists $container_input_output_map{ $input_container_uri }) {
      if ($container_input_output_map{ $input_container_uri } ne $output_container_uri) {
        croak "Something has gone very wrong";
      }
    }
      
    $container_input_output_map{ $input_container_uri } = $output_container_uri;
  }

  return \%container_input_output_map;
}

sub _fetch_barcodes_for_map {
  my ($self, $container_map_barcodes) = @_;
  my %barcodes_map;

  foreach my $key (keys %$container_map_barcodes) {
    my $input_container = $self->fetch_and_parse($key);
    my $output_container = $self->fetch_and_parse($container_map_barcodes->{$key});

    my $input_barcode = $input_container->findnodes($CONTAINER_NAME)->pop()->textContent;
    my $output_barcode = $output_container->findnodes($CONTAINER_NAME)->pop()->textContent;

    $barcodes_map{$input_barcode} = $output_barcode;
  }

  return \%barcodes_map;
}

sub _fetch_beds {
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
