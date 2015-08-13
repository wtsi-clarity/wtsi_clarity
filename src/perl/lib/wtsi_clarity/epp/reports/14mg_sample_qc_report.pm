package wtsi_clarity::epp::reports::14mg_sample_qc_report;

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
## use critic

Readonly::Scalar my $CHERRYPICK_STAMPING_PROCESS_NAME => q{Cherrypick Stamping (SM)};

has 'container_id' => (
  is        => 'ro',
  isa       => 'ArrayRef',
  predicate => '_has_container_id',
  required  => 0,
);

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

sub elements {
  my $self = shift;
  my $containers = $self->_containers->findnodes('/con:details/con:container');

  my @samples = ();
  foreach my $container (@{$containers}) {
    my $container_lims_id = $container->findvalue('@limsid');
    push @samples, @{$self->_build_samples($container)};
  }

  return sub {
    if (scalar @samples == 0) {
      return;
    }
    my $sample_doc = pop @samples;
    $self->_write_sample_uuid($sample_doc->findvalue('./name'));
    return $sample_doc;
  }
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

  return $self->config->irods->{'lab_sample_qc_path'} . q{/};
}

sub _build__containers {
  my $self = shift;

  if ($self->_has_process_url) {
    return $self->step_doc->output_containers;
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

  return {
    'Sample UUID'             => $sample->findvalue('./name') // q{},
    'Concentration'           => $sample->findvalue('./udf:field[@name="Sample Conc. (ng\/µL) (SM)"]') // q{},
    'Sample volume'           => $sample->findvalue('./udf:field[@name="WTSI Working Volume (µL) (SM)"]') // q{},
    'Library concentration'   => $sample->findvalue('./udf:field[@name="WTSI Library Concentration"]') // q{},
    'DNA amount library prep' => $self->_get_dna_amount_library_prep($sample),
    'Status'                  => $sample->findvalue('./udf:field[@name="WTSI Proceed To Sequencing?"]') // q{},
  }
}

sub _get_dna_amount_library_prep {
  my ($self, $sample_doc) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . '/artifacts?';
  my $sample_limsid = $sample_doc->findvalue($SAMPLE_LIMSID);

  my $params = 'samplelimsid=' . $sample_limsid;
  $params .= '&process-type=' . uri_escape($CHERRYPICK_STAMPING_PROCESS_NAME);

  $uri .= $params;

  my $artifact_list = $self->fetch_and_parse($uri)
                           ->findnodes($ARTIFACTS_ARTIFACT_URI);

  if ($artifact_list->size() == 0) {
    croak 'Could not find a previous artifact for sample ' . $sample_limsid . " that has been through $CHERRYPICK_STAMPING_PROCESS_NAME";
  }

  my $artifact_doc = $self->fetch_and_parse($artifact_list->pop()->value);

  my $cherrypick_stamping_process_doc = $self->fetch_and_parse($artifact_doc->findvalue($ARTIFACT_PARENT_PROCESS_URI));

  my $volume = $cherrypick_stamping_process_doc->findvalue($UDF_FIELD_REQUIRED_VOLUME);

  my $concentration = $cherrypick_stamping_process_doc->findvalue($UDF_FIELD_REQUIRED_CONCENTRATION);

  if ( $concentration eq q{} or $volume eq q{}) {
    croak "The volume or concentration value is not defined on the sample: $sample_limsid";
  }
  return $volume * $concentration;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::reports::14mg_sample_qc_report

=head1 SYNOPSIS

wtsi_clarity::epp::reports::14mg_sample_qc_report->new( container_id => ['24-123', '24-567'])->run()

=head1 DESCRIPTION

 An EPP for creating a "14mg_sample_qc_report report". The EPP can be supplied with either a process_url, an
 array of container_ids, or a wtsi_clarity::mq::message object (which would come for the report
 queue). The report will be built and currently saved locally with the filename of
 {sample_uuid}.{timestamp}.lab_sample_qc.txt.

=head1 SUBROUTINES/METHODS

=head2 BUILD - checks the object post construction. One of either container_id, process_url, or
message must be supplied

=head2 run - Builds the report

=head2 elements

  Creating the elements of the report files.

=head2 file_content

  Generating the content of the report file.

=head2 file_name

  Generating a file name based on the sample UUID and the current time stamp.
  The file name will be like {sample_uuid}.{timestamp}.lab_sample_qc.txt.

=head2 get_metadatum

  Returns the metadatum for the file publishing to iRODS.

=head2 sort_by_column

  Define the sorting criteria by column name.

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
