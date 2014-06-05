package wtsi_clarity::util::clarity_elements;

use Moose::Role;
use Carp;
use Readonly;
use XML::LibXML;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash my %NAME2ELEMENTS => (
  'volume' => {
    'create' => '_create_volume',
    'find'   => q( /smp:sample/udf:field[starts-with(@name, 'Volume')] ),
  },
  'supplier_sample_name' => {
    'create' => '_create_supplier_sample_name',
    'find'   => q( /smp:sample/udf:field[@name='WTSI Supplier Sample Name (SM)'] )
  },
  'name' => {
    'create' => '_create_name',
    'find'   => q( /smp:sample/name )
  },
  'date_received' => {
    'create' => '_create_date_received',
    'find'   => q ( /smp:sample/date-received )
  },
);
## use critic
## no critic(Subroutines::ProhibitUnusedPrivateSubroutines)

sub set_element {
  my ($self, $xml, $name, $value) = @_;

  if (!exists $NAME2ELEMENTS{$name}) {
    croak q/ Element can not be created /;
  }
  my $element = $NAME2ELEMENTS{$name};
  my $createMethod = $element->{'create'};

  my $oldNode = $self->find_element($xml, $name);
  my $newNode = $self->$createMethod($xml, $value);
  my $root = $xml->getDocumentElement();

  if ( $oldNode ) {
    $oldNode->removeChildNodes();
    $root->removeChild($oldNode);
  }

  $root->addChild($newNode);

  return $newNode;
}

sub find_element {
  my ($self, $xml, $name) = @_;
  if (!exists $NAME2ELEMENTS{$name}) {
    croak qq/ Can not search for element $name /;
  }
  my $element = $NAME2ELEMENTS{$name};

  my $xpc = XML::LibXML::XPathContext->new($xml->getDocumentElement());
  my $nodeList = $xpc->findnodes($element->{'find'});

  if ($nodeList->size() > 1) {
    croak qq/ Found more than one element for $name /;
  }

  return $nodeList->size() == 0 ? undef : $nodeList->pop();
}

sub create_udf_element {
  my ($self, $xml_el, $udf_name, $udf_value) = @_;

  my $url = 'http://genologics.com/ri/userdefined';
  my $docElem = $xml_el->getDocumentElement();
  $docElem->setNamespace($url, 'udf', 0);
  my $node = $xml_el->createElementNS($url, 'field');
  $node->setAttribute('name', $udf_name);
  $node->appendTextNode($udf_value);
  return $node;
}

sub update_text {
  my ($self, $node, $value) = @_;

  if ($node->hasChildNodes()) {
    $node->firstChild()->setData($value);
  } else {
    $node->appendTextNode($value);
  }
  return;
}

sub _create_volume {
  my ($self, $sampleXML, $volume) = @_;
  return $self->create_udf_element($sampleXML, "Volume (\N{U+00B5}L) (SM)", $volume);
}

sub _create_date_received {
  my ($self, $sampleXML, $today) = @_;
  my $node = $sampleXML->createElement('date-received');
  $node->appendTextNode($today);
  return $node;
}

sub _create_supplier_sample_name {
  my ($self, $sampleXML, $name) = @_;
  my $docElem = $sampleXML->getDocumentElement();
  $docElem->setNamespace('http://genologics.com/ri/userdefined', 'udf', 0);
  my $node = $sampleXML->createElementNS('http://genologics.com/ri/userdefined', 'field');
  $node->setAttribute('type', 'Text');
  $node->setAttribute('name', 'WTSI Supplier Sample Name (SM)');
  $node->appendTextNode($name);
  return $node;
}

sub _create_name {
  my ($self, $sampleXML, $name) = @_;
  my $node = $sampleXML->createElement('name');
  $node->appendTextNode($name);
  return $node;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_elements

=head1 SYNOPSIS

  with 'wtsi_clarity::util::clarity_elements';

  sub update_volume {
    my ($self, $volume, $xml) = @_;
    $self->set_element($xml, 'volume', $volume);
  }

=head1 DESCRIPTION

  Moose role for updating XML clarity elements.

=head1 SUBROUTINES/METHODS

=head2 
  set_element - takes some XML, an element name, and the new value. Will
  update the element in the XML with the new value.

=head2
  find_element - takes some XML and an element name. Will return the element name
  node, or undef if not found.

=head2 create_udf_element

=head2 update_text

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

=item XML::LibXML

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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
