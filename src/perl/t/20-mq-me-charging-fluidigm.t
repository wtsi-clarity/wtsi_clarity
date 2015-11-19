use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::charging::fluidigm');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/charging/fluidigm';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $me = wtsi_clarity::mq::me::charging::fluidigm->new(
    process_url => $base_uri . '/processes/24-68036',
    step_url    => $base_uri . '/steps/24-68036',
    timestamp   => '2015-11-17 09:51:36',
  );

  is($me->_user_identifier, 'karel@testsite.ac.uk', 'Extracts the user identifier correctly');
  is($me->_cost_code, 'S01XYZ', 'Extracts the cost code correctly');
  is($me->_project_name, 'Test Project XXX123', 'Extracts the project name correctly');
  is($me->_number_of_samples, 9, 'Gets the number of samples correctly');

  lives_ok { $me->prepare_messages } 'Prepares those messages just fine';
}

{
  my $me_mocked = Test::MockObject::Extends->new( 
    wtsi_clarity::mq::me::charging::fluidigm->new(
      process_url => $base_uri . '/processes/24-68036',
      step_url    => $base_uri . '/steps/24-68036',
      timestamp   => '2015-11-17 09:51:36',
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
                                     'uuid' => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
                                     'role_type' => 'clarity_charge_project'
                                   }
                                 ],
                   'event_type' => 'billing',
                   'metadata' => {
                                   'product_type' => 'Human QC 96:96',
                                   'cost_code' => 'S01XYZ',
                                   'pipeline' => 'SM',
                                   'number_of_samples' => 9
                                 },
                   'user_identifier' => 'karel@testsite.ac.uk',
                   'uuid' => 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e',
                   'occured_at' => '2015-11-17 09:51:36'
                 }
    }
  ];

  $me_mocked->mock(q{_get_uuid}, sub {
    
    return 'cb11aa6e-8d10-11e5-ba7a-f94e03be199e';
  });

  is_deeply($me_mocked->prepare_messages, $expected_json, 'Got the correct message');
}
1;