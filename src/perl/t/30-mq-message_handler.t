use strict;
use warnings;

use Test::More tests => 7;

use_ok('wtsi_clarity::mq::message_handler');

{
  my $mq_consumer = wtsi_clarity::mq::message_handler->new();
  isa_ok($mq_consumer, 'wtsi_clarity::mq::message_handler');
}

{
  my $mq_consumer = wtsi_clarity::mq::message_handler->new();
  my $json_string = '{"__CLASS__":"wtsi_clarity::mq::message::epp-0.33","process_url":"http://clarity.com:1234","step_url":"http://clarity.com:1234/step","timestamp":"2014-11-25 12:06:27","purpose":"sample"}';
  my $message = $mq_consumer->thaw($json_string);

  isa_ok($message, 'wtsi_clarity::mq::message');
  is($message->process_url, 'http://clarity.com:1234', 'Sets the process_url');
  is($message->step_url, 'http://clarity.com:1234/step', 'Sets the step_url');
  is($message->timestamp, '2014-11-25 12:06:27', 'Sets the timestamp');
  is($message->purpose, 'sample', 'Sets the purpose');
}

1;