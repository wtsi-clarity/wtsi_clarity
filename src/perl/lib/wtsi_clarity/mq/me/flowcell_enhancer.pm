package wtsi_clarity::mq::me::flowcell_enhancer;

use Moose;
use Readonly;
use Carp;
use URI::Escape;
use POSIX qw(strftime);
use wtsi_clarity::mq::messages::flowcell::flowcell;
use JSON;

with qw/ wtsi_clarity::mq::message_enhancer /;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_ARTIFACT_LIMSIDS => q{prc:process/input-output-map/output[@output-type="Analyte"]/@limsid};
Readonly::Scalar my $FLOWCELL_BARCODE_UDF    => q{prc:process/udf:field[@name="Flow Cell ID"]};
Readonly::Scalar my $SPIKED_HYB_BARCODE      => q{prc:process/udf:field[@name="WTSI Spiked Hyb Barcode"]};
Readonly::Scalar my $PROCESS_LIMSID_PATH     => q{prc:process/@limsid};

Readonly::Scalar my $CONTAINER_URI_PATH      => q{./stp:placements/selected-containers/container/@uri};

Readonly::Scalar my $ARTIFACTS_ARTIFACT_URI  => q{art:artifacts/artifact/@uri};

Readonly::Scalar my $ARTIFACT_WELL_PATH      => q{art:artifact/location/value};
Readonly::Scalar my $ARTIFACT_NAME_PATH      => q{art:artifact/name};
Readonly::Scalar my $ARTIFACT_LIMSID_PATH    => q{art:artifact/@limsid};
Readonly::Scalar my $ARTIFACT_SAMPLE_LIMSID  => q{art:artifact/sample/@limsid};
Readonly::Scalar my $ARTIFACT_REAGENT_NAME   => q{./art:artifact/reagent-label/@name};
Readonly::Scalar my $ARTIFACT_LOCATION_VALUE => q{./art:artifact/location/value};
Readonly::Scalar my $ARTIFACT_CONTAINER_URI  => q{./art:artifact/location/container/@uri};

Readonly::Scalar my $LANE_ENTITY_TYPE        => q{library};
Readonly::Scalar my $PIPELINE_ID_LIMS        => q{GCLP-CLARITY-ISC};
Readonly::Scalar my $SAMPLE_ENTITY_TYPE      => q{library_indexed};
Readonly::Scalar my $IS_R_AND_D              => q{false};

Readonly::Scalar my $SAMPLE_LIMSID           => q{smp:sample/@limsid};
Readonly::Scalar my $SAMPLE_BAIT_NAME        => q{smp:sample/udf:field[@name="WTSI Bait Library Name"]};
Readonly::Scalar my $SAMPLE_INSERT_SIZE_FROM => q{smp:sample/udf:field[@name="WTSI Requested Size Range From"]};
Readonly::Scalar my $SAMPLE_INSERT_SIZE_TO   => q{smp:sample/udf:field[@name="WTSI Requested Size Range To"]};
Readonly::Scalar my $SAMPLE_READ_LENGTH      => q{smp:sample/udf:field[@name="Read Length"]};
Readonly::Scalar my $SAMPLE_NAME             => q{smp:sample/name};
Readonly::Scalar my $SAMPLE_PROJECT_URI      => q{smp:sample/project/@uri};

Readonly::Scalar my $CONTAINER_NAME          => q{./con:container/name};

Readonly::Scalar my $PROJECT_COST_CODE_PATH  => q{prj:project/udf:field[@name="WTSI Project Cost Code"]};
Readonly::Scalar my $PROJECT_LIMSID          => q{prj:project/@limsid};

Readonly::Scalar my $TAG_PLATE_PROCESS_NAME  => q{Library PCR set up};

Readonly::Scalar my $CONTROL_SAMPLE_UUID     => q{d3a59c4c-c037-11e0-834c-00144f01a414};
Readonly::Scalar my $CONTROL_STUDY_UUID      => q{2aa1cd2e-a557-11df-8092-00144f01a414};
Readonly::Scalar my $CONTROL_TAG_INDEX       => q{888};
Readonly::Scalar my $CONTROL_TAG_SEQUENCE    => q{ACAACGCAATC};
Readonly::Scalar my $CONTROL_TAG_SET_NAME    => q{Sanger_168tags - 10 mer tags};
Readonly::Scalar my $CONTROL_ENTITY_TYPE     => q{library_indexed_spike};

Readonly::Scalar my $REAGENT_LOT_URI_PATH    => q{/stp:lots/reagent-lots/reagent-lot/@uri};
Readonly::Scalar my $REAGENT_KIT_NAME_PATH   => q{/lot:reagent-lot/reagent-kit/@name};
Readonly::Scalar my $SPIKED_HYB_BUFFER       => q{Spiked Hyb Buffer};
Readonly::Scalar my $LOT_NUMBER_PATH         => q{/lot:reagent-lot/lot-number};
## use critic

sub type { return 'flowcell' };

# Unfortunately have to do this to get around message_enhancer requiring them
sub _build__lims_ids { return 'noop' };

