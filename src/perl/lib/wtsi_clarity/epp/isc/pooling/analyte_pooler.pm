package wtsi_clarity::epp::isc::pooling::analyte_pooler;

use Moose;
use Carp;
use Readonly;
use XML::LibXML::NodeList;
use List::MoreUtils qw/uniq/;
use Moose::Util::TypeConstraints;

use wtsi_clarity::isc::pooling::mapper;
use wtsi_clarity::epp::isc::pooling::bait_library_mapper;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::epp::isc::pooling::pooling_common';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $BATCH_CONTAINER_PATH     => q{/art:details/art:artifact/location/container/@uri };
Readonly::Scalar my $BATCH_ARTIFACT_PATH      => q{/art:details/art:artifact };
Readonly::Scalar my $ARTIFACT_URI_PATH        => q{/art:artifact/@uri };
Readonly::Scalar my $ARTIFACT_LOCATION_PATH   => q{location/value };
Readonly::Scalar my $ARTIFACT_CONTAINER_PATH  => q{location/container/@limsid };
Readonly::Scalar my $CONTAINER_LIMSID_PATH    => q{/con:details/con:container/@limsid };
Readonly::Scalar my $SAMPLE_URI_PATH          => q{/art:details/art:artifact/sample/@uri};
Readonly::Scalar my $BAIT_LIBRARY_PATH        => q{/smp:details/smp:sample/udf:field[@name='WTSI Bait Library Name']/text()};
## use critic
Readonly::Scalar my $SAMPLE_PATH              => q{/smp:details/smp:sample};

Readonly::Scalar my $PLEX_8                   => q{8};
Readonly::Hash   my %PLEXING_METHODS          => {
  '8_plex'   => 'wtsi_clarity::epp::isc::pooling::pooling_by_8_plex',
  '16_plex'  => 'wtsi_clarity::epp::isc::pooling::pooling_by_16_plex',
};

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_input_artifacts' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts {
  my $self = shift;

  return $self->process_doc->input_artifacts;
}

has '_input_artifacts_location' => (
  isa             => 'HashRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts_location {
  my $self = shift;

  my %artifacts_location;

  my @artifact_node_list = $self->_input_artifacts->findnodes($BATCH_ARTIFACT_PATH)->get_nodelist();

  foreach my $artifact_node (@artifact_node_list) {
    my $analyte_uri = $artifact_node->getAttribute('uri');
    my $analyte_location = $artifact_node->findnodes($ARTIFACT_LOCATION_PATH)->pop()->string_value;
    my $analyte_container = $artifact_node->findnodes($ARTIFACT_CONTAINER_PATH)->pop()->getValue;
    $artifacts_location{$analyte_container} ||= {};
    $artifacts_location{$analyte_container}{$analyte_location} = $analyte_uri;
  }
  return \%artifacts_location;
}

has '_samples' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__samples {
  my $self = shift;

  my @sample_node_list = $self->_input_artifacts->findnodes($SAMPLE_URI_PATH)->get_nodelist();
  my @sample_uris = map { $_->getValue } @sample_node_list;

  return $self->request->batch_retrieve('samples', \@sample_uris);
}



has '_container_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__container_uris {
  my $self = shift;

  my $uri_node_list = $self->_input_artifacts->findnodes($BATCH_CONTAINER_PATH);
  my @container_uris = uniq(map { $_->getValue } $uri_node_list->get_nodelist);

  return \@container_uris;
}

has '_container_ids' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__container_ids {
  my $self = shift;

  my $containers = $self->request->batch_retrieve('containers', $self->_container_uris);
  my $container_name_node_list = $containers->findnodes($CONTAINER_LIMSID_PATH);
  my @container_ids = uniq(map { $_->string_value } $container_name_node_list->get_nodelist);

  return \@container_ids;
}

has '_mapping' => (
  isa             => 'HashRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__mapping {
  my $self = shift;

  my $container_ids = $self->_container_ids;

  my $mapper = wtsi_clarity::isc::pooling::mapper->new(
    container_ids => $container_ids,
  );

  return $mapper->mapping;
}

has '_pools_doc' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__pools_doc {
  my $self = shift;
  my $pool_request_uri = join q{/}, ($self->step_url, 'pools');

  return $self->fetch_and_parse($pool_request_uri);
}

