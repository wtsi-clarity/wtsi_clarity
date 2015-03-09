package wtsi_clarity::epp::isc::pooling_common;

use Moose::Role;
use Carp;
use Readonly;

our $VERSION = '0.0';

Readonly::Hash my %POOL_NAMES_BY_TARGET_WELL => {
  'A:1' => 'A1:H1',
  'B:1' => 'A2:H2',
  'C:1' => 'A3:H3',
  'D:1' => 'A4:H4',
  'E:1' => 'A5:H5',
  'F:1' => 'A6:H6',
  'G:1' => 'A7:H7',
  'H:1' => 'A8:H8',
  'A:2' => 'A9:H9',
  'B:2' => 'A10:H10',
  'C:2' => 'A11:H11',
  'D:2' => 'A12:H12'
};

sub get_pool_name {
  my ($self, $destination_well_name) = @_;

  my $pool_name = $POOL_NAMES_BY_TARGET_WELL{$destination_well_name};

  croak qq{Pool name ($destination_well_name) is not defined for this destination well} if (! defined $pool_name);

  return $pool_name;
}

sub pool_location_by_pool_range {
  my ($self, $pool_range) = @_;

  my @pool_location = grep { $POOL_NAMES_BY_TARGET_WELL{$_} eq $pool_range } keys %POOL_NAMES_BY_TARGET_WELL;

  return $pool_location[0];
}


no Moose::Role;

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pooling_common

=head1 SYNOPSIS

=head1 DESCRIPTION

 Common methods for epp modules dealing with tag plates and indexing.

=head1 SUBROUTINES/METHODS

=head2 get_pool_name

  Returns the pooling range by the destination well.

=head2 pool_location_by_pool_range

  Returns the pool's well location by the pooling range.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item Carp

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
