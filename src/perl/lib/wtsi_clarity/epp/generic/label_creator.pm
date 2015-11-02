package wtsi_clarity::epp::generic::label_creator;

use Moose;
use Carp;
use Readonly;
use DateTime;
use namespace::autoclean;
use List::MoreUtils qw/uniq any/;
use URI::Escape;

use wtsi_clarity::util::signature;

extends 'wtsi_clarity::epp';
with qw{wtsi_clarity::util::clarity_elements
  wtsi_clarity::util::print
  wtsi_clarity::util::label
  wtsi_clarity::epp::generic::roles::barcode_common
  wtsi_clarity::epp::isc::pooling::pooling_common};

our $VERSION = '0.0';

Readonly::Scalar my $CONTAINER_SIGNATURE_FIELD_NAME => q{WTSI Container Signature};
Readonly::Scalar my $LIB_PCR_PURIFICATION_PROCESS_NAME => q{Lib PCR Purification};

##no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PRINTER_PATH                  => q{ /prc:process/udf:field[contains(@name, 'Printer')] };
Readonly::Scalar my $NUM_COPIES_PATH               => q{ /prc:process/udf:field[@name='Barcode Copies'] };
Readonly::Scalar my $DEFAULT_NUM_COPIES            => 1;

Readonly::Scalar my $PLATE_PURPOSE_PATH            => q{ /prc:process/udf:field[@name='Plate Purpose'] };
Readonly::Scalar my $CONTAINER_PURPOSE_PATH        => q{ /con:container/udf:field[@name='WTSI Container Purpose Name'] };

Readonly::Scalar my $IO_MAP_PATH                   => q{ /prc:process/input-output-map};
Readonly::Scalar my $IO_MAP_PATH_ANALYTE_OUTPUT    => $IO_MAP_PATH . q{[output[@output-type='Analyte' or @output-type='Pool']] };
Readonly::Scalar my $CONTAINER_URI_PATH            => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $SAMPLE_PATH                   => q{ /art:artifact/sample/@limsid };
Readonly::Scalar my $SAMPLE_URI_PATH               => q{ /art:artifact/sample[1]/@uri };
Readonly::Scalar my $CONTROL_PATH                  => q{ /art:artifact/control-type };

Readonly::Scalar my $CONTAINER_LIMSID_PATH         => q{ /con:container/@limsid };
Readonly::Scalar my $SUPPLIER_CONTAINER_NAME_PATH  => q{ /con:container/udf:field[@name='Supplier Container Name'] };
Readonly::Scalar my $CONTAINER_NAME_PATH           => q{ /con:container/name };
Readonly::Scalar my $INPUT_ANALYTES_PATH           => q{./input/@uri};
Readonly::Scalar my $TUBE_LOCATION_PATH            => q{ /art:artifact/location/value};
Readonly::Scalar my $BAIT_LIBRARY_NAME_PATH        => q{ /smp:sample/udf:field[@name='WTSI Bait Library Name']/text()};
Readonly::Scalar my $SAMPLE_LIMSID_PATH            => q{ /smp:sample/@limsid};
Readonly::Scalar my $ARTIFACT_LIMSID_PATH          => q{ /art:artifacts/artifact/@limsid};
Readonly::Scalar my $ARTIFACT_URI_PATH             => q{ /art:artifacts/artifact[@limsid='%s']/@uri};
Readonly::Scalar my $CONTAINER_SIGNATURE_PATH      => q{ /con:container/udf:field[@name='} . $CONTAINER_SIGNATURE_FIELD_NAME . q{']/text()};
Readonly::Scalar my $STEP_OUTPUT_CONTAINERS        => q{ stp:placements/selected-containers/container/@uri };
Readonly::Scalar my $EACH_CONTAINER_LIMS_ID        => q{ con:details/con:container/@limsid };

Readonly::Scalar my $FIRST_ANALYTE_URI        => q{ con:details/con:container/placement[1]/@uri };
Readonly::Scalar my $EACH_ARTIFACT            => q{ art:details/art:artifact };
Readonly::Scalar my $ANALYTE_CONTAINER_LIMSID => q{ ./location/container/@limsid };
Readonly::Scalar my $ANALYTE_SAMPLE_LIMSID    => q{ ./sample/@limsid };
Readonly::Scalar my $LAST_ARTIFACT            => q{ art:artifacts/artifact[last()]/@uri };
Readonly::Scalar my $FIRST_CONTAINER          => q{ con:containers/container[1]/@limsid };

