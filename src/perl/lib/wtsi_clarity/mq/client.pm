package wtsi_clarity::mq::client;

use Moose;
use Readonly;
use Carp;
use JSON;
use WTSI::DNAP::RabbitMQ::Client;

with 'wtsi_clarity::util::configurable';

our $VERSION = '0.0';

Readonly::Scalar my $PORT            => 5672;
Readonly::Scalar my $TIMEOUT         => 2;

has 'message_bus_type'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  default         => 'clarity_mq',
);

has 'host'      => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build_host {
  my $self = shift;
  return $self->_mq_config->{'host'} || 'localhost';
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

foreach my $attr ( qw/env password username vhost exchange routing_key/) {

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
  my $mb_type = $self->message_bus_type;
  return $self->config->$mb_type;
}

sub send_message {
  my ($self, $message, $purpose) = @_;

  my @credentials = ( host  => $self->host,
                      port  => $self->port,
                      vhost => $self->vhost,
                      user  => $self->username,
                      pass  => $self->password,);
                      # cond  => $cv);

  ##no critic(Variables::ProhibitPunctuationVars)
  my $channel_name = 'client_channel'. $$;
  ## use critic
  my $client;

  $client = WTSI::DNAP::RabbitMQ::Client->new(
    blocking_enabled => 0,
    connect_handler => sub {
      $client->open_channel(name => $channel_name);
    },
    open_channel_handler => sub {
      $client->publish( channel     => $channel_name,
                        exchange    => $self->exchange,
                        routing_key => $self->_assemble_routing_key($purpose),
                        body        => to_json($message),
                        mandatory   => 1);
      $client->disconnect;
    }
  );

  $client->connect(@credentials);

  return;
}

sub _assemble_routing_key {
  my ($self, $purpose) = @_;

  my $routing_key;

  if ($self->message_bus_type eq 'warehouse_mq') {
    $routing_key = $self->_mq_config->{'env'}. q{.} . $self->_mq_config->{'routing_key'} . q{.} . $purpose;
  } else {
    $routing_key = $self->routing_key;
  }

  return $routing_key;
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

=item Carp

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
