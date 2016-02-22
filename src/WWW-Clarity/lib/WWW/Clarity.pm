package WWW::Clarity;

use 5.006;
use Moose;

use WWW::Clarity::Request;
use WWW::Clarity::Models::Process;
use WWW::Clarity::Models::Researcher;
use WWW::Clarity::Models::Artifact;
use WWW::Clarity::Models::Sample;

our $VERSION = '0.01';

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

has 'request' => (
    isa        => 'WWW::Clarity::Request',
    is         => 'ro',
    lazy_build => 1,
  );
sub _build_request {
  my ($self) = @_;

  return WWW::Clarity::Request->new(
    username => $self->username,
    password => $self->password,
  );
}

sub get_process {
  my ($self, $uri) = @_;

  my $xml = $self->request->get_xml($uri);

  return WWW::Clarity::Models::Process->new(
    xml     => $xml,
    clarity => $self,
  );
}

sub get_researcher {
  my ($self, $uri) = @_;

  my $xml = $self->request->get_xml($uri);

  return WWW::Clarity::Models::Researcher->new(
    xml     => $xml,
    clarity => $self,
  );
}

sub get_artifact {
  my ($self, $uri) = @_;

  my $xml = $self->request->get_xml($uri);

  return WWW::Clarity::Models::Artifact->new(
    xml     => $xml,
    clarity => $self,
  );
}

sub get_artifacts {
  my ($self, $uris) = @_;

  my $xmls = $self->request->batch_get_xml($uris);

  my @artifacts;
  for my $node ($xmls->findnodes('art:artifact')) {
    push @artifacts, WWW::Clarity::Models::Artifact->new(
        xml     => $node,
        clarity => $self,
      )
  }
  return \@artifacts;
}

sub get_samples {
  my ($self, $uris) = @_;

  my $xmls = $self->request->batch_get_xml($uris);

  my @samples;
  for my $node ($xmls->findnodes('smp:sample')) {
    push @samples, WWW::Clarity::Models::Sample->new(
        xml     => $node,
        clarity => $self,
      )
  }
  return \@samples;
}

1;

=head1 NAME

WWW::Clarity - The great new WWW::Clarity!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WWW::Clarity;

    my $foo = WWW::Clarity->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 get_process

 Given a url returns the WWW::Clarity::Models::Process object.

=head2 get_researcher

 Given a url returns the WWW::Clarity::Models::Researcher object.

=head1 AUTHOR

Ronan Forman, C<< <rf9 at sanger.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-clarity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Clarity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Clarity


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Clarity>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Clarity>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Clarity>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Clarity/>

=back


=head1 ACKNOWLEDGEMENTS


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