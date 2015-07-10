package wtsi_clarity::mq::consumer;

use Moose;
use Carp;
use Try::Tiny;
use WTSI::DNAP::RabbitMQ::Client;
use POSIX qw(strftime);
use English qw(-no_match_vars);
use AnyEvent;
use Daemon::Control;

with 'wtsi_clarity::util::configurable';

our $VERSION = '0.0';

my @REQUIRED_ATTRS  = qw/name queue pid_file stderr_file stdout_file/;

my %REQUIRED_RO_STR = ( is => 'ro', isa => 'Str', required => 1, );

my %CALLBACK_ATTRS  = (
  is       => 'rw',
  isa      => 'CodeRef',
  required => 1,
  lazy     => 1,
);

has [@REQUIRED_ATTRS] => ( %REQUIRED_RO_STR );

has 'channel_name' => ( %REQUIRED_RO_STR, default => 'channel' . $PID, );

has 'dlx'          => ( %REQUIRED_RO_STR, lazy => 1, builder => '_build_dlx' );

has 'credentials' => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
  lazy     => 1,
  builder  => '_build_credentials',
);

has 'daemon' => (
  is      => 'ro',
  isa     => 'Daemon::Control',
  lazy    => 1,
  builder => '_build_daemon',
);

has 'client' => (
  is      => 'ro',
  isa     => 'Object',
  lazy    => 1,
  builder => '_build_client',
);

has 'message_handler' => (
  is       => 'ro',
  isa      => 'WtsiClarityMessageHandler',
  required => 1,
);

has 'on_startup'       => ( %CALLBACK_ATTRS, builder => '_build_on_startup', );
has 'on_consume'       => ( %CALLBACK_ATTRS, builder => '_build_on_consume', );
has 'on_consume_error' => ( %CALLBACK_ATTRS, builder => '_build_on_consume_error', );
has 'on_consume_end'   => ( %CALLBACK_ATTRS, builder => '_build_default_callback', );
has 'on_client_error'  => ( %CALLBACK_ATTRS, builder => '_build_on_client_error', );

sub run {
  my $self = shift;
  $self->daemon->program_args(\@ARGV);
  exit $self->daemon->run;
}

sub log_message {
  my $self    = shift;
  my $message = shift // q{};
  print {*STDOUT} join q{ }, _now(), qq{$message\n} or croak 'Can not write to STDOUT';
  return;
}

sub log_error_message {
  my $self    = shift;
  my $message = shift // q{};
  print {*STDERR} join q{ }, _now(), qq{$message\n} or croak 'Can not write to STDERR';
  return;
}

sub program {
  my ($self, @args) = @_;

  $self->on_startup->(@args);

  $self->client->connect( @{$self->credentials} )
               ->open_channel( name => $self->channel_name )
               ->consume( channel => $self->channel_name, queue => $self->queue );

  return AnyEvent->condvar->recv;
}

sub send_to_dlx {
  my ($self, $message_args) = @_;

  return $self->client->publish(
    channel     => $self->channel_name,
    exchange    => $self->dlx,
    routing_key => $message_args->{'deliver'}->{'method_frame'}->{'routing_key'},
    body        => $message_args->{'body'}->{'payload'},
  );
}

sub _build_dlx {
  my $self = shift;
  return $self->config->clarity_mq->{'dead_letter_exchange'};
}

sub _build_credentials {
  my $self = shift;

  return [
    host  => $self->config->clarity_mq->{'host'},
    port  => $self->config->clarity_mq->{'port'},
    vhost => $self->config->clarity_mq->{'vhost'},
    user  => $self->config->clarity_mq->{'username'},
    pass  => $self->config->clarity_mq->{'password'},
  ]
}

sub _build_daemon {
  my $self = shift;

  return Daemon::Control->new(
    name        => $self->name,
    pid_file    => $self->pid_file,
    stderr_file => $self->stderr_file,
    stdout_file => $self->stdout_file,
    program     => sub { $self->program },
  );
}

sub _build_client {
  my $self = shift;

  return WTSI::DNAP::RabbitMQ::Client->new(
    acking_enabled  => 1,
    consume_handler => sub { $self->on_consume->( @_ ) },
    error_handler   => sub { $self->on_client_error->( @_ ) },
  );
}

sub _build_on_startup {
  my $self = shift;
  return sub {
    $self->log('Starting ' . $self->name . '...');
  }
}

sub _build_on_consume {
  my $self = shift;

  return sub {
    my $args = shift;

    try {
      $self->message_handler->process(
        message     => $args->{'body'}->{'payload'},
        routing_key => $args->{'deliver'}->{'method_frame'}->{'routing_key'},
      );
    } catch {
      $self->on_consume_error->($_, $args);
    } finally {
      $self->on_consume_end->();
    }
  }
}

sub _build_on_consume_error {
  my $self = shift;

  return sub {
    my ($error_message, $message_args) = @_;

    $self->err('There was an error while trying to handle a message');
    $self->err($error_message);

    $self->send_to_dlx($message_args);

    return 1;
  }
}

sub _build_on_client_error {
  my $self = shift;
  return sub {
    my $response = shift;
    $self->err('There was an error with the message queue client');
    $self->err($response);
  }
}

sub _build_default_callback {
  return sub { };
}

sub _now {
  return strftime "%F %H:%M:%S", localtime;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::consumer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 run Calls exit whilst starting the daemon

=head2 log_message Sends a message with a timestamp to STDOUT

=head2 log_error_message Sends a message with a timestamp to STDERR

=head2 program A subroutine that is passed to Daemon::Contols program arg

=head2 send_to_dlx Sends a message to the configured DLX using the already opened channel

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Try::Tiny

=item WTSI::DNAP::RabbitMQ::Client

=item POSIX

=item English

=item AnyEvent

=item Daemon::Control

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
