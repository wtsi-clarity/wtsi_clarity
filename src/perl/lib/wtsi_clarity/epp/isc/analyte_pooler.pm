package wtsi_clarity::epp::isc::analyte_pooler;

use Moose;
use Carp;
use Readonly;
use XML::LibXML::NodeList;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

# use aliased 'XML::LibXML::NodeList' => 'get_stringvalue_from_nodelist';

# *get_value_from_nodelist = \&XML::LibXML::NodeList::getValue;
# *get_stringvalue_from_nodelist = \&XML::LibXML::NodeList::string_value;

Readonly::Scalar my $INPUT_URIS_PATH      => q(/prc:process/input-output-map/input/@uri);
Readonly::Scalar my $BATCH_CONTAINER_PATH => q{/art:details/art:artifact/location/container/@uri };
Readonly::Scalar my $CONTAINER_NAME_PATH  => q{/con:details/con:container/name };

sub _get_stringvalue_from_nodelist {
  my $self = shift;

  return q\XML::LibXML::NodeList::getValue\;
}

has '_input_artifacts' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts {
  my $self = shift;

  my $input_node_list = $self->process_doc->findnodes($INPUT_URIS_PATH);
  my $input_uris = $self->_get_values_from_nodelist('getValue', $input_node_list);

  return $self->request->batch_retrieve('artifacts', $input_uris);
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

  return $self->_get_values_from_nodelist('getValue', $uri_node_list);
}

has '_container_names' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__container_names {
  my $self = shift;

  my $containers = $self->request->batch_retrieve('containers', $self->_container_uris);
  my $container_name_node_list = $containers->findnodes($CONTAINER_NAME_PATH);

  return $self->_get_values_from_nodelist('string_value', $container_name_node_list);
}

sub _uniq_array {
  my ($self, @array) = @_;

  my %seen;
  return grep { !$seen{$_}++ } @array;
}

sub _get_values_from_nodelist {
  my ($self, $function, $nodelist) = @_;
  my @values = $self->_uniq_array(
    map { $_->$function } $nodelist->get_nodelist()
  );

  return \@values;
}

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method

  return;
};
