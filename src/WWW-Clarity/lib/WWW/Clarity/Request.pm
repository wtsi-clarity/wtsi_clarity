package WWW::Clarity::Request;

use Moose;
use WWW::Mechanize;
use XML::LibXML;

has 'username' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
  );

has 'password' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
  );

has 'mech' => (
    isa        => 'WWW::Mechanize',
    is         => 'ro',
    lazy_build => 1,
  );
sub _build_mech {
  my ($self) = @_;

  my $mech = WWW::Mechanize->new();
  $mech->credentials($self->username, $self->password);
  $mech->add_header('Content-Type' => 'application/xml');
  return $mech;
}

sub get_xml {
  my ($self, $url) = @_;

  $self->mech->get($url);

  my $xml = XML::LibXML->load_xml(
    string => $self->mech->content,
  );

  return $xml->documentElement;
}

sub batch_get_xml {
  my ($self, $uris) = @_;

  my ($base, $type) = @{$uris}[0] =~ qr/(.*)\/([[:alpha:]]*)\/[\d-]*/msx;

  my $xml = '<ri:links xmlns:ri="http://genologics.com/ri">';
  for my $uri (@{$uris}) {
    $xml .= qq{<link uri="$uri" rel="$type"/>};
  }
  $xml .= '</ri:links>';

  $self->mech->post("$base/$type/batch/retrieve", Content => $xml);

  my $response_xml = XML::LibXML->load_xml(
    string => $self->mech->content,
  );

  return $response_xml->documentElement;
}

sub put_xml {
  my ($self, $url, $xml) = @_;

  return $self->mech->put($url, content => $xml->toString);
}

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::Clarity;

    my $foo = WWW::Clarity->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 get_xml

 Given a url returns the XML::LibXML object.

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