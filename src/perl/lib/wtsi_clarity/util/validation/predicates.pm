package wtsi_clarity::util::validation::predicates;

use strict;
use warnings;

use Exporter     qw/import/;

our $VERSION   = '0.0';
our @EXPORT_OK = qw/has_length_of is_integer has_no_whitespace is_digits_or_uppercase starts_with ends_with/;

sub has_length_of {
  my ($length) = @_;
  return sub {
    my $val = shift;
    return $length == length $val;
  }
}

sub is_integer {
  return _matches_regex('^\s*[+-]?\d+\s*$');
}

sub has_no_whitespace {
  return _doesnt_match_regex('\s');
}

sub is_digits_or_uppercase {
  return _matches_regex('^\s*[[:upper:]\d]+\s*$');
}

sub starts_with {
  my $string = shift;
  return _matches_regex('^\s*(' . $string . ')');
}

sub ends_with {
  my $string = shift;
  return _matches_regex('(' . $string . ')\s*$');
}

sub _matches_regex {
  my $regex = shift;
  return sub {
    return ($_[0] =~ /$regex/sxm);
  }
}

sub _doesnt_match_regex {
  my $regex = shift;
  return sub {
    return not ($_[0] =~ /$regex/sxm);
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::util::validation::predicates

=head1 SYNOPSIS

use wtsi_clarity::util::validation::predicates;

my $has_length_of_3 = has_length_of(3);
$has_length_of_3->('abc') == 1

=head1 DESCRIPTION

A module providing a subroutines for generating validation subroutines

=head1 SUBROUTINES/METHODS

=head2 has_length_of

=head2 is_integer

=head2 has_no_whitespace

=head2 is_digits_or_uppercase

=head2 starts_with

=head2 ends_with

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Exporter

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL by Chris Smith

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
