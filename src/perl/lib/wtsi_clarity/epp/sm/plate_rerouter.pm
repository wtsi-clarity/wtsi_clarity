package wtsi_clarity::epp::sm::plate_rerouter;

use Moose;
use Carp;
use Readonly;
use URI::Escape;
use XML::LibXML;

use wtsi_clarity::epp::generic::workflow_assigner;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_ARTIFACT_URI_PATH         => q{/prc:process/input-output-map/output[@output-type="Analyte"]/@uri};
Readonly::Scalar my $SAMPLE_LIMSID_PATH               => q{/art:artifact/sample/@limsid};
Readonly::Scalar my $RESULTFILE_ARTIFACT_LIMSID_PATH  => q{/art:artifacts/artifact/@limsid};
## use critic

my @str_attribute_params = (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has [ 'process_type', 'new_step_name', 'new_protocol_name', 'new_workflow_name'] => @str_attribute_params;

has '_workflow_assigner' => (
  isa         => 'wtsi_clarity::epp::generic::workflow_assigner',
  is          => 'ro',
  required    => 0,
  lazy_build  => 1,
);
sub _build__workflow_assigner {
  my $self = shift;

  return wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url   => $self->process_url,
    new_wf        => $self->new_workflow_name,
    new_protocol  => $self->new_protocol_name,
    new_step      => $self->new_step_name,
  );
}

override 'run' => sub {
  my $self= shift;

  super();

  my $artifact_limsid = $self->_artifact_limsid_by_process_type_with_samplelimsid($self->_sample_limsid);

  my $container_uri = $self->_container_uri_by_artifact_limsid($artifact_limsid);

  my $analytes_to_reroute = $self->_get_analytes_uris_from_container($container_uri);

  $self->_reroute_analytes($analytes_to_reroute);

  return;
};

sub _reroute_analytes {
  my ($self, $analytes_to_reroute) = @_;

  my $post_uri = $self->config->clarity_api->{'base_uri'}.'/route/artifacts' ;

  my $reroute_to_step_uri = $self->_get_new_step_uri;

  my $req_doc = $self->_workflow_assigner->make_step_rerouting_request_doc(
    $reroute_to_step_uri, $analytes_to_reroute
  )->toString();
  return $self->request->post($post_uri, $req_doc) or croak qq{Could not send successful request for rerouting. ($post_uri)};
}

sub _get_new_step_uri {
  my ($self) = @_;

  return $self->_workflow_assigner->get_step_uri($self->new_step_name);
}

sub _throw_artifact_not_found_error {
  my $self = shift;

  croak qq{The artifact could not be found in the given process: '$self->process_type'.};
}

sub _artifact_limsid_by_process_type_with_samplelimsid {
  my ($self, $sample_limsid) = @_;

  my $result_file_request_uri = $self->config->clarity_api->{'base_uri'} .
                                q{/artifacts?} .
                                q{samplelimsid=}  . $sample_limsid .
                                q{&process-type=}  . uri_escape($self->process_type) .
                                q{&type=Analyte};

  my $result_file_search_artifact_xml = $self->fetch_and_parse($result_file_request_uri);

  my @artifact_file_limsids = map {$_->getValue} $result_file_search_artifact_xml->findnodes($RESULTFILE_ARTIFACT_LIMSID_PATH)->get_nodelist;

  if (scalar @artifact_file_limsids < 1) {
    $self->_throw_artifact_not_found_error;
  }

  @artifact_file_limsids = sort @artifact_file_limsids;

  return $artifact_file_limsids[-1];
}

has '_sample_limsid'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__sample_limsid {
  my $self = shift;

  my $output_artifact_xml = $self->fetch_and_parse($self->_output_artifact_uris->[0]);
  my @sample_limsids = $output_artifact_xml->findvalue($SAMPLE_LIMSID_PATH);

  if (scalar @sample_limsids < 1) {
    $self->_throw_file_not_found_error;
  }

  return $sample_limsids[0];
}

has '_output_artifact_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__output_artifact_uris {
  my $self = shift;

  my @output_uris = map { $_->getValue } $self->process_doc->findnodes($OUTPUT_ARTIFACT_URI_PATH)->get_nodelist;

  return \@output_uris;
}

sub _container_uri_by_artifact_limsid {
  my ($self, $artifact_limsid) = @_;

  my $result_file_uri = $self->config->clarity_api->{'base_uri'} . q{/artifacts/} . $artifact_limsid;

  my $artifact_xml = $self->fetch_and_parse($result_file_uri);

  my $container_uri = $artifact_xml->findvalue(q{/art:artifact/location/container/@uri});

  return $container_uri;
}

sub _get_analytes_uris_from_container {
  my ($self, $container_uri) = @_;

  my $container_xml = $self->fetch_and_parse($container_uri);

  my @analytes_uris = map { $_->getValue } $container_xml->findnodes(q{/con:container/placement/@uri});

  return \@analytes_uris;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::plate_rerouter

=head1 SYNOPSIS

  my $plate_rerouter = wtsi_clarity::epp::sm::file_download->new(er
    process_url   => 'http://clarity.com/processes/1234',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

=head1 DESCRIPTION

  Makes a file downloadable from a previous process.

=head1 SUBROUTINES/METHODS


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item use URI::Escape

=item use XML::LibXML

=item wtsi_clarity::epp::generic::workflow_assigner

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

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