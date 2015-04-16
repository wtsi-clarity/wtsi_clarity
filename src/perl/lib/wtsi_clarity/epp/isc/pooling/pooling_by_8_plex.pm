package wtsi_clarity::epp::isc::pooling::pooling_by_8_plex;

use Moose;
use Carp;
use Readonly;

our $VERSION = '0.0';

with 'wtsi_clarity::epp::isc::pooling::pooling_strategy';

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
  'D:2' => 'A12:H12',
  'E:2' => 'A1:H1',
  'F:2' => 'A2:H2',
  'G:2' => 'A3:H3',
  'H:2' => 'A4:H4',
  'A:3' => 'A5:H5',
  'B:3' => 'A6:H6',
  'C:3' => 'A7:H7',
  'D:3' => 'A8:H8',
  'E:3' => 'A9:H9',
  'F:3' => 'A10:H10',
  'G:3' => 'A11:H11',
  'H:3' => 'A12:H12',
  'A:4' => 'A1:H1',
  'B:4' => 'A2:H2',
  'C:4' => 'A3:H3',
  'D:4' => 'A4:H4',
  'E:4' => 'A5:H5',
  'F:4' => 'A6:H6',
  'G:4' => 'A7:H7',
  'H:4' => 'A8:H8',
  'A:5' => 'A9:H9',
  'B:5' => 'A10:H10',
  'C:5' => 'A11:H11',
  'D:5' => 'A12:H12',
  'E:5' => 'A1:H1',
  'F:5' => 'A2:H2',
  'G:5' => 'A3:H3',
  'H:5' => 'A4:H4',
  'A:6' => 'A5:H5',
  'B:6' => 'A6:H6',
  'C:6' => 'A7:H7',
  'D:6' => 'A8:H8',
  'E:6' => 'A9:H9',
  'F:6' => 'A10:H10',
  'G:6' => 'A11:H11',
  'H:6' => 'A12:H12'
};

has '+pool_names_by_target_well' => (
  default => sub { return \%POOL_NAMES_BY_TARGET_WELL; }
);

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pooling::pooling_by_8_plex

=head1 SYNOPSIS

=head1 DESCRIPTION

 Pooling startegy for 8 plex pooling.

=head1 SUBROUTINES/METHODS

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
