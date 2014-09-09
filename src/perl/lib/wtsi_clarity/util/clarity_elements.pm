package wtsi_clarity::util::clarity_elements;

use Moose::Role;
use Carp;
use Readonly;
use XML::LibXML;
use Try::Tiny;
use Mojo::Collection 'c';

our $VERSION = '0.0';

sub _set_clarity_element {
  my ($self, $xml, $name, $value, $override) = @_;
  return $self->_set_any_element($xml, $name, $value, $override, 0);
}

sub _set_udf_element {
  my ($self, $xml, $name, $value, $override) = @_;
  return $self->_set_any_element($xml, $name, $value, $override, 1);
}

## no critic(Subroutines::ProhibitManyArgs)
sub _set_any_element {
  my ($self, $xml, $name, $value, $override, $is_udf) = @_;
## use critic
  croak q/Missing argument: is_udf flag must be set/ if !defined $is_udf;
  # find if the element already exists...
  my $oldElement = $is_udf ?  $self->find_udf_element($xml, $name):
                              $self->find_clarity_element($xml, $name);

  if ( $oldElement ) {
    if ($override ) {
      # if node exists and should be overriden...
      return $self->_overwrite_element($oldElement, $value);
    } else {
      # if node exists but should be kept...
      return $oldElement;
    }
  }

  # node does not exists...
  my $newNode = $is_udf ? $self->create_udf_element    ($xml, $name, $value):
                          $self->create_clarity_element($xml, $name, $value);
  my $root = $xml->getDocumentElement();
  $root->addChild($newNode);

  return $newNode;
}

sub _overwrite_element {
  my ($self, $element, $value) = @_;

  if ($element->hasChildNodes()) {
    my $firstchild = $element->firstChild();
    if (!$firstchild->isa('XML::LibXML::Text')) {
      croak q(It seems that a udf element has children elements which are not text!);
    }
    $firstchild->setData($value);
    return $element;
  }
  $element->appendText($value);
  return $element;
}

sub set_udf_element_if_absent {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_udf_element($xml, $name, $value);
}

sub add_udf_element {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_udf_element($xml, $name, $value, 1);
}

sub update_udf_element {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_udf_element($xml, $name, $value, 1);
}

sub set_clarity_element_if_absent {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_clarity_element($xml, $name, $value);
}

sub add_clarity_element {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_clarity_element($xml, $name, $value, 1);
}

sub update_clarity_element {
  my ($self, $xml, $name, $value) = @_;
  return $self->_set_clarity_element($xml, $name, $value, 1);
}

sub find_udf_element {
  my ($self, $xml, $name) = @_;

  my $xpc = XML::LibXML::XPathContext->new($xml->getDocumentElement());
  my $xpath = "udf:field[\@name='$name']";
  my $nodeList = $xpc->findnodes($xpath);

  if ($nodeList->size() > 1) {
    croak qq/ Found more than one element for $name /;
  }

  return $nodeList->size() == 0 ? undef : $nodeList->pop();
}

sub find_clarity_element {
  my ($self, $xml, $name) = @_;

  my $xpc = XML::LibXML::XPathContext->new($xml->getDocumentElement());
  my $xpath = "$name";
  my $nodeList = $xpc->findnodes($xpath);

  if ($nodeList->size() > 1) {
    croak qq/ Found more than one element for $name /;
  }

  return $nodeList->size() == 0 ? undef : $nodeList->pop();
}

sub find_elements {
  my ($self, $xml, $name) = @_;
  my $xpc = XML::LibXML::XPathContext->new($xml->getDocumentElement());
  return $xpc->findnodes($name);
}


sub create_udf_element {
  my ($self, $xml_el, $udf_name, $udf_value) = @_;
  my $url = 'http://genologics.com/ri/userdefined';
  my $docElem = $xml_el->getDocumentElement();
  $docElem->setNamespace($url, 'udf', 0);
  my $node = $xml_el->createElementNS($url, 'field');
  $node->setAttribute('name', $udf_name);
  if (defined $udf_value) {
    $node->appendTextNode($udf_value);
  }
  return $node;
}

