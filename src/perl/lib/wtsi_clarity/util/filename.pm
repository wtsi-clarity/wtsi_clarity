package wtsi_clarity::util::filename;

use Moose::Role;
use Carp;

our $VERSION = '0.0';

sub with_uppercase_extension {
  my ($self, $filename) = @_;

  my $extension_pos = rindex $filename, q/./;
  my $extension = substr $filename, $extension_pos + 1;

  $filename =~ s/($extension)/uc($1)/egsxm;

  return $filename;
}

no Moose::Role;

1;

__END__

=head1 NAME

  wtsi_clarity::util::filename

=head1 SYNOPSIS

  with 'wtsi_clarity::util::filename';

=head1 DESCRIPTION

  Utility to handle operations with a file.

=head1 SUBROUTINES/METHODS

=head2 with_uppercase_extension

  Converts a file extension to uppercase.
  
=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

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
