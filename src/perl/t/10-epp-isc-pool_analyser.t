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
        'sample_name' => '132',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '125',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '181',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '170',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '176',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '153',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '107',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '165',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '147',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '157',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '128',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '136',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '106',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '185',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '142',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '123',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '150',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '102',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '143',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '149',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '154',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '189',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '179',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '135',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '186',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '182',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '138',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '164',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '105',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '163',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '188',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '120',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '166',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '122',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '158',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '168',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '113',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '172',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '148',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '171',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '139',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '183',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '98',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '110',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '121',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '162',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '167',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '155',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '145',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '160',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '114',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '118',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '133',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '99',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '175',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '161',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '141',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '134',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '184',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '130',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '104',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '127',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '156',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '151',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '108',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '126',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '177',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '187',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '173',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '178',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '159',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '112',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '152',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '129',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '191',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '109',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '119',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '117',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:1',
        'sample_name' => '146',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '103',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '192',
        'organism' => '',
        'bait_library_name' => '14M_0670551'
      },
      'H:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '144',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '111',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '169',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '97',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '137',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '180',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '101',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'F:1',
        'sample_name' => '190',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:1',
        'sample_name' => '100',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '115',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '140',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:1',
        'sample_name' => '131',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '124',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'E:1',
        'sample_name' => '174',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:1',
        'sample_name' => '116',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      }
    },
    {
      'D:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '228',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '221',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '266',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '277',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '249',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '272',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '203',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '243',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '261',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '253',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '224',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '232',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '202',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '281',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '238',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '219',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '246',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '198',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '245',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '250',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '239',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '285',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '275',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '231',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '282',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '278',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '234',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '260',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '201',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '259',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '216',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '284',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '218',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '264',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '209',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '268',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '244',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '267',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '235',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '279',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '194',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '206',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '217',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '263',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '241',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '251',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '256',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '210',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '214',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '229',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '195',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '271',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '237',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:9' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '257',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '230',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '226',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '280',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '200',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '223',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '247',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '204',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '222',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '283',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '273',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '269',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '274',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:8' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '255',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '208',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '248',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '225',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '205',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '287',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '215',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '213',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '199',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'B:7' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'B:2',
        'sample_name' => '242',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'H:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '288',
        'organism' => '',
        'bait_library_name' => '14M_0670551'
      },
      'H:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '240',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'G:2' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '207',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '193',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '265',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'A:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '233',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:11' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '276',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'E:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '197',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:12' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'D:2',
        'sample_name' => '286',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:1' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'G:1',
        'sample_name' => '196',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '211',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:6' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '236',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'C:5' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'A:2',
        'sample_name' => '227',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:4' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '220',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'F:10' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'C:2',
        'sample_name' => '270',
        'organism' => 'Homo Sapiens',
        'bait_library_name' => '14M_0670551'
      },
      'D:3' => {
        'study_name' => 'daniel andrews',
        'pooled_into' => 'H:1',
        'sample_name' => '212',
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