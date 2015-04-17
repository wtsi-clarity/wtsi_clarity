package wtsi_clarity::epp::isc::pooling::pooling_common;

use Moose::Role;
use Carp;
use Readonly;

our $VERSION = '0.0';

sub get_pool_name_by_plexing {
  my ($self, $destination_well_name, $plexing_strategy) = @_;

  return join q{ }, $plexing_strategy->get_pool_name($destination_well_name), qq{($destination_well_name)};
}

no Moose::Role;

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pooling::pooling_common

=head1 SYNOPSIS

=head1 DESCRIPTION

 Common methods for epp modules dealing with tag plates and indexing.

=head1 SUBROUTINES/METHODS

=head2 get_pool_name_by_plexing

  Returns the pooling range by the destination well and the plexing strategy.

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
