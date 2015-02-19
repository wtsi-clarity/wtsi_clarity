package wtsi_clarity::mq::me::fluidigm_enhancer;

use Moose;
use wtsi_clarity::dao::flgen_plate_dao;

with 'wtsi_clarity::mq::message_enhancer';

our $VERSION = '0.0';

sub type {
  my $self = shift;
  return 'flgen_plate';
}

sub _build__lims_ids {
  my $self = shift;
  my @lims_ids = ();

  push @lims_ids, $self->process->plate_io_map->[0]->{'source_plate'};

  return \@lims_ids;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::fluidigm_enhancer

=head1 SYNOPSIS

  my $fluidigm_enhancer = wtsi_clarity::mq::me::fluidigm_enhancer->new();
  $fluidigm_enhancer->prepare_message();

=head1 DESCRIPTION
 A data object representing a fluidigm plate.
 Its data coming from the container and containertypes artifact (XML file).

=head1 SUBROUTINES/METHODS

=head2 type

  Returns the type of the model.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::dao::flgen_plate_dao

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
