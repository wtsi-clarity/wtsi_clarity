package wtsi_clarity::clarity::process;

use Moose;
use Readonly;
use Carp;
use List::MoreUtils qw/uniq/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PARENT_PROCESS_PATH => q( /prc:process/input-output-map/input/parent-process/@uri );
Readonly::Scalar my $PROCESS_TYPE => q( /prc:process/type );
Readonly::Scalar my $PROCESS_URI_PATH => q(/prc:processes/process/@uri);
Readonly::Scalar my $INPUT_ARTIFACT_URIS_PATH => q{/prc:process/input-output-map/input/@uri};
Readonly::Scalar my $INPUT_OUTPUT_PATH   => q{prc:process/input-output-map};
Readonly::Scalar my $ALL_ANALYTES        => q(prc:process/input-output-map/output[@output-type!="ResultFile"]/@uri | prc:process/input-output-map/input/@uri);
Readonly::Scalar my $ARTIFACT_BY_LIMSID  => q{art:details/art:artifact[@limsid="%s"]};
Readonly::Scalar my $CONTAINER_BY_LIMSID => q{con:details/con:container[@limsid="%s"]};
Readonly::Scalar my $INPUT_LIMSID        => q{./input/@limsid};
Readonly::Scalar my $OUTPUT_LIMSID       => q{./output[@output-type!="ResultFile"]/@limsid};
Readonly::Scalar my $ALL_CONTAINERS      => q{art:details/art:artifact/location/container/@uri};
## use critic

has '_parent' => (
  is => 'ro',
  isa => 'Object',
  required => 1,
  init_arg => 'parent',
);

has '_config' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::config',
  required => 0,
  init_arg => undef,
  lazy_build => 1,
);
sub _build__config {
  my $self = shift;
  return $self->_parent->config;
}

has '_request' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::request',
  required => 0,
  init_arg => undef,
  lazy_build => 1,
);
sub _build__request {
  my $self = shift;
  return $self->_parent->request;
}

has 'xml' => (
  is => 'rw',
  isa => 'XML::LibXML::Document',
  required => 1,
  init_arg => 'xml',
  handles => {
    find               => 'find',
    findvalue          => 'findvalue',
    findnodes          => 'findnodes',
    toString           => 'toString',
    getDocumentElement => 'getDocumentElement',
    createElementNS    => 'createElementNS',
  },
);

has 'input_artifacts' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_input_artifacts {
  my $self = shift;

  my $input_node_list = $self->findnodes($INPUT_ARTIFACT_URIS_PATH);
  my @input_uris = uniq(map { $_->getValue } $input_node_list->get_nodelist);

  return $self->_request->batch_retrieve('artifacts', \@input_uris);
}

sub find_parent {
  my ($self, $needle_process_name, $child_process_url) = @_;

  my $parent_processes = $self->_find_parent($needle_process_name, $child_process_url);

  return $parent_processes;
}

sub _find_parent {
  my ($self, $needle_process_name, $process_url, $found_processes) = @_;

  if (!defined $found_processes) {
    $found_processes = {};
  }

  my $current_process = $self->_parent->fetch_and_parse($process_url);

  my $current_process_name = $current_process->findvalue($PROCESS_TYPE);

  if ($current_process_name eq $needle_process_name) {
    $found_processes->{$process_url} = q{};
  } else {
    my $parent_uris = $current_process->findnodes($PARENT_PROCESS_PATH);

    if ($parent_uris->size() > 0) {
      my @uniq_uris = map { $_->getValue() } $parent_uris->get_nodelist();

      foreach my $uri (@uniq_uris) {
        $self->_find_parent($needle_process_name, $uri, $found_processes);
      }
    }
  }

  my @found_processes = keys %{$found_processes};

  return \@found_processes;
}

sub find_previous_process {
  my ($self, $artifact_limsid, $process_name) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . '/processes/?inputartifactlimsid=' . $artifact_limsid;
  my $process_list_xml = $self->_parent->fetch_and_parse($uri);

  my @processes = $process_list_xml->findnodes($PROCESS_URI_PATH)->get_nodelist();

  foreach my $process_uri (@processes) {
    my $process_xml = $self->_parent->fetch_and_parse($process_uri->getValue());

    my $process_type = $process_xml->findvalue($PROCESS_TYPE);

    if ($process_type eq $process_name) {
      return $process_xml;
    }
  }

  return 0;
}

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

  my @input_output_map =
    map {
      [$_->findvalue($INPUT_LIMSID), $_->findvalue($OUTPUT_LIMSID)]
    } grep {
      $_->findvalue($OUTPUT_LIMSID)
    } $self->xml->findnodes($INPUT_OUTPUT_PATH)->get_nodelist;

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
  return $self->_request->batch_retrieve('containers', \@all_container_uris);
}

has '_analytes' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__analytes {
  my $self = shift;
  my @all_analyte_uris = $self->findnodes($ALL_ANALYTES)->to_literal_list;
  return $self->_request->batch_retrieve('artifacts', \@all_analyte_uris);
}

1;

__END__

=head1 NAME

wtsi_clarity::clarity::process

=head1 SYNOPSIS

  use wtsi_clarity::clarity::process;
  wtsi_clarity::clarity::process->new(parent => $self, xml => $xml_doc);

=head1 DESCRIPTION

  Class to wrap a process XML from Clarity with some convinient attributes and methods

=head1 SUBROUTINES/METHODS

=head2 find_parent
  Requires the name of the parent process being searched for, and the URL of the child process.
  Keeps recursing up parent processes until it finds the one being searched for

=head2 find_previous_process
  Takes a artifact limsid and a process name. Tries to find the specifed process xml in that artifact's
  history (using the ?inputartifactlimsid URL parameter)

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

=item Moose::Role

=item Readonly

=item List::MoreUtils

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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