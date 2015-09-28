package wtsi_clarity::epp::isc::calliper_analyser;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection;
use List::Util qw/sum/;
use URI::Escape;

use wtsi_clarity::util::textfile;
use wtsi_clarity::util::calliper;

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $FIRST_ANALYTE_PATH               => q{/prc:process/input-output-map[1]/input/@uri};
Readonly::Scalar my $PROCESS_INPUT_ARTIFACT_URI_PATH  => q{prc:process/input-output-map/input/@uri};
Readonly::Scalar my $ARTIFACT_NODE_LIST_PATH          => q{art:details/art:artifact};
Readonly::Scalar my $CONTAINER_PATH                   => q{/art:artifact/location/container/@uri};
Readonly::Scalar my $CONTAINER_NAME                   => q{/con:container/name};
Readonly::Scalar my $ARTIFACTS_ARTIFACT_URI           => q{art:artifacts/artifact/@uri};
Readonly::Scalar my $SAMPLE_PATH                      => q{smp:details/smp:sample[@uri="%s"]};
Readonly::Scalar my $PARENT_PROCESS_URI               => q{art:artifact/parent-process/@uri};
Readonly::Scalar my $LOCATION_VALUE_PATH              => q{./location/value};
Readonly::Scalar my $SAMPLE_URI_PATH                  => q{./sample/@uri};
Readonly::Scalar my $ARTIFACT_SAMPLE_LIMSID_PATH      => q{art:artifact/sample/@limsid};
##use critic
Readonly::Scalar my $LIBRARY_CONCENTRATION_UDF_NAME   => q{WTSI Library Concentration};
Readonly::Scalar my $LIBRARY_MOLARITY_UDF_NAME        => q{WTSI Library Molarity};
Readonly::Scalar my $POST_LIB_PCR_QC_STAMP_STEP       => q{Post Lib PCR QC Stamp};
Readonly::Scalar my $TOTAL_CONCENTRATION_UDF_NAME     => q{Total Conc. (ng/ul)};
Readonly::Scalar my $MOLARITY_UDF_NAME                => q{Region[200-1400] Molarity (nmol/l)};
Readonly::Scalar my $CONCENTRATION_KEY                => q{concentration};
Readonly::Scalar my $MOLARITY_KEY                     => q{molarity};
Readonly::Scalar my $LOCATION_KEY                     => q{location};
Readonly::Scalar my $DILUTION_FACTOR                  => q{5};
Readonly::Scalar my $HUNDRED                          => q{100};

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

### Attributes ###

has '_text_file' => (
  isa => 'wtsi_clarity::util::textfile',
  is  => 'ro',
  required  => 0,
  default => sub { return wtsi_clarity::util::textfile->new(); },
);

has '_calliper' => (
  isa      => 'wtsi_clarity::util::calliper',
  is       => 'ro',
  required => 0,
  default  => sub { return wtsi_clarity::util::calliper->new(); },
);

has '_plate_barcode' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__plate_barcode {
  my $self = shift;
  my $container_hash = $self->fetch_targets_hash($FIRST_ANALYTE_PATH, $CONTAINER_PATH);
  my $container = (values $container_hash)[0];
  return $container->findvalue($CONTAINER_NAME);
}

has '_file_path' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__file_path {
  my $self = shift;
  my $path = join q{/}, $self->config->robot_file_dir->{'post_lib_pcr_qc'}, $self->_plate_barcode;
  my $ext  = '.csv';
  return $path . $ext;
}

has '_sample_details' => (
  isa         => 'XML::LibXML::Document',
  is          => 'rw',
  required    => 0,
  lazy_build  => 1,
  writer      => '_writer_sample_details',
);


override 'run' => sub {
  my $self = shift;
  super();

  my $caliper_file = $self->_reading_the_caliper_file;

  my $caliper_datum = $self->_create_collection_from_file($caliper_file);

  my $data_by_wells = $self->_get_data_by_wells($caliper_datum);

  my $averaged_data_by_wells = $self->_avaraged_data_by_well(
    $data_by_wells
  );

  $self->_update_samples_by_location($averaged_data_by_wells);

  return 1;
};

