use strict;
use warnings;
use Test::More tests => 2;

use_ok('wtsi_clarity::util::pdf_generator::pico_analysis_results', 'can use wtsi_clarity::util::pdf_worksheet_generator' );

my $TEST_DATA = {
  'stamp' => 'made with love today',
  'pages' => [
    {
      'title' => 'title',
      'plate_table' => [[0,1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['A',"1\n2\n3",2,3,4,5,6,7,8,9,10,11,12,13],
                        ['B',1,2,'hello',4,5,6,7,8,9,10,11,12,13],
                        ['c',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['d',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['e',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['f',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['g',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['h',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['*',1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ],
      'plate_table_title' => 'plate',
      'plate_table_cell_styles' => [
          ['HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE',],
          ['HEADER_STYLE','PASS','PASS','FAIL','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS','PASS', 'PASS'],
          ['HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE',],
        ],
    },
  ]
};


{ # create_worksheet_file
  my $pico_pdf_generator = wtsi_clarity::util::pdf_generator::pico_analysis_results->new(pdf_data => $TEST_DATA);
  my $file = $pico_pdf_generator->create();
  ok($file,'create_worksheet_file should produce a file.');
  # $file->saveas('./pico_worksheet.pdf');
}

1;