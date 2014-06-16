package util::xml;
use XML::LibXML;

sub find_elements {
  my ($xml, $name) = @_;
  my $parser = XML::LibXML->new;
  my $doc = $parser->parse_string($xml);
  my $xpc = XML::LibXML::XPathContext->new($doc->getDocumentElement());
  return $xpc->findnodes($name);
}

return 1;


__END__

=head1 NAME

wtsi_clarity::t::util::xml

=head1 SYNOPSIS

  use lib qw ( t );
  use util::xml;

  ...

  my @elements = util::xml::find_elements($xml, $path);

=head1 DESCRIPTION

  Contains XML helpers function for the tests.

=head1 SUBROUTINES/METHODS

=head2
  find_elements - takes some XML, an element name.
  Returns an array of element matching the XPath.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item XML::LibXML

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Benoit Mangili

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