sub _reading_the_caliper_file {
  my ($self) = @_;

  $self->_text_file->read_content($self->_file_path);

  my $caliper_file = $self->_calliper->interpret(
    $self->_text_file->content,
    $self->_plate_barcode,
  );

  return $caliper_file;
}

sub _create_collection_from_file {
  my ($self, $caliper_file) = @_;

  return Mojo::Collection->new(@{$caliper_file});
}

sub _get_data_by_wells {
  my ($self, $caliper_datum) = @_;

  my %data_by_wells;
  foreach my $caliper_data (@{$caliper_datum}) {
    my ($well_name_letter, $well_name_number) = $caliper_data->{'Sample Name'} =~ /(^[A-H]{1})(\d{1,2})/smx;

    if ($well_name_letter && $well_name_number) {
      push @{$data_by_wells{$well_name_letter . q{:} . $well_name_number}{$CONCENTRATION_KEY}},  $caliper_data->{$TOTAL_CONCENTRATION_UDF_NAME};
      push @{$data_by_wells{$well_name_letter . q{:} . $well_name_number}{$MOLARITY_KEY}},       $caliper_data->{$MOLARITY_UDF_NAME};
    }
  }

  return \%data_by_wells;
}

sub _avaraged_data_by_well {
  my ($self, $data_by_wells) = @_;

  my %average_data_by_wells;
  while ( my ($well_name, $data) = each %{$data_by_wells}) {
    $average_data_by_wells{$well_name}{$CONCENTRATION_KEY} = $self->_averaged_and_diluted_data_for_well($data->{$CONCENTRATION_KEY});
    $average_data_by_wells{$well_name}{$MOLARITY_KEY} =      $self->_averaged_and_diluted_data_for_well($data->{$MOLARITY_KEY});
  }

  return \%average_data_by_wells;
}

sub _averaged_and_diluted_data_for_well {
  my ($self, $data_by_well) = @_;

  return int((sum(@{$data_by_well}) / scalar @{$data_by_well}) * $DILUTION_FACTOR * $HUNDRED) / $HUNDRED;
}

sub _update_samples_by_location {
  my ($self, $average_data_by_wells) = @_;

  my $parent_process_doc = $self->_parent_process_doc;

  my $artifacts_from_parent_process = $self->_artifacts_from_parent_process($parent_process_doc);

  my $sample_data_by_uris = $self->_sample_data_by_uris($artifacts_from_parent_process, $average_data_by_wells);

  $self->_set_sample_details($sample_data_by_uris);

  foreach my $sample_data (@{$sample_data_by_uris}) {
    my @samples_uri = keys $sample_data;
    my $sample_uri = pop @samples_uri;
    $self->_update_sample_with_data(
      $sample_uri,
      $sample_data->{$sample_uri}
    );
  }

  $self->request->batch_update('samples', $self->_sample_details);

  return 1;
}

sub _parent_process_doc {
  my ($self) = @_;

  my $artifact_from_previous_process_doc = $self->_artifacts_by_sample_limsid_and_process_type(
    $self->_a_sample_limsid_from_current_process, $POST_LIB_PCR_QC_STAMP_STEP
  );

  return $self->fetch_and_parse(
    $artifact_from_previous_process_doc->findvalue($PARENT_PROCESS_URI)
  );
}

sub _set_sample_details {
  my ($self, $sample_data_by_uris) = @_;

  my @sample_uris = map { keys $_ } @{$sample_data_by_uris};

  $self->_writer_sample_details($self->request->batch_retrieve('samples', \@sample_uris));

  return 1;
}