# Override prepare_messages
# Unfortunately prepare_messages in message_enhancer expects all data to come from one
# model! This is almost never the case!
sub prepare_messages {
  my $self = shift;

  my %message = ();
  $message{$self->type} = $self->_get_flowcell_message();
  $message{'lims'}      = $self->config->clarity_mq->{'id_lims'};

  return [\%message];
}

sub _get_flowcell_message {
  my $self = shift;

  my $flowcell = wtsi_clarity::mq::messages::flowcell::flowcell->new(
    lanes               => $self->_lanes,
    flowcell_barcode    => $self->_flowcell_barcode,
    flowcell_id         => $self->_flowcell_id,
    forward_read_length => $self->_forward_read_length,
    reverse_read_length => $self->_reverse_read_length,
    updated_at          => strftime('%Y-%m-%Od %H:%M:%S', localtime),
  );

  return $flowcell->pack();
}

my @defaults = (is => 'ro', isa => 'Str');

has '_spiked_hyb_barcode' => @defaults, lazy_build => 1;

sub _build__spiked_hyb_barcode {
  my $self = shift;

  my @reagent_lot_uris = $self->fetch_and_parse($self->step_url . '/reagentlots')
                              ->findnodes($REAGENT_LOT_URI_PATH)
                              ->to_literal_list;

  return $self->_find_spiked_hyb_barcode(@reagent_lot_uris);
}

sub _find_spiked_hyb_barcode {
  my ($self, @uris) = @_;
  my $uri  = shift @uris || croak "Spike Hyb Buffer not used as a reagent at Cluster Generation";

  my $reagent_doc = $self->fetch_and_parse($uri);

  if($reagent_doc->findvalue($REAGENT_KIT_NAME_PATH) eq $SPIKED_HYB_BUFFER) {
    return $reagent_doc->findvalue($LOT_NUMBER_PATH) || croak 'Spiked hyb barcode was not set';
  } else {
    return $self->_find_spiked_hyb_barcode(@uris);
  }
}

has '_flowcell_barcode' => @defaults, lazy_build => 1;

sub _build__flowcell_barcode {
  my $self = shift;
  my $barcode = $self->process->findvalue($FLOWCELL_BARCODE_UDF);

  if (!$barcode) {
    croak 'Flowcell barcode was not set';
  }

  return $barcode;
}

has '_flowcell_id'         => @defaults, lazy_build => 1;

sub _build__flowcell_id {
  my $self = shift;
  my $limsid = $self->process->findvalue($PROCESS_LIMSID_PATH);
  my $placements = $self->_get_placements($limsid);
  my $container_uri = $placements->findvalue($CONTAINER_URI_PATH);
  my ($container_lims_id) = $container_uri =~ /^.*\/(.*)$/sxm;
  return $container_lims_id;
}

sub _get_placements {
  my ($self, $limsid) = @_;
  my $placements_uri = $self->config->clarity_api->{'base_uri'} . '/steps/' . $limsid . '/placements';
  return $self->fetch_and_parse($placements_uri);
}

has '_forward_read_length' => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_forward_read_length',
);

has '_reverse_read_length' => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_reverse_read_length',
);

has '_lanes' => (
  is         => 'ro',
  isa        => 'ArrayRef[HashRef]',
  lazy_build => 1,
);
sub _build__lanes {
  my $self = shift;
  my @output_analytes = $self->process
                             ->findnodes($OUTPUT_ARTIFACT_LIMSIDS)
                             ->to_literal_list;

  my @lanes = map { $self->_build_lane($_) } @output_analytes;
  return \@lanes;
}

sub _build_lane {
  my ($self, $artifact_id) = @_;
  my %lane = ();

  my $artifact = $self->fetch_and_parse($self->config->clarity_api->{'base_uri'} . '/artifacts/' . $artifact_id);

  my $well = $artifact->findvalue($ARTIFACT_WELL_PATH);
  $lane{'position'}       = $self->_extract_lane_position($well);
  $lane{'id_pool_lims'}   = $artifact->findvalue($ARTIFACT_NAME_PATH);
  $lane{'entity_id_lims'} = $artifact->findvalue($ARTIFACT_LIMSID_PATH);
  $lane{'samples'}        = $self->_build_samples($artifact);
  $lane{'controls'}       = $self->_build_controls();

  return \%lane;
}

sub _extract_lane_position {
  my ($self, $location) = @_;
  my ($row, $column) = split /:/sxm, $location;
  return $row;
}

sub _build_samples {
  my ($self, $artifact) = @_;

  my @sample_limsids = $artifact->findnodes($ARTIFACT_SAMPLE_LIMSID)->to_literal_list;
  my @samples = map { $self->_build_sample($_) } @sample_limsids;

  return \@samples;
}

