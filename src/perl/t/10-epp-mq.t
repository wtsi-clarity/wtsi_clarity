use strict;
use warnings;
use DateTime;
use Test::More tests => 12;
use Test::Exception;

use_ok('wtsi_clarity::mq::message::epp');
use_ok('wtsi_clarity::epp::generic::messenger');

{
  my $m;
  lives_ok {$m = wtsi_clarity::epp::generic::messenger->new(
       process_url => 'http://some.com/process/XM4567',
       step_url    => 'http://some.com/step/AS456',
       purpose     => 'sample',)
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
       purpose     => 'sample',
       _date       => $date,
  );
  my $message;
  lives_ok {$message = $m->_message } 'message generated';
  isa_ok( $message, 'wtsi_clarity::mq::message::epp',
    'message generated as wtsi_clarity::mq::message::epp type object');
  ok(!(ref $message->timestamp), 'timestamp coerced');
  my $json;
  lives_ok { $json = $message->freeze } 'can serialize message object';
  my $date_as_string = $date->strftime("%a %b %d %Y %T");
  like($json, qr/$date_as_string/, 'date serialized correctly');
  lives_ok { wtsi_clarity::mq::message::epp->thaw($json) }
    'can read json string back';
}

{
  my $date = DateTime->now();
  my $m = wtsi_clarity::epp::generic::messenger->new(
    process_url => 'http://some.com/process/XM4567',
    step_url    => 'http://some.com/step/AS456',
    purpose     => 'rubbish',
    _date       => $date,
  );

  dies_ok { $m->_message } 'Dies when purpose is not one belonging to WTSIClarityMqPurpose';
}

1;
