package WWW::Clarity::Models::Researcher;

use Moose;

extends 'WWW::Clarity::Models::Model';

has '_attributes' => (
    is      => 'ro',
    default => sub {
      return {
        first_name => {
          xpath => 'first-name',
          isa   => 'text',
        },
        last_name  => {
          xpath => 'last-name',
          isa   => 'text',
        },
        email      => {
          xpath => 'email',
          isa   => 'text',
        },
        user_name  => {
          xpath => 'credentials/username',
          isa   => 'text',
        },
      }
    }
  );

sub get_full_name {
  my ($self) = @_;

  return $self->get_first_name.' '.$self->get_last_name;
}

=head1 SYNOPSIS



=head1 LICENSE AND COPYRIGHT

Copyright 2016 Sanger Insitute.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut

1;