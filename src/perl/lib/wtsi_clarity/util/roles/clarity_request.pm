package wtsi_clarity::util::roles::clarity_request;

use Moose::Role;
use XML::LibXML;
use wtsi_clarity::util::request;

our $VERSION = '0.0';

# we use this role in our epp script too, which is used as an external script,
# so, that's why we need to use the MooseX::Getopt role in this role
with qw/MooseX::Getopt/;

has 'request' => (
  isa => 'wtsi_clarity::util::request',
  is  => 'ro',
  traits => [ 'NoGetopt' ],
  default => sub { return wtsi_clarity::util::request->new(); },
);

has 'xml_parser'  => (
  isa             => 'XML::LibXML',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  default         => sub { return XML::LibXML->new(); },
);

sub fetch_and_parse {
  my ($self, $url) = @_;
  return $self->xml_parser->parse_string($self->request->get($url));
}

1;

__END__

=head1 NAME

wtsi_clarity::util::roles::clarity_request

=head1 SYNOPSIS

  with 'wtsi_clarity::util::roles::clarity_request';
  $self->fetch_and_parse('http://test.com/test/234');

=head1 DESCRIPTION

  Role that related to a HTTP request.

=head1 SUBROUTINES/METHODS

=head2 fetch_and_parse - given url, fetches XML document and returns its XML dom representation

  my $dom = $self->fetch_and_parse($url);

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item wtsi_clarity::util::request

=item XML::LibXML

=item MooseX::Getopt

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL
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
