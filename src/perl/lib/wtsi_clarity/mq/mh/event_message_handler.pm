package wtsi_clarity::mq::mh::event_message_handler;

use Moose;
use Carp;
use JSON;
use Encode;

with 'wtsi_clarity::mq::mh::warehouse_message_handler_interface';

our $VERSION = '0.0';

has 'warehouse_type' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{event},
);

# @Override
sub prepare_messages {
  my ($self, $message, $package) = @_;

  return $package->new(
            process_url => $message->process_url,
            step_url    => $message->step_url,
            timestamp   => $message->timestamp,
            event_type  => $message->purpose,
          )->prepare_messages();
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::mh::event_message_handler

=head1 SYNOPSIS

  my $message_handler = wtsi_clarity::mq::mh::event_message_handler->new();
  $message_handler->process($json_string);

=head1 DESCRIPTION

 Handles messages coming off RabbitMQ. Dispatches them to relevant report builder.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  Overrides from warehouse_message_handler_interface.
  We need the message purpose as a parameter to set the event type of the message.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item Carp

=item wtsi_clarity::mq::message_handler_interface

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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
