package wtsi_clarity::util::clarity_query;

use Moose::Role;
use Carp;
use Mojo::Collection 'c';
use URI::Escape;
use XML::LibXML;

our $VERSION = '0.0';

has '_xml_parser'  => (
  isa             => 'XML::LibXML',
  is              => 'ro',
  required        => 0,
  default         => sub { return XML::LibXML->new(); },
);

sub query_artifacts {
  my ($self, $criteria) = @_;

  my $uri = $self->_build_query_url( q{artifacts}, _build_query(q{artifacts}, $criteria) );
  my $response = $self->_xml_parser->parse_string($self->get($uri));

  return $response;
}

sub query_processes {
  my ($self, $criteria) = @_;

  my $uri = $self->_build_query_url( q{processes}, _build_query(q{processes}, $criteria) );
  my $response = $self->_xml_parser->parse_string($self->get($uri));

  return $response;
}

sub _build_query_url
{
  my ($self, $resource, $query) = @_;
  return  $self->config->clarity_api->{'base_uri'} . qq{/$resource?} . uri_escape ($query);
}

sub _build_query
{
  my ($resource, $criteria) = @_;

  my $map_key = {
    sample_id   => 'samplelimsid',
    artifact_id => 'inputartifactlimsid',
    step        => 'process-type',
    type        => 'type',
    udf         => 'udf',
  };
  my $query = q{};

  return c->new(sort keys %{$criteria})
  ->map(sub {

              my $raw_key = $_;
              my $key  = $map_key->{$raw_key};
              my $operator = q{=};
              if (!$key && $raw_key =~ m/(udf.*)([=]+)/ ) {
                $key = $1;
                $operator = $2;
              }
              my $crit = $criteria->{$_};
              # make an array of non array value...
              if(ref($crit) ne 'ARRAY'){
                $crit = [$crit];
              }
              return c->new(@{$crit})
                      ->map( sub {
                              return qq[$key$operator$_];
                            } )
                      ->join( q{&} );
            } )
  ->join( q{&} );
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
