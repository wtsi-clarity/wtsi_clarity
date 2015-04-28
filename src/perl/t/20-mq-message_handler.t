use strict;
use warnings;

use Test::More tests => 10;
use Test::MockObject::Extends;
use Test::Exception;

use_ok('wtsi_clarity::mq::message_handler');

{
  my $mq_handler = wtsi_clarity::mq::message_handler->new();
  isa_ok($mq_handler, 'wtsi_clarity::mq::message_handler');
}

{
  my $mq_handler = wtsi_clarity::mq::message_handler->new();
  my $json_string = '{"__CLASS__":"wtsi_clarity::mq::message::epp-0.33","process_url":"http://clarity.com:1234","step_url":"http://clarity.com:1234/step","timestamp":"2014-11-25 12:06:27","purpose":"sample"}';
  my $message = $mq_handler->_thaw($json_string);

  isa_ok($message, 'wtsi_clarity::mq::message');
  is($message->process_url, 'http://clarity.com:1234', 'Sets the process_url');
  is($message->step_url, 'http://clarity.com:1234/step', 'Sets the step_url');
  is($message->timestamp, '2014-11-25 12:06:27', 'Sets the timestamp');
  is($message->purpose, 'sample', 'Sets the purpose');
}

{
  my $message_enhancers = {
    'sample'  => 'me::sample_enhancer',
  };

  my $mocked_mapper = Test::MockObject::Extends->new( wtsi_clarity::mq::mapper->new);
  $mocked_mapper->mock(q{package_name}, sub {
    my ($self, $purpose) = @_;
    return q{wtsi_clarity::mq::} . $message_enhancers->{$purpose}}
  );

  my $mq_handler = wtsi_clarity::mq::message_handler->new(mapper => $mocked_mapper);

  my $enhancer = $mq_handler->_find_enhancer_by_purpose('sample');

  is($enhancer, 'wtsi_clarity::mq::me::sample_enhancer', 'Gets the correct message enhancer');

  throws_ok { $mq_handler->_require_enhancer('aa:bb:cc')}
    qr/The required package: aa:bb:cc does not exist/,
    'Throws an error when the required enhancer does not exist.';
}

{
  my $mock_mq_handler = Test::MockObject::Extends->new( wtsi_clarity::mq::message_handler->new() );

  $mock_mq_handler->mock(q{prepare_messages}, sub { return [{lims => 'CLARITY-GCLP'}]; });
  $mock_mq_handler->mock(q{_send_message}, sub { return 1; });

  my $json_string = '{"__CLASS__":"wtsi_clarity::mq::message::epp-0.33","process_url":"http://clarity.com:1234","step_url":"http://clarity.com:1234/step","timestamp":"2014-11-25 12:06:27","purpose":"sample"}';
  lives_ok { $mock_mq_handler->process_message($json_string)} 'Message processing was successful';
}


1;