##use critic

Readonly::Scalar my $SIGNATURE_LENGTH              => 5;
Readonly::Scalar my $DEFAULT_CONTAINER_TYPE        => 'plate';

Readonly::Array  my @TUBELIKE                      => qw{ tube };

has 'source_plate' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
);

has 'get_sanger_barcode_from' => (
  isa       => 'Str',
  is        => 'ro',
  required  => 0,
  predicate => 'has_get_sanger_barcode_from',
);

has 'step_url' => (
  isa       => 'Str',
  is        => 'ro',
  required  => 0,
  predicate => 'has_step_url',
);

has 'container_type' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  default    => $DEFAULT_CONTAINER_TYPE,
);

has 'increment_purpose' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
);

has 'printer' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_printer {
  my $self = shift;

  my @nodes = $self->process_doc->findnodes($PRINTER_PATH);
  if (!@nodes) {
    croak 'Printer udf field should be defined for the process';
  }
  if (scalar @nodes > 1) {
    croak 'Multiple printer udf fields are defined for the process';
  }

  my $printer = $self->trim_value($nodes[0]->textContent);
  if (!$printer) {
    croak 'Printer name should be defined';
  }
  return $printer;
}

has 'user' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_user {
  my $self = shift;

  my $technician_node = $self->process_doc->find(q(prc:process/technician))->[0];
  my $user = q[];

  if ($technician_node) {
    $user = $technician_node->find(q(./first-name))->[0]->textContent;
    if ($user) {
      $user = substr $user, 0, 1;
      $user .= q[.];
    }
    my $sn = $technician_node->find(q(./last-name))->[0]->textContent;
    if ($sn) {
      $user .= " $sn";
    }
  }
  return $user;
}

