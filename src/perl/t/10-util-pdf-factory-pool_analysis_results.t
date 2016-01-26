use strict;
use warnings;
use Test::More tests => 14;

use_ok('wtsi_clarity::util::pdf::factory::pool_analysis_results');

{
  my $pool_analysis_results = wtsi_clarity::util::pdf::factory::pool_analysis_results->new();
  isa_ok($pool_analysis_results, 'wtsi_clarity::util::pdf::factory::pool_analysis_results');
}

{
  my $cell = {
    'study_name'        => 'Study_ABC',
    'sample_name'       => 'sample_name',
    'organism'          => 'Homo_sapiens',
    'bait_library_name' => 'DDD_V5_plus',
    'pooled_into'       => 'A:1'
  };

  my $output = "Study_ABC
sample_name\nHomo_sapiens\nDDD_V5_plus";

  is(wtsi_clarity::util::pdf::factory::pool_analysis_results::format_table_cell($cell), $output, 'Formats a table cell correctly');
}

{
  my $header_row = ['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  is_deeply(wtsi_clarity::util::pdf::factory::pool_analysis_results::table_header_row(), $header_row, 'Creates a header row');
}

{
  my $footer_row = ['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  is_deeply(wtsi_clarity::util::pdf::factory::pool_analysis_results::table_footer_row(), $footer_row, 'Creates a footer row');
}

{
  my $header_style = ['HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE'];
  is_deeply(wtsi_clarity::util::pdf::factory::pool_analysis_results::headers_row(), $header_style, 'Creates a header style row');
}

{
  my $input = { 'pooled_into' => 'A:1' };
  my $result = 'COLOUR_0';
  is(wtsi_clarity::util::pdf::factory::pool_analysis_results::format_style_table_cell($input), $result, 'Formats a style cell correctly');
}

{
  my $input = 'A';
  my $result = 'A';
  is(wtsi_clarity::util::pdf::factory::pool_analysis_results::table_row_first_column($input), $result, 'Creates the first column correctly');
}

{
  my $input = [
    '0123456',
    '6250354579651'
  ];
  my $input_table_result = [['Plate name', 'Barcode', 'Signature'], ['0123456', '6250354579651']];
  is_deeply(wtsi_clarity::util::pdf::factory::pool_analysis_results::_get_input_table_data($input), $input_table_result, 'Creates the correct input table.');
}

{
  my $table_info = [
    {
      'input_table_data' => [
        '0123456',
        '6250354579651'
      ],
      'plate_table_data' => {
        'A:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name1',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'B:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name2',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'C:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name3',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'D:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name4',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'E:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name5',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'F:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name6',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'G:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name7',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'H:1' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name8',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:1'
        },
        'A:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name9',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'B:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name10',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'C:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name11',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'D:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name12',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'E:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name13',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'F:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name14',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'G:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name15',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'H:2' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name16',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:1'
        },
        'A:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name17',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'B:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name18',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'C:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name19',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'D:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name20',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'E:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name21',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'F:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name22',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'G:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name23',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'H:3' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name24',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:1'
        },
        'A:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name25',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'B:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name26',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'C:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name27',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'D:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name28',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'E:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name29',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'F:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name30',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'G:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name31',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'H:4' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name32',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:1'
        },
        'A:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name33',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'B:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name34',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'C:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name35',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'D:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name36',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'E:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name37',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'F:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name38',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'G:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name39',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'H:5' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name40',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'E:1'
        },
        'A:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name41',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'B:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name42',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'C:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name43',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'D:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name44',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'E:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name45',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'F:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name46',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'G:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name47',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'H:6' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name48',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'F:1'
        },
        'A:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name49',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'B:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name50',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'C:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name51',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'D:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name52',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'E:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name53',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'F:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name54',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'G:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name55',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'H:7' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name56',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'G:1'
        },
        'A:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name57',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'B:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name58',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'C:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name59',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'D:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name60',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'E:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name61',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'F:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name62',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'G:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name63',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'H:8' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name64',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'H:1'
        },
        'A:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name65',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'B:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name66',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'C:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name67',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'D:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name68',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'E:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name69',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'F:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name70',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'G:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name71',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'H:9' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name72',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'A:2'
        },
        'A:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name73',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'B:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name74',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'C:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name75',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'D:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name76',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'E:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name77',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'F:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name78',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'G:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name79',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'H:10' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name80',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'B:2'
        },
        'A:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name81',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'B:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name82',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'C:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name83',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'D:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name84',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'E:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name85',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'F:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name86',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'G:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name87',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'H:11' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name88',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'C:2'
        },
        'A:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name89',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'B:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name90',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'C:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name91',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'D:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name92',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'E:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name93',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'F:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name94',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'G:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name95',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        },
        'H:12' => {
          'study_name' => 'Study_ABC',
          'sample_name'  => 'sample_name96',
          'organism'     => 'Homo_sapiens',
          'bait_library_name' => 'DDD_V5_plus',
          'pooled_into' => 'D:2'
        }
      }
    }
  ];

  my $table_data = [
    [
      '',
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    ],
    [
      'A',
      'Study_ABC
sample_name1
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name9
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name17
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name25
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name33
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name41
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name49
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name57
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name65
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name73
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name81
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name89
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'B',
      'Study_ABC
sample_name2
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name10
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name18
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name26
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name34
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name42
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name50
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name58
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name66
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name74
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name82
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name90
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'C',
      'Study_ABC
sample_name3
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name11
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name19
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name27
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name35
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name43
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name51
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name59
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name67
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name75
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name83
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name91
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'D',
      'Study_ABC
sample_name4
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name12
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name20
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name28
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name36
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name44
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name52
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name60
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name68
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name76
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name84
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name92
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'E',
      'Study_ABC
sample_name5
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name13
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name21
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name29
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name37
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name45
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name53
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name61
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name69
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name77
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name85
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name93
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'F',
      'Study_ABC
sample_name6
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name14
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name22
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name30
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name38
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name46
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name54
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name62
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name70
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name78
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name86
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name94
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'G',
      'Study_ABC
sample_name7
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name15
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name23
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name31
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name39
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name47
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name55
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name63
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name71
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name79
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name87
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name95
Homo_sapiens
DDD_V5_plus'
    ],
    [
      'H',
      'Study_ABC
sample_name8
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name16
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name24
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name32
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name40
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name48
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name56
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name64
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name72
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name80
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name88
Homo_sapiens
DDD_V5_plus',
      'Study_ABC
sample_name96
Homo_sapiens
DDD_V5_plus'
    ],
    [
      '',
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    ]
  ];

  my $table_style = [
    [
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'COLOUR_0',
      'COLOUR_1',
      'COLOUR_2',
      'COLOUR_3',
      'COLOUR_4',
      'COLOUR_5',
      'COLOUR_6',
      'COLOUR_7',
      'COLOUR_8',
      'COLOUR_9',
      'COLOUR_10',
      'COLOUR_11'
    ],
    [
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE',
      'HEADER_STYLE'
    ]
  ];

  my $factory = wtsi_clarity::util::pdf::factory::pool_analysis_results->new();
  my $file = $factory->build($table_info);

  is_deeply($factory->_format($factory->plate_table, $table_info->[0]->{'plate_table_data'}), $table_data);
  is_deeply($factory->_format($factory->plate_style_table, $table_info->[0]->{'plate_table_data'}), $table_style);

  ok($file, 'does create a file object');
  $file->saveas('./test_pool_worksheet.pdf');
  my $pdf = PDF::API2->open('./test_pool_worksheet.pdf');
  ok($pdf, 'Created file could be opened.');
  unlink './test_pool_worksheet.pdf';
}

{
  my $factory = wtsi_clarity::util::pdf::factory::pool_analysis_results->new();

  my $table_info = {
    'input_table_data' => {
      'Plate name'  => '0123456',
      'Barcode'     => '6250354579651'
    },
    'plate_table_data' => {
      'A:2' => {
        'study_name' => 'Study_ABC',
        'sample_name'  => 'sample_name9',
        'organism'     => 'Homo_sapiens',
        'bait_library_name' => 'DDD_V5_plus',
        'pooled_into' => 'B:1'
      },
    }
  };

  my $table_data = [
    [
      '',
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    ],
    [
      'A',
      '',
      'Study_ABC
sample_name9
Homo_sapiens
DDD_V5_plus',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'B',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'C',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'D',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'E',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'F',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'G',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      'H',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ],
    [
      '',
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    ]
  ];

  is_deeply($factory->_format($factory->plate_table, $table_info->{'plate_table_data'}), $table_data);
}

1;