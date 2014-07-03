package wtsi_clarity::util::well_mapper;

sub get_location_in_decimal {
  my ($loc) = @_;
  my ($letter, $number) = $loc =~ /(\w):(\d+)/xms;
  my $letter_as_number = 1 + ord( uc($letter) ) - ord('A');
  my $res = ($number-1)*8 + $letter_as_number;

  return $res;
}


1;

__END__

=head1 NAME

wtsi_clarity::util::well_mapper

=head1 SYNOPSIS

 Utility methods to help converting well denominations

=head1 SUBROUTINES/METHODS

=head2 get_location_in_decimal

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
