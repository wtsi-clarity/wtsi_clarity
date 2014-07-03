package wtsi_clarity::util::well_mapper;

use strict;
use warnings;
use Carp;
use Readonly;

our $VERSION = '0.0';


Readonly::Scalar my $NB_COLS => 12 ;
Readonly::Scalar my $NB_ROWS => 8  ;

sub get_location_in_decimal {
  my ($loc) = @_;

  return _get_location_in_decimal($loc, $NB_ROWS, $NB_COLS);
}

sub _get_location_in_decimal {
  my ($loc, $nb_rows, $nb_cols) = @_;
  my ($letter, $number) = $loc =~ /(\w):(\d+)/xms;

  ## no critic(CodeLayout::ProhibitParensWithBuiltins)
  my $letter_as_number = 1 + ord( uc ($letter) ) - ord('A');
  ## use critic

  my $res = ($number-1)*$nb_rows + $letter_as_number;

  return $res;
}


1;

__END__

=head1 NAME

wtsi_clarity::util::well_mapper

=head1 SYNOPSIS

  with 'wtsi_clarity::util::well_mapper';

=head1 DESCRIPTION

 Utility methods to help converting well denominations

=head1 SUBROUTINES/METHODS

=head2 get_location_in_decimal
    converts a location with B:3 format into a location in decimal (B:3 -> 11)

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=back

=head1 AUTHOR

Carol Scott E<lt>ces@sanger.ac.ukE<gt>

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
