package wtsi_clarity::epp::isc::pool_placer;

use Moose;
use Carp;
use Readonly;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

Readonly::Scalar my $POOL_NAME_PATH         => q{/art:artifact/name};
Readonly::Scalar my $OUTPUT_PLACEMENT_PATH  => q{/stp:placements/output-placements/output-placement};
## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $CONTAINER_PATH         => q{/stp:placements/selected-containers/container/@uri};
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

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_placements_doc' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__placements_doc {
  my $self = shift;
  my $placements_request_uri = join q{/}, ($self->step_url, 'placements');

  return $self->fetch_and_parse($placements_request_uri);
}

sub _pool_location {
  my ($self, $pool_uri) = @_;

  my $pool_details = $self->fetch_and_parse($pool_uri);

  my $pool_name = $pool_details->findnodes($POOL_NAME_PATH)->pop()->string_value;

  my ($range_start, $range_end) = $pool_name =~ /([[:upper:]]\d+):([[:upper:]]\d+)/gsmx;
  my $range = "$range_start:$range_end";
  my @pool_location = grep { $POOL_NAMES_BY_TARGET_WELL{$_} eq $range } keys %POOL_NAMES_BY_TARGET_WELL;

  return $pool_location[0];
}

has '_container_uri' => (
  isa             => 'Str',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__container_uri {
  my $self = shift;

  return $self->_placements_doc->findnodes($CONTAINER_PATH)->pop()->getValue();;
}

sub _create_location_element {
  my ($self, $location) = @_;
  my $placement_doc = $self->_placements_doc;
  my $container_uri = $self->_container_uri;
  my ($limsid) = ($container_uri =~ /(\d+-\d+$)/gmsx);

  my $location_element = $placement_doc->createElement('location');

  my $container_element = $placement_doc->createElement('container');
  $container_element->setAttribute('uri', $container_uri);
  $container_element->setAttribute('limsid', $limsid);

  my $value_element = $placement_doc->createElement('value');
  $value_element->appendTextNode($location);

  $location_element->addChild($container_element);
  $location_element->addChild($value_element);

  return $location_element;
}

sub _update_output_placements_with_location {
  my $self = shift;

  foreach my $output_placement_element ($self->_placements_doc->findnodes($OUTPUT_PLACEMENT_PATH)->get_nodelist()) {
    my $uri = $output_placement_element->getAttribute('uri');
    $output_placement_element->addChild(
      $self->_create_location_element($self->_pool_location($uri))
    );
  }

  return;
}

sub update_step_with_placements {
  my $self = shift;
  my $placements_request_uri = join q{/}, ($self->step_url, 'placements');

  $self->request->post($placements_request_uri, $self->_placements_doc->toString);

  return;
}

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method

  $self->_update_output_placements_with_location;

  $self->update_step_with_placements;

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pool_placer

=head1 SYNOPSIS

  my $placementer = wtsi_clarity::epp::isc::pool_placer->new(
    process_url => $base_uri . '/processes/122-21977',
    step_url => $base_uri . '/steps/122-21977',
  );

=head1 DESCRIPTION

  This module is placing the pools to their well locations based on the mapping module for pooling.

=head1 SUBROUTINES/METHODS

=head2 update_step_with_placements - Does a POST request on the placements resource adding location information
to the pools.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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
