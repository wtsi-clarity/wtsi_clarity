package wtsi_clarity::epp::isc::pooling::pooling_by_16_plex;

use Moose;
use Readonly;

our $VERSION = '0.0';

with 'wtsi_clarity::epp::isc::pooling::pooling_strategy';

Readonly::Hash my %POOL_NAMES_BY_TARGET_WELL => {
  'A:1' => 'A1:H2',
  'B:1' => 'A3:H4',
  'C:1' => 'A5:H6',
  'D:1' => 'A7:H8',
  'E:1' => 'A9:H10',
  'F:1' => 'A11:H12',
  'G:1' => 'A1:H2',
  'H:1' => 'A3:H4',
  'A:2' => 'A5:H6',
  'B:2' => 'A7:H8',
  'C:2' => 'A9:H10',
  'D:2' => 'A11:H12',
  'E:2' => 'A1:H2',
  'F:2' => 'A3:H4',
  'G:2' => 'A5:H6',
  'H:2' => 'A7:H8',
  'A:3' => 'A9:H10',
  'B:3' => 'A11:H12',
  'C:3' => 'A1:H2',
  'D:3' => 'A3:H4',
  'E:3' => 'A5:H6',
  'F:3' => 'A7:H8',
  'G:3' => 'A9:H10',
  'H:3' => 'A11:H12'
};

has '+pool_names_by_target_well' => (
  default => sub { return \%POOL_NAMES_BY_TARGET_WELL; }
);

sub dest_well_position {
  my ($self, $well_position, $nb_cols, $container_count) = @_;

  return int(($well_position + 1)/2) + $nb_cols * ($container_count - 1) / 2;
}

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pooling::pooling_by_16_plex

=head1 SYNOPSIS

=head1 DESCRIPTION

 Pooling startegy for 16 plex pooling.

=head1 SUBROUTINES/METHODS

=head2 dest_well_position

  Returns the position of the destination well.

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
