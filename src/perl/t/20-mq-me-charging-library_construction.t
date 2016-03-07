use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::charging::library_construction');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/charging/library_construction';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::library_construction->new(
    process_url => $base_uri . '/processes/122-65197',
    step_url    => $base_uri . '/steps/122-65197',
    timestamp   => '2015-11-17 09:51:36',
    event_type  => 'charging_library_construction',
  );

  is($me->_user_identifier, 'karel@testsite.ac.uk', 'Extracts the user identifier correctly');
  is($me->product_type, 'GCLP ISC', 'Gets the correct product type information');
  is($me->pipeline, 'IHTP', 'Gets the correct pipeline information');
  is($me->_library_type, 'ISC', 'Gets the correct library type information');

  my $me_mocked = Test::MockObject::Extends->new(
    wtsi_clarity::mq::me::charging::library_construction->new(
      process_url => $base_uri . '/processes/122-65197',
      step_url    => $base_uri . '/steps/122-65197',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_library_construction',
    )
  );

  $me_mocked->mock(q{_project_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  lives_ok { $me_mocked->prepare_messages } 'Prepares those messages just fine';
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::library_construction->new(
    process_url => $base_uri . '/processes/122-41522',
    step_url    => $base_uri . '/steps/122-41522',
    timestamp   => '2015-11-17 09:51:36',
    event_type  => 'charging_library_construction',
  );

  is($me->_user_identifier, 'karel@testsite.ac.uk', 'Extracts the user identifier correctly');
  is($me->product_type, 'GCLP ISC', 'Gets the correct product type information');
  is($me->pipeline, 'IHTP', 'Gets the correct pipeline information');
  is($me->_library_type, 'ISC', 'Gets the correct library type information');

  my $me_mocked = Test::MockObject::Extends->new(
    wtsi_clarity::mq::me::charging::library_construction->new(
      process_url => $base_uri . '/processes/122-41522',
      step_url    => $base_uri . '/steps/122-41522',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_library_construction',
    )
  );

  $me_mocked->mock(q{_project_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  lives_ok { $me_mocked->prepare_messages } 'Prepares those messages just fine';
}

{
  my $me_mocked = Test::MockObject::Extends->new(
    wtsi_clarity::mq::me::charging::library_construction->new(
      process_url => $base_uri . '/processes/122-65197',
      step_url    => $base_uri . '/steps/122-65197',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_library_construction',
    )
  );

  my $expected_json = [
    {
      'lims'  => 'C_GCLP_D',
      'event' => {
        'subjects'        => [
          {
            'subject_type'  => 'clarity_project',
            'friendly_name' => 'lh13_project1',
            'uuid'          => 'd1bd68c9-92b4-11e5-841d-d1ffc6ce5ce4',
            'role_type'     => 'clarity_charge_project'
          }
        ],
        'event_type'      => 'charging_library_construction',
        'metadata'        => {
          'product_type'        => 'GCLP ISC',
          'library_type'        => 'ISC',
          'number_of_libraries' => 3,
          'bait_library'        => 'Human all exon V5',
          'cost_code'           => 'SX001',
          'plex_level'          => '8',
          'pipeline'            => 'IHTP'
        },
        'user_identifier' => 'karel@testsite.ac.uk',
        'uuid'            => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
        'occured_at'      => '2015-12-02'
      }
    },
    {
      'lims'  => 'C_GCLP_D',
      'event' => {
        'subjects'        => [
          {
            'subject_type'  => 'clarity_project',
            'friendly_name' => 'AD_test101',
            'uuid'          => 'b93a5cd3-d3e0-11e5-857c-c78c28316c7a',
            'role_type'     => 'clarity_charge_project'
          }
        ],
        'event_type'      => 'charging_library_construction',
        'metadata'        => {
          'product_type'        => 'GCLP ISC',
          'library_type'        => 'ISC',
          'number_of_libraries' => 2,
          'bait_library'        => 'Human all exon V5',
          'cost_code'           => 'test101',
          'plex_level'          => '8',
          'pipeline'            => 'IHTP'
        },
        'user_identifier' => 'karel@testsite.ac.uk',
        'uuid'            => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
        'occured_at'      => '2015-12-02'
      }
    },
    {
      'lims'  => 'C_GCLP_D',
      'event' => {
        'subjects'        => [
          {
            'subject_type'  => 'clarity_project',
            'friendly_name' => 'Test Project XXX123',
            'uuid'          => '5eb907b7-9204-11e5-9665-cec9d23d9897',
            'role_type'     => 'clarity_charge_project'
          }
        ],
        'event_type'      => 'charging_library_construction',
        'metadata'        => {
          'product_type'        => 'GCLP ISC',
          'library_type'        => 'ISC',
          'number_of_libraries' => 2,
          'bait_library'        => 'Human all exon V5',
          'cost_code'           => 'S01XYZ',
          'plex_level'          => '8',
          'pipeline'            => 'IHTP'
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