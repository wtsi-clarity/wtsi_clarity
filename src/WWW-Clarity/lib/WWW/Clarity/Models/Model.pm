package WWW::Clarity::Models::Model;

use Moose;

has 'xml' => (
    isa      => 'XML::LibXML::Element',
    is       => 'rw',
    required => 1,
    writer   => '_set_xml',
  );

has 'clarity' => (
    isa      => 'WWW::Clarity',
    is       => 'ro',
    required => 1,
  );

sub BUILD {
  my ($class) = @_;
  my $meta = __PACKAGE__->meta;

  for my $name (keys %{$class->_attributes}) {
    my $attr = $class->_attributes->{$name};
    my $type = $attr->{'is'} || 'rw';
    my $isa = $attr->{'isa'} || 'text';

    # Getter
    if ($type =~ m/r/) {
      $meta->add_method("get_$name" => sub {
          my ($self) = @_;

          my $output;
          if ($isa eq 'text' || $isa eq 'attr') {
            $output = $self->xml->findvalue($attr->{'xpath'});
          } elsif ($isa eq 'attrList') {
            my @values;
            my ($node_path, $attr_path) = $attr->{'xpath'} =~ qr/(.*)\/(\@\w+)/msx;

            for my $node ($self->xml->findnodes($node_path)) {
              push @values, $node->findvalue($attr_path);
            }
            $output = \@values;
          }

          if (exists $attr->{'getter'}) {
            $output = $attr->{'getter'}($class, $output);
          }

          if ($attr->{'cached'}) {
            $meta->add_method("get_$name" => sub {
                return $output;
              });
          }
          return $output;
        });
    }

    # Setter
    if ($type =~ m/w/) {
      $meta->add_method("set_$name" => sub {
          my ($self, $value) = @_;

          if (exists $attr->{'setter'}) {
            $value = $attr->{'setter'}($class, $value);
          }

          if ($isa eq 'text') {
            my @nodes = $self->xml->findnodes($attr->{'xpath'});
            for my $node (@nodes) {
              $node->removeChildNodes();
              $node->appendText($value);
            }
          } elsif ($isa eq 'attr') {
            croak {'Setting attributes not implemented yet.'}
          }

          return $self;
        });
    }
  }
}

sub get_uri {
  my ($self) = @_;

  return $self->xml->findvalue('@uri')
}

sub refresh {
  my ($self) = @_;

  $self->_set_xml($self->clarity->request->get_xml($self->get_uri));

  return $self;
}

sub save {
  my ($self) = @_;

  $self->clarity->request->put_xml($self->get_uri, $self->xml);

  return $self;
}

=head1 SYNOPSIS



=head1 SUBROUTINES/METHODS

=head2 get_uri

  Returns the uri for the object.

=head2 refresh

  Reloads the object from the api.

=head2 save

  Posts the xml to the api.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Sanger Insitute.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut

1;