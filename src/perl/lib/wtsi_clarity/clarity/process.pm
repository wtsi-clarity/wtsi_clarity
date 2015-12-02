package wtsi_clarity::clarity::process;

use Moose;
use Readonly;
use Carp;
use List::Util qw/reduce/;
use List::MoreUtils qw/uniq/;
use URI::Escape;
use wtsi_clarity::util::types;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_ARTIFACT_URI_PATH     => q{/prc:process/input-output-map/output[@output-type="Analyte"]/@uri};
Readonly::Scalar my $PARENT_PROCESS_PATH          => q( /prc:process/input-output-map/input/parent-process/@uri );
Readonly::Scalar my $PROCESS_TYPE                 => q( /prc:process/type );
Readonly::Scalar my $PROCESS_LIMSID_PATH          => q(/prc:processes/process/@limsid);
Readonly::Scalar my $INPUT_ARTIFACT_URIS_PATH     => q{/prc:process/input-output-map/input/@uri};
Readonly::Scalar my $INPUT_ANALYTES_URIS_PATH     => q{prc:process/input-output-map/output[@output-type!="ResultFile"]/../input/@uri};
Readonly::Scalar my $INPUT_OUTPUT_PATH            => q{prc:process/input-output-map};
Readonly::Scalar my $ALL_ANALYTES                 => q(prc:process/input-output-map/output[@output-type!="ResultFile"]/@uri | prc:process/input-output-map/input/@uri);
Readonly::Scalar my $INPUT_ANALYTES               => q(prc:process/input-output-map/input/@uri);
Readonly::Scalar my $ARTIFACT_BY_LIMSID           => q{art:details/art:artifact[@limsid="%s"]};
Readonly::Scalar my $CONTAINER_BY_LIMSID          => q{con:details/con:container[@limsid="%s"]};
Readonly::Scalar my $INPUT_LIMSID                 => q{./input/@limsid};
Readonly::Scalar my $OUTPUT_LIMSID                => q{./output[@output-type!="ResultFile"]/@limsid};
Readonly::Scalar my $ALL_CONTAINERS               => q{art:details/art:artifact/location/container/@uri};
Readonly::Scalar my $CONTAINER_URI_PATH           => q{/art:artifact/location/container/@uri};
Readonly::Scalar my $PLACEMENTS_URI_PATH          => q{/con:container/placement/@uri};
Readonly::Scalar my $RESULT_FILE_URI              => q{(prc:process/input-output-map/output[@output-type="ResultFile"]/@uri)[1]};
Readonly::Scalar my $FILE_URL_PATH                => q(/art:artifact/file:file/@uri);
Readonly::Scalar our $FILE_CONTENT_LOCATION       => q(/file:file/content-location);
Readonly::Scalar my $CONTAINER_NAME_LOCATION      => q(/con:container/name);
Readonly::Scalar my $SAMPLE_LIMSID_PATH           => q{/art:artifact/sample/@limsid};
Readonly::Scalar my $CONTAINER_SIGNATURE_LOCATION => q(/con:container/udf:field[@name="WTSI Container Signature"]);
Readonly::Scalar my $OUTPUT_ANALYTES_URI_PATH     => q{/prc:process/input-output-map/output/@uri};
Readonly::Scalar my $WORKFLOW_STAGE_URI           => q{/art:details/art:artifact[1]/workflow-stages/workflow-stage[@status="IN_PROGRESS"]/@uri};
Readonly::Scalar my $FIRST_ARTIFACT_URI           => q{art:details/art:artifact[1]/@uri};
Readonly::Scalar my $FIRST_ARTIFACT_LIMSID        => q{art:details/art:artifact[1]/@limsid};
Readonly::Scalar my $SAMPLE_URI_BY_ARTIFACT_DOC   => q{art:artifact/sample/@uri};
Readonly::Scalar my $SAMPLE_URI_BY_ARTIFACTS_DOC  => q{art:details/art:artifact/sample/@uri};
Readonly::Scalar my $PROJECT_URI_BY_SAMPLE_DOC    => q{smp:details/smp:sample/project/@uri};
Readonly::Scalar my $TECHNICIAN_URI_BY_PROCESS    => q{prc:process/technician[1]/@uri};
Readonly::Scalar my $PROJECT_LIMSID               => q{prj:project/@limsid};
Readonly::Scalar my $BAIT_LIBRARY_PATH            => q{smp:sample/udf:field[@name='WTSI Bait Library Name']};
Readonly::Scalar my $ARTIFACT_LIMSID_PATH         => q{art:artifacts/artifact/@limsid};
## use critic

