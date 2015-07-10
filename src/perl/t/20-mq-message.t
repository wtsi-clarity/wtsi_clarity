use strict;
use warnings;
use DateTime;

use Test::More tests => 10;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::mq::message');

my $timestamp = DateTime->now();
my %args      = ( process_url => 'http://clarity.com/processes/1',
                  step_url    => 'http://clarity.com/steps/1',
                  timestamp   => $timestamp );

{
  my $message = wtsi_clarity::mq::message->create('warehouse',
    purpose => 'sample',
    %args,
  );

  isa_ok($message, 'wtsi_clarity::mq::message_types::warehouse_message', 'create returns a warehouse_message object');
}

{
  my $message = wtsi_clarity::mq::message->create('report',
    purpose => '14MG',
    %args,
  );

  isa_ok($message, 'wtsi_clarity::mq::message_types::report_message', 'create returns a report_message object');
}

{
  my $message_as_json_str = '{"__CLASS__":"wtsi_clarity::mq::message_types::warehouse_message","process_url":"http://clarity.com/processes/1","purpose":"sample","step_url":"http://clarity.com/steps/1","timestamp":"Thu Jul 16 2015 13:10:26"}';
  isa_ok(wtsi_clarity::mq::message->defrost('warehouse', $message_as_json_str), 'wtsi_clarity::mq::message_types::warehouse_message');
}

{
  my $message_as_json_str = '{"__CLASS__":"wtsi_clarity::mq::message_types::report_message","process_url":"http://clarity.com/processes/1","purpose":"14MG","step_url":"http://clarity.com/steps/1","timestamp":"Thu Jul 16 2015 13:06:55"}';
  isa_ok(wtsi_clarity::mq::message->defrost('report', $message_as_json_str), 'wtsi_clarity::mq::message_types::report_message');
}

{
  throws_ok {
    wtsi_clarity::mq::message->create('warehouse',
      %args,
    );
  } q'Moose::Exception::AttributeIsRequired',
    q'create throws an error when purpose is not passed in';

  throws_ok {
    wtsi_clarity::mq::message->create('warehouse',
      purpose => 'not a valid purpose',
      %args,
    );
  } q{Moose::Exception::ValidationFailedForTypeConstraint},
    q{create throws an error when purpose is not a WtsiClarityMqWarehousePurpose for a warehouse message};

  throws_ok {
    wtsi_clarity::mq::message->create('report',
      purpose => 'not a valid purpose',
      %args,
    );
  } q{Moose::Exception::ValidationFailedForTypeConstraint},
    q{create throws an error when purpose is not a WtsiClarityMqReportPurpose for a report message};

  throws_ok {
    wtsi_clarity::mq::message->create('not a valid message_type',
      purpose => 'sample',
      %args,
    );
  } qr/Message type must be one of the following: /,
    q{create throws an error when message type is not valid};
}

{
  my $wh_message_as_json_str = '{"__CLASS__":"wtsi_clarity::mq::message_types::warehouse_message","process_url":"http://clarity.com/processes/1","purpose":"sample","step_url":"http://clarity.com/steps/1","timestamp":"Thu Jul 16 2015 13:10:26"}';

  throws_ok {
    wtsi_clarity::mq::message->defrost('not a valid message type', $wh_message_as_json_str);
  } qr/Message type must be one of the following: /,
    q{defrost throws an error when an invalid message type is passed in};

}

1;