sub _build_sample {
  my ($self, $sample_limsid) = @_;
  my %sample = ();
  my $sample_doc = $self->fetch_and_parse($self->config->clarity_api->{'base_uri'} . '/samples/' . $sample_limsid);

  $sample{'pipeline_id_lims'} = $PIPELINE_ID_LIMS;
  $sample{'entity_type'}      = $SAMPLE_ENTITY_TYPE;
  $sample{'is_r_and_d'}       = $IS_R_AND_D;

  # Stuff from sample
  $sample{'bait_name'} = $sample_doc->findvalue($SAMPLE_BAIT_NAME);
  $sample{'requested_insert_size_from'} = $sample_doc->findvalue($SAMPLE_INSERT_SIZE_FROM);
  $sample{'requested_insert_size_to'} = $sample_doc->findvalue($SAMPLE_INSERT_SIZE_TO);

  my $read_length = $sample_doc->findvalue($SAMPLE_READ_LENGTH);

  if (defined $read_length && !$self->has_forward_read_length && !$self->has_reverse_read_length) {
    $self->_forward_read_length($read_length);
    $self->_reverse_read_length($read_length);
  }

  $sample{'sample_uuid'} = $sample_doc->findvalue($SAMPLE_NAME);

  %sample = (%sample, $self->_get_project_info($sample_doc));

  %sample = (%sample, $self->_get_tag_info($sample_doc));

  return \%sample;
}

sub _get_project_info {
  my ($self, $sample_doc) = @_;
  my %project_info = ();
  my $project_doc = $self->fetch_and_parse($sample_doc->findvalue($SAMPLE_PROJECT_URI));

  $project_info{'cost_code'}     = $project_doc->findvalue($PROJECT_COST_CODE_PATH);
  $project_info{'study_id'} = $project_doc->findvalue($PROJECT_LIMSID);

  return %project_info;
}

sub _get_tag_info {
  my ($self, $sample_doc) = @_;
  my %tag_info = ();

  my $uri = $self->config->clarity_api->{'base_uri'} . '/artifacts?';
  my $sample_limsid = $sample_doc->findvalue($SAMPLE_LIMSID);

  my $params = 'samplelimsid=' . $sample_limsid;
  $params .= '&process-type=' . uri_escape($TAG_PLATE_PROCESS_NAME);

  $uri .= $params;

  my $artifact_list = $self->fetch_and_parse($uri)
                           ->findnodes($ARTIFACTS_ARTIFACT_URI);

  if ($artifact_list->size() == 0) {
    croak 'Could not find a previous artifact for sample ' . $sample_limsid . ' that has been through "Library PCR set up"';
  }

  my $artifact = $self->fetch_and_parse($artifact_list->pop()->value);

  my $reagent_label_name = $artifact->findvalue($ARTIFACT_REAGENT_NAME);

  ($tag_info{'tag_set_name'}, $tag_info{'tag_index'}, $tag_info{'tag_sequence'}) = $self->_extract_tag_info($reagent_label_name);

  $tag_info{'id_library_lims'} = $self->_get_id_library_lims($artifact);

  return %tag_info;
}

sub _extract_tag_info {
  my ($self, $reagent_label_name) = @_;
  my @result = $reagent_label_name =~ /^(.*):\stag\s(\d+)\s[(]([[:upper:]]+)[)]$/sxm;
  return @result;
}

sub _get_id_library_lims {
  my ($self, $artifact_doc) = @_;
  my $well = $artifact_doc->findvalue($ARTIFACT_LOCATION_VALUE);
  $well =~ s/://sxm;
  my $container_barcode = $self->_get_container_barcode($artifact_doc);
  return $container_barcode . q{:} . $well;
}

my %container_cache = ();

sub _get_container_barcode {
  my ($self, $artifact_doc) = @_;

  my $container_uri = $artifact_doc->findvalue($ARTIFACT_CONTAINER_URI);

  if (!exists $container_cache{$container_uri}) {
    my $container = $self->fetch_and_parse($container_uri);
    $container_cache{$container_uri} = $container->findvalue($CONTAINER_NAME);
  }

  return $container_cache{$container_uri};
}

sub _build_controls {
  my $self = shift;
  my @controls = ();

  # Always will be just the one...
  my %control = ();
  $control{'sample_uuid'}      = $CONTROL_SAMPLE_UUID;
  $control{'study_uuid'}       = $CONTROL_STUDY_UUID;
  $control{'tag_index'}        = $CONTROL_TAG_INDEX;
  $control{'tag_sequence'}     = $CONTROL_TAG_SEQUENCE;
  $control{'tag_set_name'}     = $CONTROL_TAG_SET_NAME;
  $control{'entity_type'}      = $CONTROL_ENTITY_TYPE;
  $control{'id_library_lims'}  = $self->_spiked_hyb_barcode;
  $control{'pipeline_id_lims'} = $PIPELINE_ID_LIMS;

  push @controls, \%control;

  return \@controls;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::flowcell_enhancer

=head1 SYNOPSIS

  my $me = wtsi_clarity::mq::me::flowcell_enhancer
             ->new(
               process_url => 'http://process',
               step_url    => 'http://step',
               timestamp   => '123456789',
             )
             ->prepare_messages;

=head1 DESCRIPTION

 Gets all the info to prepare a flowcell message to be sent to the warehouse queue

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

=head2 type

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item Carp

=item URI::Escape

=item POSIX

=item wtsi_clarity::mq::messages::flowcell::flowcell

=item wtsi_clarity::mq::message_enhancer

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL

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
