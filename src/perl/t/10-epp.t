use strict;
use warnings;
use Test::More tests => 4;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

use_ok('wtsi_clarity::epp');

{
  my $epp = wtsi_clarity::epp->new(process_url => 'http://some.com/process/XM4567');

  is(ref $epp->config, 'wtsi_clarity::util::config', 'config accessor built');
  is($epp->config->clarity_mq->{'username'}, 'guest', 'conf option correctly retrieved');
}

{
  my $epp = wtsi_clarity::epp->new(process_url => $base_uri . '/processes/24-30034');

  isa_ok($epp->step_doc, 'wtsi_clarity::clarity::step');
}

1;
