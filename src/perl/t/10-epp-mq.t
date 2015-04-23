use strict;
use warnings;
use DateTime;
use Test::More tests => 21;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::message');
use_ok('wtsi_clarity::epp::generic::messenger');
use_ok('wtsi_clarity::mq::client');

{
  my $m;

  lives_ok {$m = wtsi_clarity::epp::generic::messenger->new(
       process_url => 'http://some.com/process/XM4567',
       step_url    => 'http://some.com/step/AS456',
       purpose     => ['sample'],)
       }
    'object created with step_url and process_url sttributes';

  isa_ok( $m, 'wtsi_clarity::epp::generic::messenger');

  is(ref $m->_date, 'DateTime', 'default datetime object created');
}

{
  my $date = DateTime->now();

  my $m =  wtsi_clarity::epp::generic::messenger->new(
       process_url => 'http://some.com/process/XM4567',
       step_url    => 'http://some.com/step/AS456',
       purpose     => ['sample'],
       _date       => $date,
  );
  my $messages;

  lives_ok {$messages = $m->_messages } 'message generated';

  isa_ok($messages, 'ARRAY',
    'messages generated as ArrayRef type object');

  my $message = $messages->[0];

  isa_ok($message, 'wtsi_clarity::mq::message',
    'messages contains wtsi_clarity::mq::message type object');

  ok(!(ref $message->timestamp), 'timestamp coerced');

  my $json;
  lives_ok { $json = $message->freeze } 'can serialize message object';

  my $date_as_string = $date->strftime("%a %b %d %Y %T");
  like($json, qr/$date_as_string/, 'date serialized correctly');

  lives_ok { wtsi_clarity::mq::message->thaw($json) }
    'can read json string back';
}

{
  my $date = DateTime->now();

  my $m =  wtsi_clarity::epp::generic::messenger->new(
       process_url => 'http://some.com/process/XM4567',
       step_url    => 'http://some.com/step/AS456',
       purpose     => ['sample', 'study'],
       _date       => $date,
  );

  isa_ok($m->_messages, 'ARRAY',
    'messages generated as ArrayRef type object');

  is(scalar @{$m->_messages}, 2, 'Creates 2 messages from 2 purposes');
}

{
  my $date = DateTime->now();

  my $m = wtsi_clarity::epp::generic::messenger->new(
    process_url => 'http://some.com/process/XM4567',
    step_url    => 'http://some.com/step/AS456',
    purpose     => ['rubbish'],
    _date       => $date,
  );

  dies_ok { $m->_messages } 'Dies when purpose is not one belonging to WTSIClarityMqPurpose';
}

{
  my $client = wtsi_clarity::mq::client->new();
  my $mocked_client = Test::MockObject::Extends->new($client);
  $mocked_client->set_true('send_message');

  my $date = DateTime->now();

  my $m = wtsi_clarity::epp::generic::messenger->new(
    process_url => 'http://some.com/process/XM4567',
    step_url    => 'http://some.com/step/AS456',
    purpose     => ['study', 'sample'],
    _date       => $date,
    _client     => $mocked_client,
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

1;
