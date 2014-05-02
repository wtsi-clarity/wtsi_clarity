use strict;
use warnings;
use Test::More tests => 6;

use_ok('wtsi_clarity::epp');

{
  my $epp = wtsi_clarity::epp->new(process_url => 'http://some.com/process/XM4567');
  isa_ok( $epp, 'wtsi_clarity::epp');
  is ($epp->base_url, q[http://some.com/], 'base url');

  my $host = 'http://clarity-ap..some.ac.uk:8080/api/v2/';
  $epp = wtsi_clarity::epp->new(process_url => $host . 'processes/24-1026');
  is ($epp->base_url, $host, 'base url');
  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';
  is(ref $epp->config, 'wtsi_clarity::util::config', 'config accessor built');
  is($epp->config->clarity_mq->{'host'}, 'host1', 'conf option correctly retrieved');
}

1;