sub _update_sample_with_data {
  my ($self, $sample_uri, $sample_data) = @_;

  my $sample_list = $self->_sample_details->findnodes(sprintf $SAMPLE_PATH, $sample_uri);

  if ($sample_list->size() != 1) {
    croak sprintf 'Found %i samples for sample %s', $sample_list->size(), $sample_uri;
  }

  my $sample_xml        = $sample_list->pop();

  my $concentration = $sample_data->{$CONCENTRATION_KEY};
  my $molarity      = $sample_data->{$MOLARITY_KEY};
  my $concentration_udf = $self->create_udf_element($self->_sample_details, $LIBRARY_CONCENTRATION_UDF_NAME, $concentration);
  my $molarity_udf      = $self->create_udf_element($self->_sample_details, $LIBRARY_MOLARITY_UDF_NAME, $molarity);

  $sample_xml->appendChild($concentration_udf);
  $sample_xml->appendChild($molarity_udf);

  return 1;
}

sub _artifacts_from_parent_process {
  my ($self, $parent_process_doc) = @_;

  my @artifact_uri_nodes = $parent_process_doc->findnodes($PROCESS_INPUT_ARTIFACT_URI_PATH);
  my @artifact_uris = map { $_->getValue() } @artifact_uri_nodes;

  return $self->request->batch_retrieve('artifacts', \@artifact_uris);
}

sub _sample_data_by_uris {
  my ($self, $doc, $average_data_by_wells) = @_;

  my @sample_by_uris;
  my @artifacts = $doc->findnodes($ARTIFACT_NODE_LIST_PATH)->get_nodelist;

  foreach my $artifact (@artifacts) {
    my $location = $artifact->findvalue($LOCATION_VALUE_PATH);
    my $sample_uri = $artifact->findvalue($SAMPLE_URI_PATH);
    push @sample_by_uris,
      {
        $sample_uri =>  {
                          $LOCATION_KEY       => $location,
                          $CONCENTRATION_KEY  => $average_data_by_wells->{$location}->{$CONCENTRATION_KEY},
                          $MOLARITY_KEY       => $average_data_by_wells->{$location}->{$MOLARITY_KEY}
                        },
      };
  }

  return \@sample_by_uris;
}

sub _artifacts_by_sample_limsid_and_process_type {
  my ($self, $sample_limsid, $process_type) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . '/artifacts?';
  my $params = 'samplelimsid=' . $sample_limsid;
  $params .= '&process-type=' . uri_escape($process_type);

  $uri .= $params;

  my $artifact_list = $self->fetch_and_parse($uri)
                           ->findnodes($ARTIFACTS_ARTIFACT_URI);

  if ($artifact_list->size() == 0) {
    croak 'Could not find a previous artifact for sample ' . $sample_limsid . " that has been through $process_type";
  }

  return $self->fetch_and_parse($artifact_list->pop()->value);
}

sub _a_sample_limsid_from_current_process {
  my ($self) = @_;

  my $an_input_artifact_limsid = $self->process_doc->findnodes($PROCESS_INPUT_ARTIFACT_URI_PATH)->to_literal_list->[0];

  my $artifact_doc = $self->fetch_and_parse($an_input_artifact_limsid);

  return $artifact_doc->findvalue($ARTIFACT_SAMPLE_LIMSID_PATH);
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::calliper_analyser

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::calliper_analyser
    ->new(
      process_url        => 'http://clarity_url/processes/1234',
      calliper_file_name => 'abcd_file',
    )
    ->run()

=head1 DESCRIPTION

  Finds a calliper file from a process. Extracts the duplicated concentration and molarity from that file and calculate the average of them.
  Multiple the average concentration/molarity by 5 and update the related sample's UDF fields (WTSI Library Concentration and WTSI Library Molarity)
  with that calculated values.

=head1 SUBROUTINES/METHODS

=head2 run - runs the script

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item Mojo::Collection

=item List::Util

=item URI::Escape

=item wtsi_clarity::util::textfile

=item wtsi_clarity::util::calliper

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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