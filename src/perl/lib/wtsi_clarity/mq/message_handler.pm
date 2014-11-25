package wtsi_clarity::mq::message_handler;

use Moose;
use wtsi_clarity::mq::message;

sub thaw {
  my ($self, $json_string) = @_;

  return wtsi_clarity::mq::message->thaw($json_string);
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::message_handler

=head1 SYNOPSIS

  my $message_handler = wtsi_clarity::mq::message_handler->new();
  $message_handler->handle_message($json_string);

=head1 DESCRIPTION

 Handles messages coming off RabbitMQ. Dispatches them to relevant message enhancer.

=head1 SUBROUTINES/METHODS

=head2 handle_message

  Takes in JSON string. Converts to mq::message, and dispatches to relevant message enhancer.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
