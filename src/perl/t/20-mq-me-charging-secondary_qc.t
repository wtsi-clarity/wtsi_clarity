use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::charging::secondary_qc');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/charging/secondary_qc';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::secondary_qc->new(
    process_url => $base_uri . '/processes/24-68264',
    step_url    => $base_uri . '/steps/24-68264',
    timestamp   => '2015-11-17 09:51:36',
    event_type  => 'charging_secondary_qc',
  );

  is($me->_user_identifier, 'karel@testsite.ac.uk', 'Extracts the user identifier correctly');

  my $me_mocked = Test::MockObject::Extends->new(
    wtsi_clarity::mq::me::charging::secondary_qc->new(
      process_url => $base_uri . '/processes/24-68264',
      step_url    => $base_uri . '/steps/24-68264',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_secondary_qc',
    )
  );

  $me_mocked->mock(q{_project_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  lives_ok { $me_mocked->prepare_messages } 'Prepares those messages just fine';
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::secondary_qc->new(
    process_url => $base_uri . '/processes/24-25340',
    step_url    => $base_uri . '/steps/24-25340',
    timestamp   => '2015-11-17 09:51:36',
    event_type  => 'charging_secondary_qc',
  );

  throws_ok { $me->_user_identifier }
    qr{The technician XML element is missing from the process XML document.},
    'Errors when the technician XML element is missing';
}

{
  my $me_mocked = Test::MockObject::Extends->new( 
    wtsi_clarity::mq::me::charging::secondary_qc->new(
      process_url => $base_uri . '/processes/24-68264',
      step_url    => $base_uri . '/steps/24-68264',
      timestamp   => '2015-11-17 09:51:36',
      event_type  => 'charging_secondary_qc',
    )
  );

  my $expected_json = [
    {
      'lims' => 'C_GCLP_D',
      'event' => {
                   'subjects' => [
                                   {
                                     'subject_type' => 'clarity_project',
                                     'friendly_name' => 'Test Project XXX123',
                                     'uuid' => 'd1bd68c9-92b4-11e5-841d-d1ffc6ce5ce4',
                                     'role_type' => 'clarity_charge_project'
                                   }
                                 ],
                   'event_type' => 'charging_secondary_qc',
                   'metadata' => {
                                   'product_type' => 'Secondary QC GCLP',
                                   'cost_code' => 'S01XYZ',
                                   'pipeline' => 'SM',
                                   'number_of_samples' => 20
                                 },
                   'user_identifier' => 'karel@testsite.ac.uk',
                   'uuid' => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
                   'occured_at' => '2015-12-02'
                 }
    }
  ];

  $me_mocked->mock(q{_get_uuid}, sub {

    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  is_deeply($me_mocked->prepare_messages, $expected_json, 'Got the correct message');
}

1;