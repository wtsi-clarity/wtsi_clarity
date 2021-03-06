use strict;
use warnings;
use Test::More tests => 18;

use_ok('wtsi_clarity::mq::local_client');
use_ok('wtsi_clarity::mq::warehouse_client');
use_ok('wtsi_clarity::util::config');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

{ # Tests for clarity mq client settings
  my $client = wtsi_clarity::mq::local_client->new();
  isa_ok( $client, 'wtsi_clarity::mq::local_client');
  is( $client->port, 5672, 'default port');
  is( $client->host, 'localhost', 'localhost');
  is( $client->username, 'guest', 'username from config file');
  is( $client->password, 'guest', 'password from config file');
}

{ # Tests for warehouse mq client settings
  my $client = wtsi_clarity::mq::warehouse_client->new(warehouse => 'unified');
  isa_ok( $client, 'wtsi_clarity::mq::warehouse_client');
  is( $client->env, 'devel', 'Gets the correct environment value from the config file.');
  is( $client->port, 1234, 'Gets the correct port from the config file.');
  is( $client->host, 'host1', 'Gets the correct host from the config file.');
  is( $client->vhost, 'vhost1', 'Gets the correct virtual host from the config file.');
  is( $client->exchange, 'warehouse_exch', 'Gets the correct exchange name from the config file');
  is( $client->username, 'user3', 'Gets the correct username from the config file.');
  is( $client->password, 'pword3', 'Gets the correct password from the config file');
  is( $client->routing_key, 'clarity', 'Gets the correct base routing key from the config file');
}

{ # Tests for generating the routing key
  my $client = wtsi_clarity::mq::local_client->new();

  my $config = wtsi_clarity::util::config->new();

  my $client_wh = wtsi_clarity::mq::warehouse_client->new(warehouse => 'unified');
  my $purpose = 'sample';
  my $expected_routing_key_wh = join q{.}, $config->warehouse_mq->{'env'}, $config->warehouse_mq->{'routing_key'}, $client_wh->warehouse, $purpose;

  is($client_wh->assemble_routing_key($purpose), $expected_routing_key_wh, 'Got back the correct routing key for warehouse mq.');
}

1;