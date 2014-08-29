use strict;
use warnings;
use Test::More tests => 3;

use_ok('wtsi_clarity::epp');

{
  my $epp = wtsi_clarity::epp->new(process_url => 'http://some.com/process/XM4567');

  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';
  is(ref $epp->config, 'wtsi_clarity::util::config', 'config accessor built');
  is($epp->config->clarity_mq->{'username'}, 'user2', 'conf option correctly retrieved');
}

1;