has '_num_copies' => (
  isa        => 'Int',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__num_copies {
  my $self = shift;
  my @nodes = $self->process_doc->findnodes($NUM_COPIES_PATH);
  if (!@nodes) {
    return $DEFAULT_NUM_COPIES;
  }
  if (scalar @nodes > 1) {
    croak 'Multiple barcode copies udf fields are defined for the process';
  }
  return $nodes[0]->textContent || $DEFAULT_NUM_COPIES;
}

has '_plate_purpose' => (
  isa        => 'Maybe[Str]',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__plate_purpose {
  my $self = shift;
  my @nodes = $self->process_doc->findnodes($PLATE_PURPOSE_PATH);
  if (scalar @nodes > 1) {
    croak 'Multiple plate purpose udf fields are defined for the process';
  }
  if (@nodes) {
    return $self->trim_value($nodes[0]->textContent);
  }
  return;
}

has '_container' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container {
  my $self = shift;

  my $iopath = $self->source_plate ? $IO_MAP_PATH : $IO_MAP_PATH_ANALYTE_OUTPUT;
  my @nodes = $self->process_doc->findnodes($iopath);
  if (!@nodes) {
    croak 'No analytes registered';
  }

  my $containers = {};
  foreach my $anode (@nodes) {
    my $path = $self->source_plate ? q[input] : q[output];
    ##no critic (RequireInterpolationOfMetachars)
    my $url = $anode->findvalue(q{./} . $path . q{/@uri});
    ##use critic
    my $analyte_dom = $self->fetch_and_parse($url);
    my $container_url = $analyte_dom->findvalue($CONTAINER_URI_PATH);
    if (!$container_url) {
      croak qq[Container not defined for $url];
    }

    if (!exists $containers->{$container_url}) {
      $containers->{$container_url}->{'doc'} = $self->fetch_and_parse($container_url);
    }
    my @control_flag = $analyte_dom->findnodes($CONTROL_PATH);
    if (!@control_flag) {
      # Sample list should not contain controls
      my @sample_lims_ids = $analyte_dom->findnodes($SAMPLE_PATH)->to_literal_list;
      if (!@sample_lims_ids) {
        croak qq[Sample lims id not defined for $url];
      }
      push @{$containers->{$container_url}->{'samples'}}, @sample_lims_ids;
    }

    $containers->{$container_url}->{'signature'} =
      ($containers->{$container_url}->{'samples'}) ?
        $self->_get_signature($containers->{$container_url}->{'samples'}) : q{};

    if ((any {
      $_ eq $self->container_type
    } @TUBELIKE) && !exists $containers->{$container_url}->{'parent_barcode_with_pooling_range'}) {
      my $input_analyte_dom = $self->fetch_and_parse($anode->findvalue($INPUT_ANALYTES_PATH));

      my $sample_data = $self->_sample_data($input_analyte_dom);

      $containers->{$container_url}->{'tube_signature_and_pooling_range'} =
        $containers->{$container_url}->{'signature'} .
          q{ } .
          $self->_pooling_range($input_analyte_dom, $sample_data->{'bait_library_name'});

      my $artifact_doc = $self->_search_artifact_by_process_and_samplelimsid($LIB_PCR_PURIFICATION_PROCESS_NAME, $sample_data->{'limsid'});
      my $container_xml = $self->_container_doc($artifact_doc);
      $containers->{$container_url}->{'original_plate_signature'} = $self->_signature_from_container($container_xml);
    }
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get containers for process ] . $self->process_url;
  }

  return $containers;
}

sub _pooling_range {
  my ($self, $input_analyte_dom, $bait_library_name) = @_;

  my $destination_well_name = $self->_get_tube_location($input_analyte_dom);

  my $pool_name = $self->_plexing_strategy_by_bait_library($bait_library_name)->get_pool_name($destination_well_name);

  $pool_name =~ s/://xmsg;

  return $pool_name;
}

sub _get_tube_location {
  my ($self, $input_analyte_dom) = @_;

  return $input_analyte_dom->findvalue($TUBE_LOCATION_PATH);
}

has '_bait_library' => (
  isa             => 'Str',
  is              => 'ro',
  writer          => '_set_bait_library',
);

sub _plexing_strategy_by_bait_library {
  my ($self, $bait_library_name) = @_;

  $self->_set_bait_library($bait_library_name);

  return $self->pooling_strategy;
}

sub _sample_data {
  my ($self, $input_analyte_dom) = @_;

  my $sample_dom = $self->fetch_and_parse($input_analyte_dom->findvalue($SAMPLE_URI_PATH));

  return  {
    'bait_library_name' => $sample_dom->findvalue($BAIT_LIBRARY_NAME_PATH),
    'limsid'            => $sample_dom->findvalue($SAMPLE_LIMSID_PATH)
  };
}

sub _search_artifact_by_process_and_samplelimsid {
  my ($self, $process_type, $sample_limsid) = @_;

  my $artifact_request_uri = $self->config->clarity_api->{'base_uri'} .
    q{/artifacts?} .
    q{samplelimsid=}  . $sample_limsid .
    q{&process-type=}  . uri_escape($process_type) .
    q{&type=Analyte};

  my $artifact_xml = $self->fetch_and_parse($artifact_request_uri);
  my @artifact_limsids_nodes = $artifact_xml->findnodes($ARTIFACT_LIMSID_PATH)->get_nodelist;
  my @limsids = reverse uniq( sort map {
    $_->getValue()
  } @artifact_limsids_nodes);

  if (scalar @limsids < 1) {
    croak qq{The artifact could not be found by the given process: '$process_type' and samplelimsid: '$sample_limsid'.};
  }

  my $searched_artifact_uri = $artifact_xml->findvalue(sprintf $ARTIFACT_URI_PATH, $limsids[0]);

  return $self->fetch_and_parse($searched_artifact_uri);
}

sub _container_doc {
  my ($self, $artifact_doc) = @_;

  my $container_uri = $artifact_doc->findvalue($CONTAINER_URI_PATH);

  return $self->fetch_and_parse($container_uri);
}

sub _signature_from_container {
  my ($self, $container_doc) = @_;

  my $signature = $container_doc->findvalue($CONTAINER_SIGNATURE_PATH);

  if (!defined $signature || length $signature < 1) {
    croak q{The signature has not been registered on this container.};
  }

  return $signature;
}

has '_plate_purpose_suffix' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  default    => sub {
    my @a = ('A'..'Z');
    return \@a;
  },
);

has '_plate_to_parent_plate_map' => (
  isa      => 'HashRef',
  is       => 'rw',
  required => 0,
  writer   => q{_set_plate_to_parent_plate_map},
  default  => sub {
    {
    }
  },
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  $self->_check_options();

  $self->_set_container_data();
  $self->_update_container();

  my $template = $self->_generate_labels();

  $self->print_labels($self->printer, $template);

  return;
};