sub create_clarity_element {
  my ($self, $xml_el, $udf_name, $udf_value) = @_;
  my $node = $xml_el->createElement($udf_name);
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

sub trim_value {
  my ($self,$v) = @_;
  if ($v) {
    $v =~ s/^\s+|\s+$//smxg;
  }
  return $v;
}

sub grab_values {
  my ($self, $xml_doc, $xpath) = @_;

  my @nodes;
  try {
    @nodes = $xml_doc->findnodes($xpath)->get_nodelist();
  } catch {
    @nodes = ();
  };

  my @ids = c ->new(@nodes)
              ->map( sub { $_->getValue(); } )
              ->each();
  return \@ids;
}

sub find_elements_first_value {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'other', 0,  $default)
}

sub find_elements_first_textContent {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'other', 1,  $default)
}

sub find_udf_element_value {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'udf', 0,  $default)
}

sub find_udf_element_textContent {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'udf', 1,  $default)
}

sub find_clarity_element_value {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'clarity', 0,  $default)
}

sub find_clarity_element_textContent {
  my ($self, $doc, $xpath, $default) = @_;
  return $self->_find_elements_first_result($doc, $xpath, 'clarity', 1,  $default)
}

sub _find_elements_first_result {
  my ($self, $doc, $xpath, $type, $isText, $default) = @_;
  my $element;

  if ($type eq 'udf')
  {
    $element = $self->find_udf_element($doc, $xpath);
  }
  elsif ($type eq 'clarity')
  {
    $element = $self->find_clarity_element($doc, $xpath);
  }
  else
  {
    my @elements = $self->find_elements($doc, $xpath);

    if (@elements) {
      $element = $elements[0];
    } else {
      return $default if (defined $default) ;
      croak qq{Empty result when applying xpath with find_elements: '$xpath'.} ;
    }
  }

  if (!$element) {
    return $default if (defined $default) ;
    croak qq{Empty result when applying xpath : '$xpath'.} ;
  }

  if ($isText) {
    return $element->textContent;
  } else {
    return $element->getValue();
  }
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
  set_udf_element_if_absent - takes some XML, an element name, and the new value. Will
  add a UDF element in the XML with the new value, in the UDF namespace, and with an
  attribute name but will NOT change the value of an existing node.

=head2
  add_udf_element - takes some XML, an element name for the name attribute, and the
  new value. Will update the element in the XML with the new value if present.

=head2
  update_udf_element - alias for add_udf_element.

=head2
  set_clarity_element_if_absent - takes some XML, an element name, and the new value. Will
  add the element in the XML with the new value but will NOT change the value of
  an existing node.

=head2
  add_clarity_element - takes some XML, an element name, and the new value. Will
  update the element in the XML with the new value if present.

=head2
  update_clarity_element - alias for add_clarity_element.

=head2
  find_udf_element - takes some XML and an element name. Will return the UDF element
  node, or undef if not found.

=head2
  find_clarity_element - takes some XML and an element name. Will return the element
  node, or undef if not found.

=head2
  find_elements - takes some XML and an element name. Will return all the elements (nodes) found.

=head2
  grab_values - return a list of values extracted using an xpath

=head2 create_udf_element
  creates a new UDF element, append it to the xml at the given position, and returns it

=head2 create_clarity_element
  creates a new element, append it to the xml at the given position, and returns it


=head2
 find_elements_first_value - takes some XML, a xpath and an optional default value if not found.
 Will return the *value* of the first element found.
 if no element can be found, it will croak, except if a default value as been provided.

=head2
 find_elements_first_textContent - takes some XML, a xpath and an optional default value if not found.
 Will return the *textContent* of the first element found.
 if no element can be found, it will croak, except if a default value as been provided.

=head2
find_udf_element_value - takes some XML, an element name and an optional default value if not found.
 Will return the *value* of the UDF element found.
 if no element can be found, it will croak, except if a default value as been provided.

=head2
 find_udf_element_textContent - takes some XML, an element name and an optional default value if not found.
 Will return the *textContent* of the UDF element found.
 if no element can be found, it will croak, except if a default value as been provided.

=head2
 find_clarity_element_value - takes some XML, an element name and an optional default value if not found.
 Will return the *value* of the clarity element found.
 if no element can be found, it will croak, except if a default value as been provided.

=head2
 find_clarity_element_textContent - takes some XML, an element name and an optional default value if not found.
 Will return the *textContent* of the clarity element found.
 if no element can be found, it will croak, except if a default value as been provided.



=head2 update_text

=head2 trim_value - trims white space on both ends of the string

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
