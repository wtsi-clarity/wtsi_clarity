package wtsi_clarity::util::well_mapper;

use Moose::Role;
use wtsi_clarity::util::error_reporter qw/croak/;

our $VERSION = '0.0';

sub well_location_index {
  my ($self, $loc, $nb_rows, $nb_cols) = @_;

  if (!$loc) {
    croak( 'Well address should be given');
  }

  if (!$nb_rows) {
    croak( 'Number of rows has to be given');
  }

  if (!$nb_cols) {
    croak( 'Number of columns has to be given');
  }

  my ($letter, $number) = $loc =~ /\A(\w):(\d+)/xms;
  if (!$letter || !$number) {
    croak( "Well location format '$loc' is not recornised");
  }

  if ($number > $nb_cols) {
    croak( "Invalid column address '$number' for $nb_rows:$nb_cols layout");
  }

  ## no critic(CodeLayout::ProhibitParensWithBuiltins)
  my $letter_as_number = 1 + ord( uc ($letter) ) - ord('A');
  ## use critic

  if ($letter_as_number > $nb_rows) {
    croak( "Invalid row address '$letter' for $nb_rows:$nb_cols layout");
  }

  return  ($number-1)*$nb_rows + $letter_as_number;
}

no Moose::Role;

1;

__END__

=head1 NAME

  wtsi_clarity::util::well_mapper

=head1 SYNOPSIS

  with 'wtsi_clarity::util::well_mapper';

=head1 DESCRIPTION

  Utility to help converting well location notations

=head1 SUBROUTINES/METHODS

=head2 well_location_index

  Converts a location with B:3 format into a location in decimal (B:3 -> 11)

  my $num_rows = 8;
  my $num_columns = 12;
  my $index = $self->well_location_index('B:3', $num_rows, $num_columns);
  # alternatively, can be used as a package-level method
  $index = wtsi_clarity::util::well_mapper->well_location_index('B:3', $num_rows, $num_columns);
  
=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item wtsi_clarity::util::error_reporter

=back

=head1 AUTHOR

Chris Smith E<lt>mcs24@sanger.ac.ukE<gt>

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
