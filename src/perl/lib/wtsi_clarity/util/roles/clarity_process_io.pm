package wtsi_clarity::util::roles::clarity_process_io;

use Moose::Role;
use Carp;
use Readonly;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_OUTPUT_PATH   => q{prc:process/input-output-map};
Readonly::Scalar my $ALL_ANALYTES        => q(prc:process/input-output-map/output[@output-type!="ResultFile"]/@uri | prc:process/input-output-map/input/@uri);
Readonly::Scalar my $ARTIFACT_BY_LIMSID  => q{art:details/art:artifact[@limsid="%s"]};
Readonly::Scalar my $CONTAINER_BY_LIMSID => q{con:details/con:container[@limsid="%s"]};
Readonly::Scalar my $INPUT_LIMSID        => q{./input/@limsid};
Readonly::Scalar my $OUTPUT_LIMSID       => q{./output/@limsid};
Readonly::Scalar my $ALL_CONTAINERS      => q{art:details/art:artifact/location/container/@uri};
## use critic

has 'io_map' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  lazy_build => 1,
);

sub _build_io_map {
  my $self = shift;
  my @mapping = map { $self->_build_mapping($_); } @{$self->_input_output_map};
  return \@mapping;
}

has ['plate_io_map', 'plate_io_map_barcodes'] => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  lazy_build => 1,
);

sub _build_plate_io_map {
  my $self = shift;
  my @plate_mapping = ();
  my @all_plates = ();

  foreach my $io_mapping (@{$self->io_map}) {

    next if $self->_in_plate_mapping(\@plate_mapping, $io_mapping);

    push @plate_mapping, {
      source_plate => $io_mapping->{'source_plate'},
      dest_plate   => $io_mapping->{'dest_plate'}
    };
  }

  return \@plate_mapping;
}

sub _build_plate_io_map_barcodes {
  my $self = shift;
  my @plate_io_map_barocodes = map { $self->_get_plate_barcode($_) } @{$self->plate_io_map};
  return \@plate_io_map_barocodes;
}

sub _get_plate_barcode {
  my ($self, $plate_io_map) = @_;

  my $source_plate = $self->_containers->findnodes(sprintf $CONTAINER_BY_LIMSID, $plate_io_map->{'source_plate'})->pop();
  my $dest_plate =   $self->_containers->findnodes(sprintf $CONTAINER_BY_LIMSID, $plate_io_map->{'dest_plate'})->pop();

  return {
    'source_plate' => $source_plate->findvalue('./name'),
    'dest_plate'   => $dest_plate->findvalue('./name'),
  };
}

sub _in_plate_mapping {
  my ($self, $plate_mapping, $io_mapping) = @_;

  foreach my $plate_io (@{$plate_mapping}) {
    if ($plate_io->{'source_plate'} eq $io_mapping->{'source_plate'}
      && $plate_io->{'dest_plate'} eq $io_mapping->{'dest_plate'}) {
      return 1;
    }
  }

  return 0;
}

sub _build_mapping {
  my ($self, $tuple) = @_;

  my $input_analyte = $self->_analytes->findnodes(sprintf $ARTIFACT_BY_LIMSID, $tuple->[0])->pop();
  my $output_analyte = $self->_analytes->findnodes(sprintf $ARTIFACT_BY_LIMSID, $tuple->[1])->pop();

  ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  return {
    'source_plate' => $input_analyte->findvalue('./location/container/@limsid'),
    'source_well'  => $input_analyte->findvalue('./location/value'),
    'source_well_sample_limsid' => $input_analyte->findvalue('./sample/@limsid'),
    'dest_plate'   => $output_analyte->findvalue('./location/container/@limsid'),
    'dest_well'    => $output_analyte->findvalue('./location/value'),
  };
}

has '_input_output_map' => (
  is => 'ro',
  isa => 'ArrayRef[ArrayRef]',
  lazy_build => 1,
);

sub _build__input_output_map {
  my $self = shift;

  my @input_output_map = map {
    [$_->findvalue($INPUT_LIMSID), $_->findvalue($OUTPUT_LIMSID)]
  } $self->process_doc->findnodes($INPUT_OUTPUT_PATH)->get_nodelist;

  return \@input_output_map;
}

has '_containers' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__containers {
  my $self = shift;
  my @all_container_uris = $self->_analytes->findnodes($ALL_CONTAINERS)->to_literal_list;
  return $self->request->batch_retrieve('containers', \@all_container_uris);
}

has '_analytes' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__analytes {
  my $self = shift;
  my @all_analyte_uris = $self->findnodes($ALL_ANALYTES)->to_literal_list;
  return $self->request->batch_retrieve('artifacts', \@all_analyte_uris);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::roles::clarity_process_io

=head1 SYNOPSIS

  with 'wtsi_clarity::util::roles::clarity_process_io';

  $self->io_map();

=head1 DESCRIPTION

  Role that describes the inputs and outputs of a Clarity process in a simple.

=head1 SUBROUTINES/METHODS

=head2 io_map
  Returns an array of hashes which describe the inputs/outputs of a process
    e.g. [
      {source_plate => 123, source_well => 'A1', dest_plate => 456, dest_well => 'A1'},
      {source_plate => 123, source_well => 'B1', dest_plate => 456, dest_well => 'B1'},
    ]

=head2 plate_io_map
  Uses the io_map to describe the input/output containers of a process
    e.g. [
      {source_plate => 123, dest_plate => 456},
      {source_plate => 123, dest_plate => 789}
    ]

=head2 plate_io_map_barcodes
  Returns the same as the plate_io_map but with the container name (i.e. an EAN13 barcode) instead of limsids
    e.g. [
      {source_plate => 1234567891012, dest_plate => 9876543212345},
      {source_plate => 1234567891012, dest_plate => 2649374928273}
    ]

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role;

=item Carp;

=item Readonly;

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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