package wtsi_clarity::mq::mh::warehouse_message_handler_interface;

use Moose::Role;
use Carp;
use JSON;
use Encode;

use wtsi_clarity::mq::warehouse_client;

with 'wtsi_clarity::mq::mh::message_handler_interface';

our $VERSION = '0.0';

has 'json' => (
  isa     => 'JSON',
  is      => 'ro',
  default => sub {
    my $json = JSON->new->allow_nonref;
    return $json->canonical();
  },
);

sub process {
  my ($self, $message, $package) = @_;

  my $messages = $self->prepare_messages($message, $package);

  foreach my $message_to_wh (@{$messages}) {
    $self->_send_message(encode_utf8($self->json->encode($message_to_wh)), $message->purpose);
  }

  return 1;
}

sub _send_message {
  my ($self, $message, $purpose) = @_;
  print $purpose . ": " . $message . "\n" or carp "Can't write to the log file"; # So it goes into the log

  my $wh_client = wtsi_clarity::mq::warehouse_client->new(warehouse => $self->warehouse_type);
  $wh_client->send_message($message, $purpose);
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

wtsi_clarity::mq::mh::warehouse_message_handler_interface

=head1 SYNOPSIS

  package wtsi_clarity::mq::mh::report_message_handler;

  with 'wtsi_clarity::mq::mh::warehouse_message_handler_interface';

=head1 DESCRIPTION

 Handles messages coming off RabbitMQ. Dispatches them to relevant message enhancer.

=head1 SUBROUTINES/METHODS

=head2 process

  Takes in JSON string. Converts to mq::message, and dispatches to relevant message enhancer.

=head2 prepare_messages

  Receives the message from the local queue, finds the relevant enhancer, and then runs
  prepare_messages on that enhancer, returning the result

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::mq::message

=item wtsi_clarity::mq::mapper

=item wtsi_clarity::mq::client

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
