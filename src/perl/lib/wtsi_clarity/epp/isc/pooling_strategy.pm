package wtsi_clarity::epp::isc::pooling_strategy;

use Moose::Role;
use Readonly;
use Carp;

our $VERSION = '0.0';

Readonly::Hash my %POOL_NAMES_BY_TARGET_WELL => {};

has 'pool_names_by_target_well' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
);

sub get_pool_name {
  my ($self, $destination_well_name) = @_;

  my $pool_name = $self->pool_names_by_target_well->{$destination_well_name};

  croak qq{Pool name ($destination_well_name) is not defined for this destination well} if (! defined $pool_name);

  return $pool_name;
}

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pooling_strategy

=head1 SYNOPSIS

=head1 DESCRIPTION

 Interface for pooling strategies.

=head1 SUBROUTINES/METHODS

=head2 get_pool_name

  Returns the pooling range by the destination well.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

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