has '_bait_library' => (
  isa             => 'Str',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__bait_library {
  my $self = shift;

  my @bait_library_node_list = $self->_samples->findnodes($BAIT_LIBRARY_PATH);
  my @bait_libraries = map { $_->getValue() } @bait_library_node_list;

  my $samples_count = $self->_samples->findnodes($SAMPLE_PATH)->get_nodelist;
  my $bait_libraries_count = @bait_libraries;

  @bait_libraries = uniq(@bait_libraries);

  if (scalar @bait_libraries == 0) {
    croak q{The samples does not contains Bait Library Name information.};
  } elsif ($samples_count !=  $bait_libraries_count) {
    croak q{One or some of the samples does not contains Bait Library Name information.};
  } elsif (scalar @bait_libraries > 1) {
    my $library_names = join q{, }, @bait_libraries;
    croak qq{The samples contains multiple Bait Libraries. It is not supported. The step contains the following libraries: $library_names};
  }

  return $bait_libraries[0];
}

sub _plexing_mode_by_bait_library {
  my ($self, $bait_library_name) = @_;

  my $bait_library_mapper = wtsi_clarity::epp::isc::pooling::bait_library_mapper->new();

  return $bait_library_mapper->plexing_mode_by_bait_library($bait_library_name);
}

duck_type 'WtsiClarityPoolingStrategy', [qw/get_pool_name/];

has '_pooling_strategy' => (
  isa             => 'WtsiClarityPoolingStrategy',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__pooling_strategy {
  my $self = shift;

  my $plexing_method = $PLEXING_METHODS{$self->_plexing_mode_by_bait_library($self->_bait_library)};
  if (!defined $plexing_method) {
    croak qq{The plexing method for bait: ($self->_bait_info) you would like to use is not defined.};
  }

  my $loaded = eval "require $plexing_method";
  if (!$loaded) {
    croak qq{Failed to require $plexing_method};
  }

  return $plexing_method->new();
}

has '_pools' => (
  isa             => 'HashRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__pools {
  my $self = shift;

  my $mappings = $self->_mapping;
  my $pools = {};
  while ( my ($container_limsid, $locations_and_analyte_uris) = each %{$self->_input_artifacts_location}) {
    my $container_mapping = $mappings->{$container_limsid};
     while ( my ($location, $analyte_uri) = each %{$locations_and_analyte_uris}) {
      my $mapping = $container_mapping->{$location};
      my $pool_name = join q{ },
        $self->process_doc->get_container_name_by_limsid($container_limsid),
        $self->get_pool_name_by_plexing($mapping->{'dest_well'}, $self->_pooling_strategy);

      $pools->{$pool_name} ||= [];
      push @{$pools->{$pool_name}}, $analyte_uri;
    }
  }

  return $pools;
}

sub _create_pools {
  my $self = shift;

  my $pools_doc = $self->_pools_doc;
  my $pooled_inputs_element = $pools_doc->getElementsByTagName('pooled-inputs')->pop();

  while ( my ($pool_name, $analyte_uris) = each %{$self->_pools} ) {
    my $pool_element = $pools_doc->createElement('pool');
    $pool_element->setAttribute('name', $pool_name);

    foreach my $analyte_uri (@{$analyte_uris}) {
      my $analyte_uri_element = $pools_doc->createElement('input');
      $analyte_uri_element->setAttribute('uri', $analyte_uri);
      $pool_element->addChild($analyte_uri_element);
    }

    $pooled_inputs_element->addChild($pool_element);
  }

  # needs to remove the available inputs node
  for my $input_element ($pools_doc->findnodes(q{/stp:pools/available-inputs/input})) {
    $input_element->unbindNode;
  }

  return $pools_doc;
}

sub update_step_with_pools {
  my $self = shift;
  my $pool_request_uri = join q{/}, ($self->step_url, 'pools');

  $self->request->put($pool_request_uri, $self->_create_pools->toString);

  return;
}

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method

  $self->update_step_with_pools;

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pooling::analyte_pooler

=head1 SYNOPSIS

  my $pooler = wtsi_clarity::epp::isc::pooling::analyte_pooler->new(
    process_url => $base_uri . '/processes/122-21977',
    step_url => $base_uri . '/steps/122-21977',
  );

=head1 DESCRIPTION

  This module is creates the pools from the analytes using the mapping module for pooling.

=head1 SUBROUTINES/METHODS

=head2 update_step_with_pools - Does a PUR request on the pools adding the pooled-inputs
to the step's pools.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item XML::LibXML::NodeList

=item wtsi_clarity::isc::pooling::mapper

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
