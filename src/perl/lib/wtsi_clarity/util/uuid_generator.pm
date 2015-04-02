package wtsi_clarity::util::uuid_generator;

use strict;
use warnings;
use UUID::Tiny ':std';

use base 'Exporter';

our $VERSION = '0.0';

our @EXPORT_OK = qw/new_uuid/;

sub new_uuid {
  my ($self) = @_;

  return uuid_to_string(create_uuid(UUID_TIME));
}

1;

__END__

=head1 NAME

wtsi_clarity::util::uuid_generator

=head1 SYNOPSIS

use wtsi_clarity::util::uuid_generator qw/new_uuid/;

=head1 DESCRIPTION

Utility method for generating a new UUID.

=head1 SUBROUTINES/METHODS

=head2 new_uuid
  
  Generates and returns a new UUID.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

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