has '_parent' => (
  is => 'ro',
  isa => 'HasRequestAndConfig',
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
  return $self->_request->batch_retrieve('artifacts', $self->input_states());
}

has 'input_states' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_input_states {
  my $self = shift;

  my $input_node_list = $self->findnodes($INPUT_ARTIFACT_URIS_PATH);
  my @input_states = uniq(map {
    $_->getValue
  } $input_node_list->get_nodelist);

  return \@input_states;
}
has 'input_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_input_uris {
  my $self = shift;

  my @input_uris = @{$self->input_states};
  map {
    do {
      (my $tmp = $_) =~ s/[?]state = \d + //smx
    }
  } @input_uris;

  return \@input_uris
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
      my @uniq_uris = uniq(map {
        $_->getValue()
      } $parent_uris->get_nodelist());

      foreach my $uri (@uniq_uris) {
        $self->_find_parent($needle_process_name, $uri, $found_processes);
      }
    }
  }

  my @found_processes = keys %{$found_processes};

  return \@found_processes;
}

sub find_by_artifactlimsid_and_name {
  my ($self, $artifact_limsid, $process_name) = @_;

  my $parameters = 'inputartifactlimsid=' . $artifact_limsid . '&type=' . uri_escape($process_name);
  my $process_list_xml = $self->_by_entity_type_and_parameter($parameters, '/processes?');

  my @processes = $process_list_xml->findnodes($PROCESS_LIMSID_PATH)->to_literal_list();

  if (scalar @processes == 0) {
    return 0;
  }

  my $process_limsid = $self->_find_highest_limsid(\@processes);

  return $self->_by_entity_type_and_parameter($process_limsid, '/processes/');
}

sub _by_entity_type_and_parameter {
  my ($self, $param, $entity_type) = @_;

  my $uri = $self->_config->clarity_api->{'base_uri'} . qq{$entity_type} . $param;

  return $self->_parent->fetch_and_parse($uri);
}

sub _find_highest_limsid {
  my ($self, $limsids) = @_;

  my $highest_limsid = reduce {
    my ($prefix_a, $id_a) = split /-/sxm, $a;
    my ($prefix_b, $id_b) = split /-/sxm, $b;

    $id_a > $id_b ? $a : $b;
  } @{$limsids};

  return $highest_limsid;
}

has 'io_map' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  lazy_build => 1,
);

sub _build_io_map {
  my $self = shift;
  my @mapping = map {
    $self->_build_mapping($_);
  } @{$self->_input_output_map};

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

  my @plate_io_map_barocodes = map {
    $self->_get_plate_barcode($_)
  } @{$self->plate_io_map};

  return \@plate_io_map_barocodes;
}

sub _get_plate_barcode {
  my ($self, $plate_io_map) = @_;

  my $source_plate = $self->containers->findnodes(sprintf $CONTAINER_BY_LIMSID, $plate_io_map->{'source_plate'})->pop();
  my $dest_plate = $self->containers->findnodes(sprintf $CONTAINER_BY_LIMSID, $plate_io_map->{'dest_plate'})->pop();

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

has 'containers' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build_containers {
  my $self = shift;
  my @all_container_uris = $self->_analytes->findnodes($ALL_CONTAINERS)->to_literal_list;
  return $self->_request->batch_retrieve('containers', \@all_container_uris);
}

has 'input_containers' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);
sub _build_input_containers {
  my $self = shift;
  my @all_container_uris = uniq($self->_input_analytes->findnodes($ALL_CONTAINERS)->to_literal_list);
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

has 'output_analyte_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_output_analyte_uris {
  my $self = shift;

  my @output_uris = map {
    $_->getValue
  } $self->findnodes($OUTPUT_ANALYTES_URI_PATH)->get_nodelist;

  return \@output_uris;
}

