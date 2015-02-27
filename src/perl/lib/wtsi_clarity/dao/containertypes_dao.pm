package wtsi_clarity::dao::containertypes_dao;

use Moose;
use Readonly;

with 'wtsi_clarity::dao::base_dao';

Readonly::Hash  my %ATTRIBUTES  => {
  'x_dimension_size' => '/ctp:container-type/x-dimension/size',
  'y_dimension_size' => '/ctp:container-type/y-dimension/size',
};

our $VERSION = '0.0';

has '+resource_type' => (
  default     => 'containertypes',
);

has '+attributes' => (
  default     => sub { return \%ATTRIBUTES; },
);

has 'plate_size' => (
  is => 'ro',
  isa => 'Int',
  lazy_build => 1,
);

sub _build_plate_size {
  my $self = shift;
  return $self->x_dimension_size * $self->y_dimension_size;
}

1;

__END__

=head1 NAME

wtsi_clarity::dao::containertypes_dao

=head1 SYNOPSIS
  my $containertypes_dao = wtsi_clarity::dao::containertypes_dao->new(lims_id => "1234");
  $containertypes_dao->to_message();

=head1 DESCRIPTION
 A data object representing a containertype.
 It's data coming from the containertype XML file returned from Clarity API.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item dao::base_dao

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL
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
