package wtsi_clarity::epp::generic::roles::container_common;

use Moose::Role;
use Readonly;
use Carp;
use XML::LibXML;

our $VERSION = '0.0';

Readonly::Scalar my $XML_HEADER_STR                   => q{<?xml version="1.0" encoding="UTF-8"?>};
Readonly::Scalar my $CONTAINER_HEADER_START_STR       => q{<con:container xmlns:con="http://genologics.com/ri/container">};
Readonly::Scalar my $CONTAINER_HEADER_END_STR         => q{</con:container>};
Readonly::Scalar my $CONTAINERTYPES_URI_PATH          => q{containertypes};

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $CONTAINER_TYPE_URI_PATH  => q{/ctp:container-types/container-type/@uri[1]};
Readonly::Scalar my $CONTAINER_NAME_URI_PATH  => q{/ctp:container-types/container-type/@name[1]};
Readonly::Scalar my $CONTAINER_URI_PATH       => q{//con:container/@uri};
Readonly::Scalar my $CONTAINER_LIMSID_PATH    => q{//con:container/@limsid};
Readonly::Scalar my $CONTAINER_BARCODE_PATH   => q{//con:container/name};
##use critic

Readonly::Scalar our $PLATE_96_WELL_CONTAINER_NAME  => q{96 Well Plate};
Readonly::Scalar our $ABGENE_800_CONTAINER_NAME     => q{ABgene 0800};
Readonly::Scalar our $ABGENE_765_CONTAINER_NAME     => q{ABgene 0765};
Readonly::Scalar our $FLUIDX_075_CONTAINER_NAME     => q{FluidX075};
Readonly::Scalar our $STOCK_PLATE_PURPOSE           => q{Stock Plate};

Readonly::Hash    my %CONTAINER_PURPOSES        => {
  $PLATE_96_WELL_CONTAINER_NAME => $STOCK_PLATE_PURPOSE,
  $FLUIDX_075_CONTAINER_NAME    => $STOCK_PLATE_PURPOSE,
  $ABGENE_800_CONTAINER_NAME    => $STOCK_PLATE_PURPOSE,
  $ABGENE_765_CONTAINER_NAME    => $STOCK_PLATE_PURPOSE,
};

sub get_container_purpose {
  my ($self, $container_type) = @_;

  return $CONTAINER_PURPOSES{$container_type};
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

sub create_new_container {
  my ($self, $output_container_type_name) = @_;

  my $xml_header = $XML_HEADER_STR;
  $xml_header .= $CONTAINER_HEADER_START_STR;
  my $xml_footer = $CONTAINER_HEADER_END_STR;

  my $xml = $xml_header;

  my $container_type_data = $self->_get_new_container_type_data_by_name($output_container_type_name);
  my $output_container_type_xml_str = "<type uri='$container_type_data->{'uri'}' name='$container_type_data->{'name'}' />";

  $xml .= $output_container_type_xml_str;
  $xml .= $xml_footer;

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
  $container_type_data->{'uri'} = $container_type_xml->findvalue($CONTAINER_TYPE_URI_PATH);
  $container_type_data->{'name'} = $container_type_xml->findvalue($CONTAINER_NAME_URI_PATH);

  return $container_type_data;
}

sub get_container_data {
  my ($self, $container_xml) = @_;

  my $uri = $container_xml->findvalue($CONTAINER_URI_PATH);
  my $limsid = $container_xml->findvalue($CONTAINER_LIMSID_PATH);
  my $barcode = $container_xml->findvalue($CONTAINER_BARCODE_PATH);

  return {
    'limsid'  => $limsid,
    'uri'     => $uri,
    'barcode' => $barcode
  }
}

sub batch_retrieve_containers_xml {
  my ($self, $container_uris) = @_;

  return $self->request->batch_retrieve('containers', $container_uris);
}

no Moose::Role;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::roles::container_common

=head1 SYNOPSIS

  with 'wtsi_clarity::epp::generic::roles::container_common';

=head1 DESCRIPTION

  Common utility methods for dealing with containers.

=head1 SUBROUTINES/METHODS

=head2 create_new_container

  Creates a new container in the system with the given type
  and returns the XML document of the new container.

=head2 get_container_data

  Returns the `limsid` and `uri` of the given container in a hash structure.

=head2 batch_retrieve_containers_xml

  Retrives the containers XML documents for the given container URIs.

=head2 get_container_purpose

  Returns the purpose of the container by the given container type.

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
