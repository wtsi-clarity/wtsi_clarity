use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

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
      analysis_file => '122-22674',
      process_url => $base_uri . '/processes/122-22674',
    );
  my $expected_input_table_data = {
    'Plate limsid'  => '27-2213',
    'Plate barcode' => '6250354579651'
  };
  is_deeply($pool_analyser->_input_table_data, $expected_input_table_data, 'Returns input table data correctly.');
}

{
  my $pool_analyser = wtsi_clarity::epp::isc::pool_analyser->new(
      analysis_file => '122-22674',
      process_url => $base_uri . '/processes/122-22674',
    );
  my $expected_plate_table_data = {
            'A:1' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name1',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:1'
                   },
            'B:1' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name2',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:1'
                   },
            'C:1' => {
                      'study_name' => 'Study_ABC',
                      'sample_name'  => 'sample_name3',
                      'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:1'
                    },
            'D:1' => {
                      'study_name' => 'Study_ABC',
                      'sample_name'  => 'sample_name4',
                      'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:1'
                    },
            'E:1' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name5',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:1'
                   },
            'F:1' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name6',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:1'
                    },
            'G:1' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name7',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:1'
                   },
            'H:1' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name8',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:1'
                   },
            'A:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name9',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'B:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name10',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'C:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name11',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'D:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name12',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'E:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name13',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'F:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name14',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'G:2' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name15',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'B:1'
                    },
            'H:2' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name16',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:1'
                   },
            'A:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name17',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'B:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name18',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'C:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name19',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'D:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name20',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'E:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name21',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'F:3' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name22',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'C:1'
                    },
            'G:3' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name23',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'C:1'
                    },
            'H:3' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name24',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:1'
                   },
            'A:4' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name25',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'D:1'
                    },
            'B:4' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name26',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:1'
                   },
            'C:4' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name27',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'D:1'
                    },
            'D:4' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name28',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:1'
                   },
            'E:4' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name29',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:1'
                   },
            'F:4' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name30',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:1'
                   },
            'G:4' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name31',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'D:1'
                    },
            'H:4' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name32',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:1'
                   },
            'A:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name33',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'B:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name34',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'C:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name35',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'D:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name36',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'E:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name37',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'F:5' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name38',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'E:1'
                    },
            'G:5' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name39',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'E:1'
                   },
            'H:5' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name40',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'E:1'
                    },
            'A:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name41',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'B:6' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name42',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'F:1'
                    },
            'C:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name43',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'D:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name44',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'E:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name45',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'F:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name46',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'G:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name47',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'H:6' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name48',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'F:1'
                   },
            'A:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name49',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'B:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name50',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'C:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name51',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'D:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name52',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'E:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name53',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'F:7' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name54',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'G:1'
                    },
            'G:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name55',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'H:7' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name56',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'G:1'
                   },
            'A:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name57',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'B:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name58',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'C:8' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name59',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'H:1'
                    },
            'D:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name60',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'E:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name61',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'F:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name62',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'G:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name63',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'H:8' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name64',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'H:1'
                   },
            'A:9' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name65',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:2'
                   },
            'B:9' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name66',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:2'
                   },
            'C:9' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name67',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:2'
                    },
            'D:9' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name68',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:2'
                    },
            'E:9' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name69',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:2'
                    },
            'F:9' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name70',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'A:2'
                    },
            'G:9' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name71',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:2'
                   },
            'H:9' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name72',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'A:2'
                   },
            'A:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name73',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'B:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name74',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'C:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name75',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'D:10' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name76',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'B:2'
                    },
            'E:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name77',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'F:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name78',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'G:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name79',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'H:10' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name80',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'B:2'
                   },
            'A:11' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name81',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:2'
                   },
            'B:11' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name82',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'C:2'
                    },
            'C:11' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name83',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:2'
                   },
            'D:11' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name84',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:2'
                   },
            'E:11' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name85',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'C:2'
                    },
            'F:11' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name86',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:2'
                   },
            'G:11' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name87',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'C:2'
                    },
            'H:11' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name88',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'C:2'
                   },
            'A:12' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name89',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'D:2'
                    },
            'B:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name90',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   },
            'C:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name91',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   },
            'D:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name92',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   },
            'E:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name93',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   },
            'F:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name94',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   },
            'G:12' => {
                      'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name95',
                     'organism'     => 'Homo Sapiens',
                      'bait_library_name' => 'DDD_V5_plus',
                      'pooled_into' => 'D:2'
                    },
            'H:12' => {
                     'study_name' => 'Study_ABC',
                     'sample_name'  => 'sample_name96',
                     'organism'     => 'Homo Sapiens',
                     'bait_library_name' => 'DDD_V5_plus',
                     'pooled_into' => 'D:2'
                   }
    };
  is_deeply($pool_analyser->_plate_table_data, $expected_plate_table_data, 'Returns plate table data correctly.');
}

{
  my $pool_analyser = wtsi_clarity::epp::isc::pool_analyser->new(
      analysis_file => '122-22674',
      process_url => $base_uri . '/processes/122-22674',
    );
  my $results = ();
  $results->{'input_table_data'} = $pool_analyser->_input_table_data;
  $results->{'plate_table_data'} = $pool_analyser->_plate_table_data;
  lives_ok { wtsi_clarity::util::pdf::factory->createPDF('pool_analysis_results', $results)}
    'Creates a PDF file for the pool analysis.';
}

1;