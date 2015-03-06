package wtsi_clarity::epp::isc::analyte_pooler;

use Moose;
use Carp;
use Readonly;
use XML::LibXML::NodeList;
use List::MoreUtils qw/uniq/;

use wtsi_clarity::isc::pooling::mapper;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $BATCH_CONTAINER_PATH     => q{/art:details/art:artifact/location/container/@uri };
Readonly::Scalar my $BATCH_ARTIFACT_PATH      => q{/art:details/art:artifact };
Readonly::Scalar my $ARTIFACT_URI_PATH        => q{/art:artifact/@uri };
Readonly::Scalar my $ARTIFACT_LOCATION_PATH   => q{location/value };
Readonly::Scalar my $CONTAINER_LIMSID_PATH      => q{/con:details/con:container/@limsid };
## use critic

Readonly::Hash my %POOL_NAMES_BY_TARGET_WELL => {
  'A:1' => 'A1:H1',
  'B:1' => 'A2:H2',
  'C:1' => 'A3:H3',
  'D:1' => 'A4:H4',
  'E:1' => 'A5:H5',
  'F:1' => 'A6:H6',
  'G:1' => 'A7:H7',
  'H:1' => 'A8:H8',
  'A:2' => 'A9:H9',
  'B:2' => 'A10:H10',
  'C:2' => 'A11:H11',
  'D:2' => 'A12:H12'
};

sub _get_pool_name {
  my ($self, $destination_well_name) = @_;

  my $pool_name = $POOL_NAMES_BY_TARGET_WELL{$destination_well_name};

  croak qq{Pool name ($destination_well_name) is not defined for this destination well} if (! defined $pool_name);

  return $pool_name;
}

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_input_artifacts_location' => (
  isa             => 'HashRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts_location {
  my $self = shift;

  my %artifacts_location;
  my @artifact_node_list = $self->process_doc->input_artifacts->findnodes($BATCH_ARTIFACT_PATH)->get_nodelist();

  foreach my $artifact_node (@artifact_node_list) {
    my $analyte_uri = $artifact_node->getAttribute('uri');
    my $analyte_location = $artifact_node->findnodes($ARTIFACT_LOCATION_PATH)->pop()->string_value;
    $artifacts_location{$analyte_location} = $analyte_uri;
  }
  return \%artifacts_location;
}

has '_container_uris' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__container_uris {
  my $self = shift;

  my $uri_node_list = $self->process_doc->input_artifacts->findnodes($BATCH_CONTAINER_PATH);
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
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__mapping {
  my $self = shift;

  my $container_ids = $self->_container_ids;

  # for now we just supporting only one input container per pooling
  if (scalar @{$container_ids} > 1) {
    croak("Only 1 input container is supported.");
  }

  my $mapper = wtsi_clarity::isc::pooling::mapper->new(
    container_id => $container_ids->[0],
  );

  my $mapping = $mapper->mapping;

  return $mapping;
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
  while ( my ($location, $analyte_uri) = each %{$self->_input_artifacts_location}) {
    foreach my $mapping (@{$mappings}) {
      if ($mapping->{'source_well'} eq $location) {
        my $pool_name = join q{ }, $self->process_doc->get_container_name_by_limsid($mapping->{'source_plate'}), $self->_get_pool_name($mapping->{'dest_well'});
        $pools->{$pool_name} ||= [];
        push @{$pools->{$pool_name}}, $analyte_uri;
      }
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

wtsi_clarity::epp::isc::analyte_pooler

=head1 SYNOPSIS

  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
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
