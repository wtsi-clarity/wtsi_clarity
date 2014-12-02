use strict;
use warnings;
use Test::More;

my $exit_code = system('rabbitmqctl status > /dev/null 2>&1');

if ($exit_code != 0) {
  plan skip_all => 'RabbitMQ needs to be running to run message_consumer tests';
} else {
  plan tests => 3;
}

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

use_ok('WTSI::DNAP::RabbitMQ::Client');

{
  local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];
  my $start_exit_code = system('./bin/message_consumer start --test > /dev/null');
  is($start_exit_code, 0, 'Daemon gets started fine');
  my $stop_exit_code = system('./bin/message_consumer stop > /dev/null');
  is($stop_exit_code, 0, 'Daemon gets stopped fine');
}