has 'output_analytes' => (
  isa        => 'XML::LibXML::Document',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build_output_analytes {
  my $self = shift;

  return $self->_request->batch_retrieve('artifacts', $self->output_analyte_uris);
}

has '_input_analytes' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__input_analytes {
  my $self = shift;
  my @all_analyte_uris = uniq($self->findnodes($INPUT_ANALYTES)->to_literal_list);
  return $self->_request->batch_retrieve('artifacts', \@all_analyte_uris);
}

has '_first_input_analyte_uri' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build__first_input_analyte_uri {
  my $self = shift;
  return $self->_input_analytes->findnodes($FIRST_ARTIFACT_URI)->pop()->textContent;
}

has 'first_input_analyte_limsid' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_first_input_analyte_limsid {
  my $self = shift;
  return $self->_input_analytes->findnodes($FIRST_ARTIFACT_LIMSID)->pop()->textContent;
}

has 'first_input_analyte_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build_first_input_analyte_doc {
  my $self = shift;

  return $self->_parent->fetch_and_parse($self->_first_input_analyte_uri);
}

has '_first_sample_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__first_sample_doc {
  my $self = shift;

  my $first_analytes_doc = $self->_parent->fetch_and_parse($self->_first_input_analyte_uri);
  my $sample_uri = $first_analytes_doc->findnodes($SAMPLE_URI_BY_ARTIFACT_DOC)->pop()->textContent;

  return $self->_parent->fetch_and_parse($sample_uri);
}

has 'samples_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build_samples_doc {
  my $self = shift;

  my $analytes_doc = $self->_input_analytes;
  my @sample_uris = $analytes_doc->findnodes($SAMPLE_URI_BY_ARTIFACTS_DOC)->to_literal_list;
  my $samples_doc = $self->_request->batch_retrieve('samples', \@sample_uris);

  return $samples_doc;
}

has 'bait_library' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_bait_library {
  my $self = shift;

  return $self->_first_sample_doc->findvalue($BAIT_LIBRARY_PATH);
}

has 'project_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);
sub _build_project_doc {
  my $self = shift;

  return $self->_parent->fetch_and_parse($self->samples_doc->findnodes($PROJECT_URI_BY_SAMPLE_DOC)->pop->textContent);
}

has 'study_limsid' => (
  isa         => 'Str',
  is          => 'ro',
  lazy_build  => 1,
);
sub _build_study_limsid {
  my $self = shift;

  return $self->project_doc->findvalue($PROJECT_LIMSID);
}

has 'technician_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);
sub _build_technician_doc {
  my $self = shift;

  return $self->_parent->fetch_and_parse($self->xml->findvalue($TECHNICIAN_URI_BY_PROCESS));
}

sub get_result_file_location {
  my $self = shift;

  my $result_file_xml = $self->_parent->fetch_and_parse($self->xml->findvalue($RESULT_FILE_URI));
  my $file_path = $result_file_xml->findvalue($FILE_URL_PATH);

  if (!defined $file_path) {
    croak q{The result file could not been found!};
  }

  my $uploaded_file_xml = $self->_parent->fetch_and_parse($file_path);

  return $uploaded_file_xml->findvalue($FILE_CONTENT_LOCATION);
}

