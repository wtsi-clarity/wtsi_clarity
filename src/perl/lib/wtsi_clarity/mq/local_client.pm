package wtsi_clarity::mq::local_client;

use Moose;
use WTSI::DNAP::RabbitMQ::Client;
extends 'wtsi_clarity::mq::client';

our $VERSION = '0.0';

sub _build_message_bus_type { return q{clarity_mq} };

sub send_message {
  my ($self, $message, $routing_key) = @_;

  my @credentials = ( host  => $self->host,
                      port  => $self->port,
                      vhost => $self->vhost,
                      user  => $self->username,
                      pass  => $self->password,);

  ##no critic(Variables::ProhibitPunctuationVars)
  my $channel_name = 'client_channel'. $$;
  ## use critic

  my $client = WTSI::DNAP::RabbitMQ::Client->new(
    blocking_enabled => 1,
  );

  $client->connect(@credentials);

  $client->open_channel(name => $channel_name);

  $client->publish(
    channel     => $channel_name,
    exchange    => $self->exchange,
    routing_key => $routing_key,
    body        => $message,
    mandatory   => 1
  );

  $client->disconnect;

  return;
}

1;
__END__

=head1 NAME

wtsi_clarity::mq::local_client

=head1 SYNOPSIS

=head1 DESCRIPTION

 Rabbit message queue client for the local Clarity queue.

=head1 SUBROUTINES/METHODS

=head2 send_message

  $client->send_message("Some message", "purpose");

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::mq::client

=item WTSI::DNAP::RabbitMQ::Client

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