sub _check_options {
  my $self = shift;

  if ($self->has_get_sanger_barcode_from && !$self->has_step_url) {
    croak 'Step URL must be provided when get_sanger_barcode_from is set';
  }

  return 1;
}

sub _fetch_sanger_barcode {
  my ($self, $step_name) = @_;

  # Fetch the output containers
  my $placements = $self->fetch_and_parse($self->step_url . q{/placements});
  my @output_containers = $placements->findnodes($STEP_OUTPUT_CONTAINERS)->to_literal_list;
  my $container_xml = $self->request->batch_retrieve('containers', \@output_containers);
  # Fetch the first analyte from each container
  my @analyte_uris = $container_xml->findnodes($FIRST_ANALYTE_URI)->to_literal_list;
  my $analytes_xml = $self->request->batch_retrieve('artifacts', \@analyte_uris);

  my %limsid_to_num = ();

  foreach my $analyte ($analytes_xml->findnodes($EACH_ARTIFACT)) {

    my $container_limsid = $analyte->findvalue($ANALYTE_CONTAINER_LIMSID);
    my $sample_limsid = $analyte->findvalue($ANALYTE_SAMPLE_LIMSID);

    my $artifacts_uri = $self->config->clarity_api->{'base_uri'}
      . q{/artifacts?type=Analyte&process-type=}
      . uri_escape($step_name)
      . q{&samplelimsid=} . $sample_limsid;

    my $artifacts_xml = $self->fetch_and_parse($artifacts_uri);

    my $artifact_uri = $artifacts_xml->findvalue($LAST_ARTIFACT);

    if ($artifact_uri eq q{}) {
      $self->epp_log('No parent plate of plate ' . $container_limsid . ' has been through step ' . $step_name);
      next;
    }

    my $artifact_xml = $self->fetch_and_parse($artifact_uri);
    my $container_uri = $artifact_xml->findvalue($CONTAINER_URI_PATH);
    my $container_from_step_xml = $self->fetch_and_parse($container_uri);
    my $container_name = $container_from_step_xml->findvalue($CONTAINER_NAME_PATH);

    my $container_search_uri = $self->config->clarity_api->{'base_uri'}
      . q{/containers?name=} . $container_name;

    my $container_search_xml = $self->fetch_and_parse($container_search_uri);
    my $container_search_xml_limsid = $container_search_xml->findvalue($FIRST_CONTAINER);

    my $barcode = $self->get_barcode_from_id($container_search_xml_limsid);

    if ($barcode =~ /[0-9]{13}/) {
      $barcode = $self->generate_barcode($container_search_xml_limsid);
    }

    $limsid_to_num{$container_limsid} = $barcode;
  }
  return \%limsid_to_num;
}

sub _generate_labels {
  my $self = shift;

  return $self->generateLabels({
    'number'       => $self->_num_copies,
    'type'         => $self->container_type,
    'user'         => $self->user,
    'containers'   => $self->_container,
    'source_plate' => $self->source_plate,
  });
}

sub _set_container_data {
  my $self = shift;

  if ($self->has_get_sanger_barcode_from) {
    $self->epp_log('Fetching Sanger Barcodes from ' . $self->get_sanger_barcode_from);
    my $plate_to_parent_plate_map = $self->_fetch_sanger_barcode($self->get_sanger_barcode_from);
    $self->_set_plate_to_parent_plate_map($plate_to_parent_plate_map);
    $self->epp_log('Found Sanger Barcodes for ' . (scalar keys %{$plate_to_parent_plate_map}) . ' plate(s)');
  }

  my $count = 0;
  my @urls = keys %{$self->_container};

  foreach my $container_url (@urls) {
    my $container = $self->_container->{$container_url};
    my $doc = $container->{'doc'};
    my $lims_id = $doc->findvalue($CONTAINER_LIMSID_PATH);
    if (!$lims_id) {
      croak qq[No limsid for $container_url];
    }
    $container->{'limsid'} = $lims_id;
    if ($self->source_plate) {
      # SM first step only
      $self->_copy_supplier_container_name($doc);
    }

    my $suffix = ( scalar @urls == 1 || !$self->increment_purpose ) ?
      q[] : $self->_plate_purpose_suffix->[$count];
    $container->{'purpose'} = $self->_copy_purpose($doc, $suffix);

    my ($barcode, $num) = $self->generate_barcode($lims_id);
    $container->{'barcode'} = $barcode;
    $container->{'num'} = $num;

    if ($self->has_get_sanger_barcode_from &&
      exists $self->_plate_to_parent_plate_map->{$container->{'limsid'}}) {

      $container->{'sanger_barcode'} = $self->_plate_to_parent_plate_map->{$container->{'limsid'}};
    }

    $self->_copy_barcode2container($doc, $barcode);

    $self->_add_signature_to_container_doc($container);

    $count++;
  }

  return;
}

