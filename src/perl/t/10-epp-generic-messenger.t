use strict;
use warnings;
use Test::More tests => 6;

use_ok('wtsi_clarity::mq::client');

{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  my $r = wtsi_clarity::mq::client->new();
  isa_ok( $r, 'wtsi_clarity::mq::client');
  is( $r->port, 5672, 'default port');
  is( $r->host, 'localhost', 'localhost');
  is( $r->username, 'guest', 'username from config file');
  is( $r->password, 'guest', 'password from config file');
}

1;