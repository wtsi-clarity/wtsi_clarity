package wtsi_clarity::util::well_mapper;

use Moose::Role;
use Readonly;
use Carp;

our $VERSION = '0.0';

Readonly::Scalar my $CHR_A => 64;

sub well_location_index {
  my ($self, $loc, $nb_rows, $nb_cols) = @_;

  if (!$loc) {
    croak 'Well address should be given';
  }

  $self->_asset_parameter_validation($nb_rows, $nb_cols);

  my ($letter, $number) = $loc =~ /\A(\w):(\d+)/xms;
  if (!$letter || !$number) {
    croak "Well location format '$loc' is not recornised";
  }

  if ($number > $nb_cols) {
    croak "Invalid column address '$number' for $nb_rows:$nb_cols layout";
  }

  ## no critic(CodeLayout::ProhibitParensWithBuiltins)
  my $letter_as_number = 1 + ord( uc ($letter) ) - ord('A');
  ## use critic

  if ($letter_as_number > $nb_rows) {
    croak "Invalid row address '$letter' for $nb_rows:$nb_cols layout";
  }

  return  ($number-1)*$nb_rows + $letter_as_number;
}

sub position_to_well {
  my ($self, $pos, $nb_rows, $nb_cols) = @_;

  if (!$pos) {
    croak 'Position should be given';
  }

  if ($pos < 1) {
    croak 'Position should be bigger than zero';
  }

  $self->_asset_parameter_validation($nb_rows, $nb_cols);

  my $number = int($pos / $nb_rows);
  my $letter_mod = $pos % $nb_rows;
  my $letter;

  if ($letter_mod > 0) {
    $number++;
    $letter = chr $CHR_A + $letter_mod;
  } else {
    $letter = 'H';
  }

  return $letter . q{:}. $number;
}

sub _asset_parameter_validation {
  my ($self, $nb_rows, $nb_cols) = @_;

  if (!$nb_rows) {
    croak 'Number of rows has to be given';
  }

  if (!$nb_cols) {
    croak 'Number of columns has to be given';
  }
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

=head2 position_to_well

  Converts a decimal position like '5' format into a well location with B:3 format (11 -> B:3)

  my $num_rows = 8;
  my $num_columns = 12;
  my $index = $self->position_to_well(11, $num_rows, $num_columns);
  # alternatively, can be used as a package-level method
  $index = wtsi_clarity::util::well_mapper->well_location_index(11, $num_rows, $num_columns);

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

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
