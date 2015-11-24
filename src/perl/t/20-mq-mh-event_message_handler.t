use strict;
use warnings;

use Test::More tests => 3;
use Test::MockObject::Extends;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::mq::mh::event_message_handler');

{
  my $mq_handler = wtsi_clarity::mq::mh::event_message_handler->new();
  isa_ok($mq_handler, 'wtsi_clarity::mq::mh::event_message_handler');
}

{
  my $mock_mq_handler = Test::MockObject::Extends->new( wtsi_clarity::mq::mh::event_message_handler->new() );

  $mock_mq_handler->mock(q{prepare_messages}, sub { return [{lims => 'CLARITY-GCLP'}]; });
  $mock_mq_handler->mock(q{_send_message}, sub { return 1; });

  my $json_string = '{"__CLASS__":"wtsi_clarity::mq::me::charging::fluidigm","process_url":"http://clarity.com:1234","step_url":"http://clarity.com:1234/step","timestamp":"2014-11-25 12:06:27","purpose":"charging_fluidigm"}';
  lives_ok { $mock_mq_handler->process(message => $json_string, routing_key => 'event')} 'Message processing was successful';
}

1;