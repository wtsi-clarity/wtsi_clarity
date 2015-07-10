use strict;
use warnings;
use Carp;

use Test::More tests => 11;
use Test::MockObject;

use_ok('wtsi_clarity::mq::consumer');

{
  my $message;
  my $routing_key;
  my $on_consume_end_called = 0;

  my $message_handler = Test::MockObject->new();

  $message_handler->mock('process', sub {
    my ($self, %args) = @_;
    $message          = $args{'message'};
    $routing_key      = $args{'routing_key'};
  });

  my $consumer = wtsi_clarity::mq::consumer->new(
    name            => 'Test Consumer',
    queue           => 'test_queue',
    pid_file        => 'test_pid',
    stderr_file     => 'stderr_file',
    stdout_file     => 'stdout_file',
    message_handler => $message_handler,
    on_consume_end  => sub {
      $on_consume_end_called = 1;
    },
  );

  isa_ok($consumer, 'wtsi_clarity::mq::consumer');

  can_ok($consumer, qw/ name queue pid_file stderr_file stdout_file message_handler
                        channel_name credentials daemon client on_startup on_consume
                        on_consume_error on_consume_end run log_message log_error_message
                        program /);

  $consumer->on_consume->({
    body => {
      payload => 'here is the message'
    },
    deliver => {
      method_frame => {
        routing_key => 'routing_key',
      }
    }
  });

  is($message_handler->called('process'), 1, 'The message handler gets called when a message is consumed');
  is($message, 'here is the message', 'message_handler::process is passed the message');
  is($routing_key, 'routing_key',     'message_handler::process is passed the routing_key');
  is($on_consume_end_called, 1, 'The on_consume_end is called after message_handler::process');
}

{
  my $message_handler = Test::MockObject->new();

  $message_handler->mock('process', sub {
    croak 'something has gone wrong processing the message';
  });

  my $on_consume_error_called = 0;
  my $error_message;
  my $message_args;
  my $on_consume_end_called = 0;

  my $consumer = wtsi_clarity::mq::consumer->new(
    name             => 'Test Consumer',
    queue            => 'test_queue',
    pid_file         => 'test_pid',
    stderr_file      => 'stderr_file',
    stdout_file      => 'stdout_file',
    message_handler  => $message_handler,
    on_consume_error => sub {
      ($error_message, $message_args) = @_;
      $on_consume_error_called = 1;
    },
    on_consume_end   => sub {
      $on_consume_end_called = 1;
    },
  );

  my $args = {
    body => {
      payload => 'here is the message'
    },
    deliver => {
      method_frame => {
        routing_key => 'routing_key',
      }
    }
  };

  $consumer->on_consume->($args);

  is($on_consume_error_called, 1, 'The on_consume_error callback is called when message_handler::process croaks');
  like($error_message, qr/something has gone wrong processing the message/,
    'The on_consume_error callback receives the error message as its first argument');
  is_deeply($message_args, $args, 'The on_consume_error callback receives the message args as the second argument');
  is($on_consume_end_called, 1, 'The on_consume_end is called even after message_handler::process croaked');
}

1;