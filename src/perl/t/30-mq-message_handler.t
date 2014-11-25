use strict;
use warnings;

use Test::More tests => 2;

use_ok('wtsi_clarity::mq::message_handler');

{
  my $mq_consumer = wtsi_clarity::mq::message_handler->new();
  isa_ok($mq_consumer, 'wtsi_clarity::mq::message_handler');
}

1;