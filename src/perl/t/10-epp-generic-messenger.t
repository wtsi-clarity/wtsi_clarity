use strict;
use warnings;
use DateTime;
use Test::More tests => 9;
use Test::Exception;
use Test::MockObject::Extends;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::mq::local_client');
use_ok('wtsi_clarity::epp::generic::messenger');
use_ok('wtsi_clarity::mq::message');

# Happpppppppy path...
{
  my $client = wtsi_clarity::mq::local_client->new();
  my $mocked_client = Test::MockObject::Extends->new($client);

  $mocked_client->set_true('send_message');

  my $m = wtsi_clarity::epp::generic::messenger->new(
    process_url => 'http://some.com/process/XM4567',
    step_url    => 'http://some.com/step/AS456',
    purpose     => ['study', 'sample'],
    routing_key => 'warehouse',
    _client     => $mocked_client,
    _messages   => _create_messages()
  );

  lives_ok { $m->run() }
    'Can run the run action';

  my ($method_name, $method_args) = $mocked_client->next_call();
  is($method_name, 'send_message', 'Sends the first message');
  ok($method_args->[1], '...and the argument is there');

  my ($method_name2, $method_args2) = $mocked_client->next_call();
  is($method_name2, 'send_message', 'Sends the second message');
  ok($method_args2->[1], '...and the argument is there again');
}

{
  throws_ok {
    wtsi_clarity::epp::generic::messenger->new(
      process_url => 'http://some.com/process/XM4567',
      step_url    => 'http://some.com/step/AS456',
      purpose     => ['study', 'sample'],
      routing_key => 'not a good routing key!!',
    );
  } q{Moose::Exception::ValidationFailedForTypeConstraint},
    q{Throws an error on creation if routing key is invalid};
}

sub _create_messages {
  my @messages = map {
    wtsi_clarity::mq::message->create('warehouse',
      process_url => 'http://clarity.com/processes/' . $_,
      step_url    => 'http://clarity.com/steps/' . $_,
      timestamp   => DateTime->now(),
      purpose     => 'sample',
    );
  } 1..2;

  return \@messages;
}

1;
