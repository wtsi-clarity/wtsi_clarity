use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::charging::sequencing');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/charging/sequencing';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::sequencing->new(
    process_url => $base_uri . '/processes/24-68270',
    step_url    => $base_uri . '/steps/24-68270',
    timestamp   => '2015-11-17 09:51:36',
    event_type  => 'charging_sequencing',
  );

  is($me->_user_identifier, 'karel@testsite.ac.uk', 'Extracts the user identifier correctly');
  is($me->product_type, 'GCLP ISC', 'Gets the correct product type information');
  is($me->pipeline, 'IHTP', 'Gets the correct pipeline information');

  my $me_mocked = Test::MockObject::Extends->new(
    wtsi_clarity::mq::me::charging::sequencing->new(
      process_url => $base_uri . '/processes/24-68270',
      step_url    => $base_uri . '/steps/24-68270',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_sequencing',
    )
  );

  $me_mocked->mock(q{_project_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  lives_ok { $me_mocked->prepare_messages } 'Prepares those messages just fine';
}

{
  my $me_mocked = Test::MockObject::Extends->new( 
    wtsi_clarity::mq::me::charging::sequencing->new(
      process_url => $base_uri . '/processes/24-68270',
      step_url    => $base_uri . '/steps/24-68270',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_sequencing',
    )
  );

  my $expected_json = [
    {
      'lims'  => 'C_GCLP_D',
      'event' => {
        'subjects'        => [
          {
            'subject_type'  => 'clarity_project',
            'friendly_name' => 'AD_test_250714',
            'uuid'          => '3f29ea9f-9cce-11e5-b8ab-cfa7c16b1e7b',
            'role_type'     => 'clarity_charge_project'
          }
        ],
        'event_type'      => 'charging_sequencing',
        'metadata'        => {
          'product_type'    => 'GCLP ISC',
          'pipeline'        => 'IHTP',
          'version'         => '1',
          'platform'        => '2500',
          'run_type'        => 'PE',
          'read_length'     => 75,
          'plex_level'      => '8',
          'cost_code'       => 'S4019',
          'number_of_lanes' => 8
        },
        'user_identifier' => 'karel@testsite.ac.uk',
        'uuid'            => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
        'occured_at'      => '2015-12-02'
      }
    }
  ];

  $me_mocked->mock(q{_get_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  is_deeply($me_mocked->prepare_messages, $expected_json, 'Got the correct message');
}

1;