sub get_container_name_by_limsid {
  my ($self, $limsid) = @_;

  my $container_xml = $self->_by_entity_type_and_parameter($limsid, '/containers/');
  my $container_name = $container_xml->findvalue($CONTAINER_NAME_LOCATION);

  croak qq{Could not find the name of container with the given limsid: $limsid} if (!defined $container_name || $container_name eq q{});

  return $container_name;
}

sub sample_limsid_by_artifact_uri {
  my ($self, $artifact_uri) = @_;

  my $output_artifact_xml = $self->_parent->fetch_and_parse($artifact_uri);
  my @sample_limsids = $output_artifact_xml->findvalue($SAMPLE_LIMSID_PATH);

  if (scalar @sample_limsids < 1) {
    $self->_throw_artifact_not_found_error;
  }

  return $sample_limsids[0];
}

has 'output_artifact_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_output_artifact_uris {
  my $self = shift;

  my @output_uris = map {
    $_->getValue
  } $self->_parent->findnodes($OUTPUT_ARTIFACT_URI_PATH)->get_nodelist;

  return \@output_uris;
}

has 'number_of_input_artifacts' => (
  isa => 'Num',
  is  => 'ro',
  lazy_build => 1,
);
sub _build_number_of_input_artifacts {
  my $self = shift;

  return scalar $self->xml->findnodes($INPUT_ANALYTES_URIS_PATH)->get_nodelist;
}

sub container_uri_by_artifact_limsid {
  my ($self, $artifact_limsid) = @_;

  my $result_file_uri = $self->_config->clarity_api->{'base_uri'} . q{/artifacts/} . $artifact_limsid;

  my $artifact_xml = $self->_parent->fetch_and_parse($result_file_uri);

  my $container_uri = $artifact_xml->findvalue($CONTAINER_URI_PATH);

  return $container_uri;
}

sub get_analytes_uris_by_container_uri {
  my ($self, $container_uri) = @_;

  my $container_xml = $self->_parent->fetch_and_parse($container_uri);

  my @analytes_uris = map {
    $_->getValue
  } $container_xml->findnodes($PLACEMENTS_URI_PATH);

  return \@analytes_uris;
}

sub get_container_signature_by_limsid {
  my ($self, $limsid) = @_;

  my $container_xml = $self->_by_entity_type_and_parameter($limsid, '/containers/');;
  my $container_signature = $container_xml->findvalue($CONTAINER_SIGNATURE_LOCATION);

  croak qq{Could not find the signature of container with the given limsid: $limsid} if (!defined $container_signature || $container_signature eq q{});

  return $container_signature;
}

sub get_current_workflow_uri {
  my $self = shift;

  my $artifacts_xml = $self->input_artifacts();
  my $workflow_stage = $artifacts_xml->findnodes($WORKFLOW_STAGE_URI);

  my ($workflow_uri) = $workflow_stage =~ / ^ (. * )\/stages\/\d + /smx;
  return $workflow_uri;
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

=head2 find_by_artifactlimsid_and_name
  Takes an artifact limsid and a process name. Tries to find the specifed process xml in that artifact's
  history (using the ?inputartifactlimsid URL parameter). If there are multiple processes, the latest one
  will be returned i.e. the one with the highest limsid. Returns 0 if no processes are found.

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

=head2 containers
  Returns the process related containers XML artifact.

=head2 get_result_file_location
  Returns the location of the result file.

=head2 get_container_name_by_limsid

  Returns the name of the container by its limsid.

=head2 sample_limsid_by_artifact_uri

  Returns the sample LIMSID by the artifact URI.

=head2 container_uri_by_artifact_limsid

  Returns the container URI by the given artifact LIMSID.

=head2 get_analytes_uris_by_container_uri

  Returns URI of analytes by the given container.

=head2 get_container_signature_by_limsid

  Returns the signature of the container by its limsid.

=head2 get_current_workflow_uri

    Returns the uri for the workflow.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item Carp

=item List::Util

=item List::MoreUtils

=item URI::Escape

=item use wtsi_clarity::util::types

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