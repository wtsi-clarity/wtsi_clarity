package wtsi_clarity::epp::reports::sample_qc_report;

use Moose;
use Readonly;
use Carp;
use DateTime;
use URI::Escape;

extends 'wtsi_clarity::epp::reports::report';

our $VERSION = '0.0';

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $FILE_NAME                        => q{%s.%s.lab_sample_qc.txt};
Readonly::Scalar my $SAMPLE_LIMSID                    => q{./@limsid};
Readonly::Scalar my $ARTIFACTS_ARTIFACT_URI           => q{art:artifacts/artifact/@uri};
Readonly::Scalar my $ARTIFACT_PARENT_PROCESS_URI      => q{art:artifact/parent-process/@uri};
Readonly::Scalar my $UDF_FIELD_REQUIRED_VOLUME        => q{prc:process/udf:field[@name="(1) Required Volume"]};
Readonly::Scalar my $UDF_FIELD_REQUIRED_CONCENTRATION => q{prc:process/udf:field[@name="(1) Required Concentration"]};
Readonly::Scalar my $BUFFER                           => 0.1;
## use critic

Readonly::Scalar my $CHERRYPICK_STAMPING_PROCESS_NAME => q{Cherrypick Stamping (SM)};
Readonly::Scalar my $DATA_DESTINATION_PATH          => q{prj:project/udf:field[@name="WTSI Data Destination"]};

has '_containers' => (
  is      => 'ro',
  isa     => 'XML::LibXML::Document',
  lazy    => 1,
  builder => '_build__containers',
);

has '_sample_uuid' => (
  is          => 'ro',
  isa         => 'Str',
  lazy_build  => 1,
  writer      => '_write_sample_uuid',
);

has '_project_uri' => (
  is          => 'ro',
  isa         => 'Str',
  lazy_build  => 1,
  writer      => '_write_project_uri',
  predicate   => '_has_project_uri',
);

sub elements {
  my $self = shift;
  my $containers = $self->_containers->findnodes('/con:details/con:container');

  my @samples = ();
  foreach my $container (@{$containers}) {
    my $container_lims_id = $container->findvalue('@limsid');
    push @samples, @{$self->_build_samples($container)};
  }

  return sub { return $self->_sample_doc(\@samples) };

}

sub _sample_doc {
  my ($self, $samples) = @_;

  if (scalar @{$samples} == 0) {
    return;
  }
  my $sample_doc = pop @{$samples};
  $self->_write_sample_uuid($sample_doc->findvalue('./name'));
  $self->_write_project_uri($sample_doc->findvalue('./project/@uri'));

  return $sample_doc;
}

sub sort_by_column { return 'sample_UUID' }

sub file_name {
  my ($self, $sample) = @_;
  return sprintf $FILE_NAME, $self->_sample_uuid, $self->now();
}

sub get_metadatum {
  my ($self) = @_;

  my @metadatum = (
    {
      "attribute" => "type",
      "value"     => "lab_sample_qc.txt",
    },
    {
      "attribute" => "sample",
      "value"     => $self->_sample_uuid,
    }
  );

  return @metadatum;
}

sub headers {
  return [
    'Sample UUID',
    'Concentration',
    'Sample volume',
    'Library concentration',
    'DNA amount library prep',
    'Status',
  ]
}

sub file_content {
  my ($self, $sample) = @_;
  my %file_content = ();

  my @rows = (
    $self->_build_row($sample)
  );

  return \@rows;
}

sub irods_destination_path {
  my ($self) = @_;

  my $project_doc = $self->fetch_and_parse($self->_project_uri);
  my $destination = $project_doc->findvalue($DATA_DESTINATION_PATH);
  return $self->config->irods->{$destination.'_lab_sample_qc_path'};
}

sub _build__containers {
  my $self = shift;

  if ($self->_has_process_url) {
    return $self->process_doc->input_containers;
  } elsif ($self->_has_container_id) {
    my @urls = map { $self->config->clarity_api->{'base_uri'} . '/containers/' . $_ } @{$self->container_id};
    return $self->request->batch_retrieve('containers', \@urls);
  }
}

sub _build_samples {
  my ($self, $container) = @_;
  my @sample_uris = ();
  my @artifact_uris = $container->findnodes('placement/@uri')->to_literal_list;
  my $analytes = $self->request->batch_retrieve('artifacts', \@artifact_uris);

  @sample_uris = map { $self->_get_sample_uri($_, $analytes) }
            $container->findnodes('./placement/value')->to_literal_list;

  my $samples_batch_doc = $self->request->batch_retrieve('samples', \@sample_uris);

  my @samples = $samples_batch_doc->findnodes('/smp:details/smp:sample');

  return \@samples;
}

sub _get_sample_uri {
  my ($self, $placement, $analytes) = @_;
  my $artifact = $analytes->findnodes("art:details/art:artifact[location/value='$placement']")->pop;
  return $artifact->findvalue('./sample/@uri');
}

