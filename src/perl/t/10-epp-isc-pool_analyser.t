use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;
use Test::Deep;
use Test::MockObject::Extends;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::isc::pool_analyser');

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pool_analyser';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

1;