package wtsi_clarity::util::string;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = '0.0';

our @EXPORT_OK = qw/trim/;

=head2 trim

  Arg [1]    : string

  Example    : $trimmed = trim("  foo ");
  Description: Trim leading and trailing whitespace, withina  line, from a copy
               of the argument. Return the trimmed string.
  Returntype : Str

=cut
sub trim {
  my ($str) = @_;

  my $copy = $str;
  $copy =~ s/^\s*//;
  $copy =~ s/\s*$//;

  return $copy;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::string

=head1 SYNOPSIS

use wtsi_clarity::util::string qw/trim/;

my $trimmed_string = trim($str);

=head1 DESCRIPTION

Currently just one utility method for manipulting strings

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
