package wtsi_clarity::mq::mh::event_message_handler;

use Moose;
use Carp;
use JSON;
use Encode;

use wtsi_clarity::mq::warehouse_client;

with 'wtsi_clarity::mq::message_handler_interface';

our $VERSION = '0.0';

has '_wh_client' => (
  isa         => 'wtsi_clarity::mq::warehouse_client',
  is          => 'ro',
  required    => 0,
  default     => sub {
    return wtsi_clarity::mq::warehouse_client->new(warehouse => 'event');
  },
);

#TODO DRY it
sub process {
  my ($self, $message, $package) = @_;

  my $messages = $self->prepare_messages($message, $package);

  foreach my $message_to_wh (@{$messages}) {
    $self->_send_message(encode_utf8(to_json($message_to_wh)), $message->purpose);
  }

  return 1;
}

sub _send_message {
  my ($self, $message, $purpose) = @_;
  print $purpose . ": " . $message . "\n" or carp "Can't write to the log file"; # So it goes into the log
  $self->_wh_client->send_message($message, $purpose);
  return;
}

sub prepare_messages {
  my ($self, $message, $package) = @_;

  return $package->new(
            process_url => $message->process_url,
            step_url    => $message->step_url,
            timestamp   => $message->timestamp,
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

=head2 process

  Takes in JSON string. Converts to mq::message, and dispatches to relevant message enhancer.

=head2 prepare_messages

  Receives the message from the local queue, finds the relevant enhancer, and then runs
  prepare_messages on that enhancer, returning the result.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
