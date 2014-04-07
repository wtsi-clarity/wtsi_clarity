#############
# Created By: Kate Taylor
# Created On: 07 April2014

package test;

use strict;
use warnings;
use Carp;

our $VERSION = '0';

sub print_message {
    return qq{'Clarity LIMS perl test message\n};
}

sub main {
  print_message;
  return;
}
1;
__END__

=head1 NAME

test

=head1 VERSION

=head1 SYNOPSIS

A test module to exercise the Jenkins integration server

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 main

main routine 

=cut

=head2 print_message

Prints a message.

=cut 

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Carp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: kt6 $

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Kate Taylor

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
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