sub _build_row {
  my ($self, $sample) = @_;

  my $sample_limsid           = $sample->findvalue($SAMPLE_LIMSID);
  my $artifact                = $self->_get_cherrypick_sample_artifact($sample_limsid);
  my $cherrypick_stamping_doc = $self->_get_cherrypick_stamping_process($artifact);
  my $cherrypick_volume       = $self->_get_cherrypick_sample_volume($artifact);

  return {
    'Sample UUID'             => $sample->findvalue('./name') // q{},
    'Concentration'           => $sample->findvalue('./udf:field[@name="Sample Conc. (ng\/µL) (SM)"]') // q{},
    'Sample volume'           => $cherrypick_volume // q{},
    'Library concentration'   => $sample->findvalue('./udf:field[@name="WTSI Library Concentration"]') // q{},
    'DNA amount library prep' => $self->_get_dna_amount_library_prep($cherrypick_stamping_doc, $sample, $cherrypick_volume),
    'Status'                  => $self->_get_status($sample),
  }
}

sub _get_status {
  my ($self, $sample) = @_;
  my $status = ($sample->findvalue('./udf:field[@name="WTSI Proceed To Sequencing?"]') eq 'Yes') ? 'Passed' : 'Failed';
  return $status;
}

sub _get_sample_concentration {
  my ($self, $sample) = @_;
  return $sample->findvalue('./udf:field[@name="Sample Conc. (ng\/µL) (SM)"]');
}

sub _get_cherrypick_stamping_process {
  my ($self, $artifact_doc) = @_;
  return $self->fetch_and_parse($artifact_doc->findvalue($ARTIFACT_PARENT_PROCESS_URI));
}

sub _get_cherrypick_sample_artifact {
  my ($self, $sample_limsid) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . '/artifacts?';

  my $params = 'samplelimsid=' . $sample_limsid;
  $params .= '&process-type=' . uri_escape($CHERRYPICK_STAMPING_PROCESS_NAME);

  $uri .= $params;

  my $artifact_list = $self->fetch_and_parse($uri)
                           ->findnodes($ARTIFACTS_ARTIFACT_URI);

  if ($artifact_list->size() == 0) {
    croak 'Could not find a previous artifact for sample ' . $sample_limsid . " that has been through $CHERRYPICK_STAMPING_PROCESS_NAME";
  }

  return $self->fetch_and_parse($artifact_list->pop()->value);
}

sub _get_cherrypick_sample_volume {
  my ($self, $artifact_doc) = @_;
  return $artifact_doc->findvalue('art:artifact/udf:field[@name="Cherrypick Sample Volume"]');
}

sub _get_dna_amount_library_prep {
  my ($self, $cherrypick_stamping_process_doc, $sample, $cherrypick_volume) = @_;

  my $volume_required = $cherrypick_stamping_process_doc->findvalue($UDF_FIELD_REQUIRED_VOLUME);

  my $concentration_required = $cherrypick_stamping_process_doc->findvalue($UDF_FIELD_REQUIRED_CONCENTRATION);

  my $sample_limsid = $sample->findvalue($SAMPLE_LIMSID);

  if ( $concentration_required eq q{} or $volume_required eq q{}) {
    croak "The volume and concentration required have not been defined at Cherrypick Stamping for sample: $sample_limsid";
  }

  my $requirement = $volume_required * $concentration_required;

  my $sample_concentration = $self->_get_sample_concentration($sample);

  my $dna_amount = $sample_concentration * $cherrypick_volume;

  # If the dna amount is not up to requirement, S.M. subtract 2ul from the cherrypick volume
  # (to bring the concentration up). Added buffer as S.M. won't take off the 2 if the dna amount
  # is close enough...
  if ($dna_amount < ($requirement - $BUFFER)) {
    $dna_amount = $sample_concentration * ($cherrypick_volume - 2);
  }

  return $dna_amount;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::reports::sample_qc_report

=head1 SYNOPSIS

wtsi_clarity::epp::reports::sample_qc_report->new( container_id => ['24-123', '24-567'])->run()

=head1 DESCRIPTION

 An EPP for creating a "sample_qc_report report". The EPP can be supplied with either a process_url, an
 array of container_ids, or a wtsi_clarity::mq::message object (which would come for the report
 queue). The report will be built and currently saved locally with the filename of
 {sample_uuid}.{timestamp}.lab_sample_qc.txt.

=head1 SUBROUTINES/METHODS

=head2 BUILD - checks the object post construction. One of either container_id, process_url, or
message must be supplied

=head2 run - Builds the report

=head2 elements

  Creating the elements of the report files.

=head2 headers

  Returns the headers of the report file.

=head2 file_content

  Generating the content of the report file.

=head2 file_name

  Generating a file name based on the sample UUID and the current time stamp.
  The file name will be like {sample_uuid}.{timestamp}.lab_sample_qc.txt.

=head2 get_metadatum

  Returns the metadatum for the file publishing to iRODS.

=head2 sort_by_column

  Define the sorting criteria by column name.

=head2 set_publish_to_irods

  Checks whether the 'WTSI Send data to external iRODS' check box in project the sample relates to is checked or not.
  If it is checked then returns 1, otherwise 0.

=head2 irods_destination_path

  Returns the file's destination path on iRODS.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readnly

=item Carp

=item List::Util

=item DateTime

=item URI::Escape

=item wtsi_clarity::epp::reports::report

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
