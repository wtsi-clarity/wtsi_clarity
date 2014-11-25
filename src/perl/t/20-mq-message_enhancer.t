use warnings;
use strict;

use Test::More tests => 3;

use_ok('wtsi_clarity::mq::message_enhancer');

{
  my $me = wtsi_clarity::mq::message_enhancer->new(
    process_url => 'http://testserver.com:1234/processes/999',
    step_url    => 'http://testserver.com:1234/processes/999/step/2',
    timestamp   => '2014-11-25 12:06:27',
  );

  isa_ok($me, 'wtsi_clarity::mq::message_enhancer');
  can_ok($me, qw/ process_url step_url publish /);
}