package wtsi_clarity::epp;

use Moose;
use Carp;
use XML::LibXML;

use wtsi_clarity::util::config;
use wtsi_clarity::util::request;

with 'MooseX::Getopt';

our $VERSION = '0.0';

has 'process_url'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'base_url'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);
sub _build_base_url {
  my $self = shift;
  my ($url) = $self->process_url =~ /(\S+\/)\w+\/\w+/smx;
  if (!$url) {
    croak q[Failed to get base url from ] . $self->process_url;
  }
  return $url;
}

has 'config'      => (
  isa             => 'wtsi_clarity::util::config',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);
sub _build_config {
  return wtsi_clarity::util::config->new();
}

has 'xml_parser'  => (
  isa             => 'XML::LibXML',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  default         => sub { return XML::LibXML->new(); },
);

has 'request' => (
  isa => 'wtsi_clarity::util::request',
  is  => 'ro',
  traits => [ 'NoGetopt' ],
  default => sub { return wtsi_clarity::util::request->new(); },
);

has 'process_doc'  => (
  isa             => 'XML::LibXML::Document',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);
sub _build_process_doc {
  my ($self) = @_;
  return $self->fetch_and_parse($self->process_url);
}

sub run {
  my $self = shift;
  $self->epp_log(sprintf 'run method of the %s class is called, process is %s',
                     ref $self,
                     $self->process_url);
  return;
}

sub fetch_and_parse {
  my ($self, $url) = @_;
  return $self->xml_parser->parse_string($self->request->get($url));
}

sub epp_log {
  my ($self, $message) = @_;
  warn "$message\n";
  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp

=head1 SYNOPSIS

  package wtsi_clarity::epp::child;
  use Moose;
  extends 'wtsi_clarity::epp';

  override 'run' => sub {
    my $self = shift;
    super(); #call parent's run method
    # the child's callback goes here
  };
  1;

=head1 DESCRIPTION

 Parent class for all Clarity callbacks

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 base_url - base url for api calls; if not given is derived from process url

=head2 run - executes the callback, should be implemented by child classes

=head2 epp_log - simple logging procedure

=head2 config

  A reference to wtsi_clarity::util::config object,
  access to configuration options for the package.

=head2 request

   A reference to wtsi_clarity::util::request object,
   which should be used to raise http requests

=head2 xml_parser - XML parser instance

=head2 process_doc - XML dom representation of process xml

=head2 fetch_and_parse - given url, fetches XML document and returns its XML dom representation

  my $dom = $self->fetch_and_parse($url);

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Getopt

=item Carp

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
