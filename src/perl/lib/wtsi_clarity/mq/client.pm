package wtsi_clarity::mq::client;

use Moose;
use Readonly;
use wtsi_clarity::util::error_reporter qw/croak/;
#use AnyEvent;
use AnyEvent::RabbitMQ;

with 'wtsi_clarity::util::configurable';

our $VERSION = '0.0';

Readonly::Scalar my $PORT            => 5672;
Readonly::Scalar my $TIMEOUT         => 2;

has 'host'      => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build_host {
  my $self = shift;
  return $self->config->clarity_mq->{'host'} || 'localhost';
}

has 'port'      => (
  isa             => 'Int',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build_port {
  my $self = shift;
  return $self->_mq_config->{'port'} || $PORT;
}

foreach my $attr ( qw/password username vhost exchange routing_key/) {

  has $attr => (isa => 'Str', is => 'ro', required => 0, lazy_build => 1,);
    my $build_method = '_build_' . $attr;
    ##no critic (TestingAndDebugging::ProhibitNoStrict TestingAndDebugging::ProhibitNoWarnings)
    no strict 'refs';
    no warnings 'redefine';
    *{$build_method} = sub {
        my $self = shift;
        return $self->_mq_config->{$attr};
    };
}

has '_mq_config'      => (
  isa             => 'HashRef',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__mq_config {
  my $self = shift;
  return $self->config->clarity_mq;
}

sub send_message {
  my ($self, $message) = @_;

  my $cv = AnyEvent->condvar;
  # The $connection variable should be here to ensure correct object descruction.
  my $connection = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
    host       => $self->host,
    port       => $self->port,
    user       => $self->username,
    pass       => $self->password,
    vhost      => $self->vhost,
    timeout    => $TIMEOUT,
    tls        => 0, # Or 1 if you'd like SSL
    on_success =>
    sub {
      my $ar = shift;
      $ar->open_channel(
        on_success => sub {
          my $channel = shift;
          $channel->publish('body'=>$message, 'exchange'=>$self->exchange, 'routing_key'=>$self->routing_key,);
          $cv->send("Message '$message' sent");
        },
        on_failure => $cv,
        on_close   => sub {
          my $method_frame = shift->method_frame;
          croak( $method_frame->reply_code, $method_frame->reply_text );
        }
      );
    },
    on_failure => $cv,
    on_read_failure => sub { croak @_ },
    on_close   => sub {
      my $why = shift;
      if (ref $why) {
        my $method_frame = $why->method_frame;
        croak( $method_frame->reply_code, q[: ], $method_frame->reply_text );
      } else {
        croak( $why );
      }
    },
  );
  warn $cv->recv, "\n";
  return;
}

1;
__END__

=head1 NAME

wtsi_clarity::mq::client

=head1 SYNOPSIS

=head1 DESCRIPTION

 Rabbit message queue client.

=head1 SUBROUTINES/METHODS

=head2 send_message

  $client->send_message("Some message");

=head2 host

  If not given, is read from the configuration file. Failing that, the host where
  the client is executed is used.

=head2 port

  If not given, is read from the configuration file. Failing that, 5672 is used.

=head2 username

=head2 password

=head2 vhost

=head2 exchange

=head2 routing_key

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item wtsi_clarity::util::error_reporter

=item AnyEvent

=item AnyEvent::RabbitMQ

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
