use strict;
use warnings;
use Test::More tests => 4;

use_ok('wtsi_clarity::epp');

{
  my $epp = wtsi_clarity::epp->new(process_id => 'XM4567');
  isa_ok( $epp, 'wtsi_clarity::epp');

  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';
  is(ref $epp->config, 'wtsi_clarity::util::config', 'config accessor built');
  is($epp->config->clarity_mq->{'host'}, 'host1', 'conf option correctly retrieved');
}

1;