sub _add_signature_to_container_doc {
  my ($self, $container) = @_;

  $self->add_udf_element($container->{'doc'}, $CONTAINER_SIGNATURE_FIELD_NAME, $container->{'signature'});

  return;
}

sub _get_signature {
  my ($self, $samples) = @_;
  my @uniq_samples = uniq(@{$samples});
  return wtsi_clarity::util::signature->new(sig_length => $SIGNATURE_LENGTH)->encode(sort @uniq_samples);
}

sub _update_container {
  my $self = shift;
  foreach my $container_url (keys %{$self->_container}) {
    my $doc = $self->_container->{$container_url}->{'doc'};

    $self->request->put($container_url, $doc->toString);
  }
  return;
}

sub _copy_purpose {
  my ($self, $doc, $suffix) = @_;

  my $nodes = $doc->findnodes($CONTAINER_PURPOSE_PATH);
  if ($nodes->size > 1) {
    croak 'Only one container purpose node is possible';
  }

  my $purpose;
  if ($nodes->size == 1) {
    # At cherry-picking stage purpose is preset
    $purpose = $nodes->pop()->textContent();
    if (!$purpose) {
      croak qq[No purpose in $CONTAINER_PURPOSE_PATH];
    }
  } else {
    $purpose = $self->_plate_purpose;
    if ($suffix) {
      $purpose .= " $suffix";
    }
    $self->add_udf_element($doc, q[WTSI Container Purpose Name], $purpose);
  }

  return $purpose;
}

sub _copy_supplier_container_name {
  my ($self, $doc) = @_;

  my @supplier_nodes = $doc->findnodes($SUPPLIER_CONTAINER_NAME_PATH);

  if (!@supplier_nodes) {
    # Copy only if does not exists,
    # otherwise we might overwrite the value.
    my @nodes = $doc->findnodes($CONTAINER_NAME_PATH);
    if (!@nodes || scalar @nodes > 1) {
      croak 'Only one container name node is possible';
    }
    my $name = $nodes[0]->textContent();
    if ($name) {
      $name = $self->trim_value($name);
    }
    if (!$name) {
      croak 'Container name undefined';
    }
    $self->add_udf_element($doc, 'Supplier Container Name', $name);
  }
  return;
}

sub _copy_barcode2container {
  my ($self, $doc, $barcode) = @_;

  my $nodes = $doc->findnodes($CONTAINER_NAME_PATH);
  if ($nodes->size == 0 || $nodes->size > 1) {
    croak 'Multiple or none container name nodes';
  }
  $self->update_text($nodes->pop(), $barcode);
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::label_creator

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::label_creator->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a barcode and sets it for the containers (if required), formats the label  and prints it.

=head1 SUBROUTINES/METHODS

=head2 process_url

  Clarity process url, required.

=head2 printer

  Printer name (as known to the print service), an optional attribute.

=head2 user

  User name as it appears on a label, an optional attribute.

=head2 source_plate

  A boolean flag indicating whether source or target plates have to be considered
  false by default, meaning that target plates should be considered bt default, an optional attribute.

=head2 increment_purpose

  A boolean flag indicating whether container purpose has to be incremented in
  case of multiple outputs, defaults to false, an optional attribute.

=head2 get_sanger_barcode_from

  An optional string that can be set to the name of a previous step. The "sanger barcodes" for the matching
  containers in this previous step will be added to the label for these new containers.

=head2 run

  Callback for the label_creator action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=item Readonly

=item DateTime

=item List::MoreUtils

=item wtsi_clarity::util::barcode

=item wtsi_clarity::util::signature

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::util::print

=item wtsi_clarity::util::label

=back

=head1 AUTHOR

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
