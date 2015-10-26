use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/control_verifier';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};
my $prefix = q[http://testserver.com:1234/here/artifacts/];
my $test_data_dir = q[t/data/epp/generic/control_verifier];

local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  use_ok ('wtsi_clarity::epp::generic::control_verifier');

  my $epp = wtsi_clarity::epp::generic::control_verifier->new(
    process_url => $base_uri . '/processes/24-67069',
    step_url    => $base_uri . '/steps/24-67069',
  );

  lives_ok{
    $epp->_validate()
  } "Passes with no control samples";
}

{
  use_ok ('wtsi_clarity::epp::generic::control_verifier');

  my $epp = wtsi_clarity::epp::generic::control_verifier->new(
    process_url => $base_uri . '/processes/24-67067',
    step_url    => $base_uri . '/steps/24-67067',
  );

  throws_ok{
    $epp->_validate()
  } qr/Control sample already added./, "Throws with control sample";
}


