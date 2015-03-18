package wtsi_clarity::epp::generic::stamper_common;

use Moose::Role;
use Readonly;
use Carp;
use XML::LibXML;

Readonly::Scalar my $PLACEMENT_URI_PATH               => q{placements};
Readonly::Scalar my $OUTPUT_PLACEMENTS_PATH           => q{/stp:placements/output-placements/output-placement};
Readonly::Scalar my $CONTAINERTYPES_URI_PATH          => q{containertypes};
Readonly::Scalar my $XML_HEADER_STR                   => q{<?xml version="1.0" encoding="UTF-8"?>};
Readonly::Scalar my $CONTAINER_HEADER_START_STR       => q{<con:container xmlns:con="http://genologics.com/ri/container">};
Readonly::Scalar my $CONTAINER_HEADER_END_STR         => q{</con:container>};
Readonly::Scalar my $PLATE_96_WELL_NUMBER_OF_COLUMNS  => 12;

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $CONTAINER_TYPE_URI_PATH  => q{/ctp:container-types/container-type/@uri[1]};
Readonly::Scalar my $CONTAINER_NAME_URI_PATH  => q{/ctp:container-types/container-type/@name[1]};
Readonly::Scalar my $BASE_CONTAINER_URI_PATH  => q{/stp:placements/selected-containers/container/@uri[1]};
Readonly::Scalar my $CONTAINER_URI_PATH       => q{/con:container/@uri};
Readonly::Scalar my $CONTAINER_LIMSID_PATH    => q{/con:container/@limsid};
##use critic

our $VERSION = '0.0';

has '_placement_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__placement_url {
  my ($self) = @_;

  return join q{/}, $self->step_url, $PLACEMENT_URI_PATH;
}

has '_container_type_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container_type_url {
  my ($self) = @_;

  return join q{/}, $self->config->clarity_api->{'base_uri'}, $CONTAINERTYPES_URI_PATH;
}

has '_base_placement_doc' => (
  isa        => 'XML::LibXML::Document',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__base_placement_doc {
  my ($self) = @_;

  my $placement_xml_raw = $self->request->get($self->_placement_url);
  my $parser = XML::LibXML->new();
  $parser->keep_blanks(0);

  my $placement_xml = $parser->load_xml(string => $placement_xml_raw );

  # needs to remove the available output-placement nodes
  for my $output_placement ($placement_xml->findnodes($OUTPUT_PLACEMENTS_PATH)) {
    $output_placement->unbindNode;
  }

  return $placement_xml;
}

sub get_basic_container_data {
  my ($self) = @_;

  my $uri = $self->_base_placement_doc->findvalue($BASE_CONTAINER_URI_PATH);
  my ($limsid) = $uri =~ /(\d{2}-\d+)/smx;

  return {
    'limsid'  => $limsid,
    'uri'     => $uri
  }
}

sub get_container_data {
  my ($self, $container_xml) = @_;

  my $uri = $container_xml->findvalue($CONTAINER_URI_PATH);
  my $limsid = $container_xml->findvalue($CONTAINER_LIMSID_PATH);

  return {
    'limsid'  => $limsid,
    'uri'     => $uri
  }
}

sub create_new_container {
  my ($self, $output_container_type_name) = @_;

  my $xml_header = $XML_HEADER_STR;
  $xml_header   .= $CONTAINER_HEADER_START_STR;
  my $xml_footer = $CONTAINER_HEADER_END_STR;

  my $xml = $xml_header;

  my $container_type_data = $self->_get_new_container_type_data_by_name($output_container_type_name);
  my $output_container_type_xml_str = "<type uri='$container_type_data->{'uri'}' name='$container_type_data->{'name'}' />";

  $xml   .= $output_container_type_xml_str;
  $xml   .= $xml_footer;

  my $url = $self->config->clarity_api->{'base_uri'} . '/containers';
  my $container_doc = XML::LibXML->load_xml(string => $self->request->post($url, $xml));

  return $container_doc;
}

sub _get_new_container_type_data_by_name {
  my ($self, $container_type_name) = @_;

  my $url = join q{?}, $self->_container_type_url, qq{name=$container_type_name};

  my $container_type_xml_raw = $self->request->get($url);
  my $parser = XML::LibXML->new();

  my $container_type_xml = $parser->load_xml(string => $container_type_xml_raw );

  if (length $container_type_xml->findvalue($CONTAINER_TYPE_URI_PATH) == 0) {
    croak qq{Container type can not be found by this name: $container_type_name};
  }
  my $container_type_data = ();
  $container_type_data->{'uri'}  = $container_type_xml->findvalue($CONTAINER_TYPE_URI_PATH);
  $container_type_data->{'name'} = $container_type_xml->findvalue($CONTAINER_NAME_URI_PATH);

  return $container_type_data;
}

sub add_container_to_placement {
  my ($self, $placement_doc, $container_uri) = @_;

  my $selected_containers_element =
    $placement_doc->getElementsByTagName('selected-containers')->pop();

  my $container_element = $placement_doc->createElement('container');
  $container_element->setAttribute('uri', $container_uri);

  $selected_containers_element->addChild($container_element);

  return;
}

sub init_96_well_location_values {
  my ($self) = @_;

  my @wells = (); # Ordered list of wells

  for (1..$PLATE_96_WELL_NUMBER_OF_COLUMNS) {
    foreach my $column ('A'..'H') {
      push @wells, $column . q{:} . $_;
    }
  }

  return \@wells;
}

sub create_output_placement_tag {
  my ($self, $placement_xml, $placement_uri, $container_data, $location_value) = @_;

  my $output_placement_element = $placement_xml->createElement('output-placement');
  $output_placement_element->setAttribute('uri', $placement_uri);

  my $location_element = $placement_xml->createElement('location');

  my $container_element = $placement_xml->createElement('container');
  $container_element->setAttribute('limsid', $container_data->{'limsid'});
  $container_element->setAttribute('uri', $container_data->{'uri'});

  my $value_element = $placement_xml->createElement('value');
  $value_element->appendTextNode($location_value);

  $location_element->addChild($container_element);
  $location_element->addChild($value_element);
  $output_placement_element->addChild($location_element);

  return $output_placement_element;
}

sub post_placement_doc {
  my ($self, $placement_xml) = @_;

  $self->request->post($self->_placement_url, $placement_xml->toString);

  return;
}

no Moose::Role;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::stamper_common

=head1 SYNOPSIS

  with 'wtsi_clarity::epp:generic::stamper_common';

=head1 DESCRIPTION

  Common utility methods for stamping.

=head1 SUBROUTINES/METHODS

=head2 get_basic_container_data

  Returns the `limsid` and `uri` of the base container in a hash structure.

=head2 get_container_data

  Returns the `limsid` and `uri` of the given container in a hash structure.

=head2 create_new_container

  Creates a new container in the system with the given type
  and returns the XML document of the new container.

=head2 add_container_to_placement

  Adds the given container to the placement XML document.

=head2 init_96_well_location_values

  Generates and returns an array of well locations, like ('A:1', 'B:1', 'C:1', ... ).

=head2 create_output_placement_tag

  Creates and returns the `output-placement` tag and returns this XML element.

=head2 post_placement_doc

  Sends the placement XML document as a HTTP POST request.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item XML::LibXML

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
