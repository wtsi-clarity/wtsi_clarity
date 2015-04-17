package wtsi_clarity::isc::pooling::mapper;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::request;
use wtsi_clarity::util::types;

with qw/MooseX::Getopt wtsi_clarity::util::configurable/;
with 'wtsi_clarity::util::well_mapper';

our $VERSION = '0.0';

Readonly::Scalar my $CONTAINER_NAME_PATH  => q{/con:container/name};
Readonly::Scalar my $CONTAINERS_URI_STR   => q{containers};
Readonly::Scalar my $TEMP_CONTAINER_NAME => q{temp_};

Readonly::Scalar my $NB_ROWS_96      => 8;
Readonly::Scalar my $NB_COLS_96      => 12;

has 'container_ids' => (
  is        => 'ro',
  isa       => 'ArrayRef[Str]',
  required  => 1,
);

has 'pooling_strategy' => (
  is        => 'rw',
  isa       => 'WtsiClarityPoolingStrategy',
  required  => 1,
);

has 'mapping' => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 0,
    lazy_build => 1,
);
sub _build_mapping {
  my $self = shift;

  my %plate_mapping = ();
  my $output_container_count = 1;
  foreach my $container_id (@{$self->container_ids}) {
    $plate_mapping{$container_id} = $self->_column_to_well_mapping($output_container_count);
    $output_container_count++;
  }

  return \%plate_mapping;
}

sub _column_to_well_mapping {
  my ($self, $output_container_count) = @_;
  my %mappings = ();

  foreach my $col (1..$NB_COLS_96) {
    foreach my $row ('A'...'H') {
      my %mapping = (
        'dest_plate'   => $TEMP_CONTAINER_NAME . $output_container_count,
        'dest_well'    => $self->position_to_well(
                            $self->pooling_strategy->dest_well_position($col), $NB_ROWS_96, $NB_COLS_96),
      );
      $mappings{$row. q{:}. $col} = \%mapping;
    }
  }

  return \%mappings;
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

