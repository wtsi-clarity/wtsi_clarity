package wtsi_clarity::util::clarity_query;

use Moose::Role;
use Carp;
use Mojo::Collection 'c';


our $VERSION = '0.0';

sub query_artifacts {
  my ($self, $criteria) = @_;

  my $uri = $self->_build_query_url( _build_query($criteria) );
  my $response = $self->get($uri);

  return $response;
}

sub _build_query_url
{
  my ($self, $query) = @_;
  return uri_escape ( $self->config->clarity_api->{'base_uri'} . "/artifacts?$query" );
}

sub _build_query
{
  my ($criteria) = @_;
  # print ">>",Dumper $criteria;

  my $map_key = {
    sample_id => 'samplelimsid',
    step => 'process-type',
    type => 'type',
  };
  my $query = q{};

  return c->new(sort keys %{$criteria})
  ->map(sub{ $map_key->{$_} . '=' . $criteria->{$_} })
  ->join("&");
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_query

=head1 SYNOPSIS

  with 'wtsi_clarity::util::clarity_query';
  my $response = $self->request->clarity_query->query_artifacts( {sample_id => 'ABC12345' } );

=head1 DESCRIPTION

  Offers a role allowing to forge and execute search queries on artifacts.

=head1 SUBROUTINES/METHODS

=head2 query_artifacts
  Takes a series of criteria (as a hash to find artifacts.

  criteria hash example :
  {
    sample_id => 'ABC12345',
    step => 'PicoGreen',
    type => 'Analyte',
  }

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Mojo::Collection

=item URI::Escape

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
