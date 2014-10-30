package wtsi_clarity::isc::pooling::mapper;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::request;

with qw/MooseX::Getopt wtsi_clarity::util::configurable/;
with 'wtsi_clarity::util::well_mapper';

our $VERSION = '0.0';

Readonly::Scalar my $CONTAINER_NAME_PATH  => q{/con:container/name};
Readonly::Scalar my $CONTAINERS_URI_STR   => q{containers};
Readonly::Scalar my $TEMP_CONTAINER_NAME1 => q{temp_1};

Readonly::Scalar my $NB_ROWS_96      => 8;
Readonly::Scalar my $NB_COLS_96      => 12;

has 'container_id' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'mapping' => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 0,
    lazy_build => 1,
);
sub _build_mapping {
  my $self = shift;

  return $self->_column_to_well_mapping($self->_container_name);
}

sub _container_name {
  my $self = shift;

  my $request_uri = join q{/}, ($self->config->clarity_api->{'base_uri'}, $CONTAINERS_URI_STR, $self->container_id);
  my $request = wtsi_clarity::util::request->new();
  my $container_raw = $request->get($request_uri) or croak qq{Could not get the container. ($request_uri)};
  my $container_dom = XML::LibXML->load_xml(string => $container_raw );

  return $container_dom->findvalue($CONTAINER_NAME_PATH);
}

sub _column_to_well_mapping {
  my ($self, $container_name) = @_;
  my @mappings;

  foreach my $col (1..$NB_COLS_96) {
    foreach my $row ('A'...'H') {
      my %mapping = ( 'src_container_name'  => $container_name,
                      'src_well'            => $row. q{:}. $col,
                      'dest_container_name' => $TEMP_CONTAINER_NAME1,
                      'dest_well'           => $self->position_to_well($col, $NB_ROWS_96, $NB_COLS_96),
                    );
      push @mappings, \%mapping;
    }
  }

  return \@mappings;
}

1;

__END__

=head1 NAME

wtsi_clarity::isc::pooling::mapper

=head1 SYNOPSIS

  my $mapper = wtsi_clarity::isc::pooling::mapper->new(
    container_id   => '27-1',
  );

  $mapper->mapping();

=head1 DESCRIPTION

  This module is able to get the mapping for an input plate.
  It maps each of the wells of the source plate(s) to the wells of the target plate(s).

=head1 SUBROUTINES/METHODS

=head2 mapping - return an array representing the mapping for 
each of the wells of the source plate(s) to the wells of the target plate(s).

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::request

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

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

