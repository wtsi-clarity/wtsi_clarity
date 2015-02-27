use strict;
use warnings;
use Test::Exception;
use Test::More tests => 6;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};


use_ok('wtsi_clarity::epp::generic::bed_verifier');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433',
    step_name => 'working_dilution',
  );

  can_ok($process, qw/ run /);

  is($process->outputs, 1, 'Outputs defaults to true');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/122-26353',
    step_name => 'pre_capture_library_pooling',
  );

  can_ok($process, qw/ run /);

  lives_ok {$process->_bed_verifier} 'Got the verifier correctly.';

  lives_ok {$process->_bed_verifier->verify($process)} 'Bed got verified.';
}

1;