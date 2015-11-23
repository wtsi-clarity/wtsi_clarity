use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::isc::pool_analyser');

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pool_analyser';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $pool_analyser = wtsi_clarity::epp::isc::pool_analyser->new(
    analysis_file => '122-22674',
    process_url => $base_uri . '/processes/122-22674',
  );
  isa_ok($pool_analyser, 'wtsi_clarity::epp::isc::pool_analyser');
}

{
  my $pool_analyser = wtsi_clarity::epp::isc::pool_analyser->new(
    analysis_file => '122-67220',
    process_url => $base_uri . '/processes/122-67220',
  );

  my $parameters = $pool_analyser->_get_parameters();

  my $expected_input_table_data = [
    [
      '27-12105',
      '2462712105806',
      'PJWVX'
    ],
    [
      '27-12825',
      '2462712825827',
      'SRQ1U'
    ],
  ];

  my @input_table_data = map {
    $_->{'input_table_data'}
  } @{$parameters};

  is_deeply(\@input_table_data, $expected_input_table_data, 'Returns input table data correctly.');

  my $expected_plate_table_data = [
    {
      'D:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4356',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4349',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4405',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4394',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4400',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4377',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4331',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4389',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4371',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4381',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4352',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4360',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4330',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4409',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4366',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4347',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4374',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4326',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4367',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4373',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4378',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4413',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4403',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4359',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4410',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4406',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4362',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4388',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4329',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4387',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4412',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4344',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4390',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4346',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4382',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4392',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4337',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4396',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4372',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4395',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4363',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4407',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4322',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4334',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4345',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4386',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4391',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4379',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4369',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4384',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4338',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4342',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4357',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4323',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4399',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4385',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4365',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4358',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4408',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4354',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4328',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4351',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4380',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4375',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4332',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4350',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4401',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4411',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4397',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4402',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4383',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4336',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4376',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4353',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4415',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4333',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4343',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4341',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => 'AND660A4370',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4327',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4416',
        'organism' => '',
        'bait_library_name' => '14M_0670551'
      },
      'H:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4368',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4335',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4393',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4321',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4361',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4404',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4325',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => 'AND660A4414',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => 'AND660A4324',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4339',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4364',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => 'AND660A4355',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4348',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => 'AND660A4398',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => 'AND660A4340',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      }
    },
    {
      'D:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4452',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4445',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4490',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4501',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4473',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4496',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4427',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4467',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4485',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4477',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4448',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4456',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4426',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4505',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4462',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4443',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4470',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4422',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4469',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4474',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4463',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4509',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4499',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4455',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4506',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4502',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4458',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4484',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4425',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4483',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4440',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4508',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4442',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4488',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4433',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4492',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4468',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4491',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4459',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4503',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4418',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4430',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4441',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4487',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4465',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4475',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4480',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4434',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4438',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4453',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4419',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4495',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4461',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4481',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4454',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4450',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4504',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4424',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4447',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4471',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4428',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4446',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4507',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4497',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4493',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4498',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4479',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4432',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4472',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4449',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4429',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4511',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4439',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4437',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4423',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => 'AND660A4466',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4512',
        'organism' => '',
        'bait_library_name' => '14M_0670551'
      },
      'H:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4464',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4431',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4417',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4489',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4457',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4500',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4421',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => 'AND660A4510',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => 'AND660A4420',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4435',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4460',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => 'AND660A4451',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4444',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => 'AND660A4494',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => 'AND660A4436',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      }
    }
  ];

  my @plate_table_data = map {
    $_->{'plate_table_data'}
  } @{$parameters};

  is_deeply(\@plate_table_data, $expected_plate_table_data, 'Returns plate table data correctly.');

  lives_ok {
    wtsi_clarity::util::pdf::factory::pool_analysis_results->new()->build($parameters)
  } 'Creates a PDF file for the pool analysis.';
}

1;