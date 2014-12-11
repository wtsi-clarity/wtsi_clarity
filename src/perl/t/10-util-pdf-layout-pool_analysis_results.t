use strict;
use warnings;
use Test::More tests => 3;

use_ok('wtsi_clarity::util::pdf::layout::pool_analysis_results', 'can use wtsi_clarity::util::pdf::layout::pool_analysis_results' );

my $TEST_DATA = {
  'stamp' => 'This is the timestamp',
  'pages' => [
    {
      'title' => 'Pooling worksheets for 0123456 plate',
      'input_table' => [['Plate name','Barcode'],['0123456','6250123456651']],
      'input_table_title' => 'Source Plate',
      'plate_table' => [[0,1,2,3,4,5,6,7,8,9,10,11,12],
                        ['A',"1\n2\n3",2,3,4,5,6,7,8,9,10,11,12],
                        ['B',1,2,'hello',4,5,6,7,8,9,10,11,12],
                        ['c',1,2,3,4,5,6,7,8,9,10,11,12],
                        ['d',1,2,3,4,5,6,7,8,9,10,11,12],
                        ['e',1,2,3,4,5,6,7,8,9,10,11,12],
                        ['f',1,2,3,4,5,6,7,8,9,10,11,12],
                        ['g',1,2,3,4,5,6,7,8,9,10,11,12],
                        ['h',1,2,3,4,5,6,7,8,9,10,11,12],
                        ],
      'plate_table_title' => 'plate',
      'plate_table_cell_styles' => [
          ['HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_2','COLOUR_3','COLOUR_4','COLOUR_5','COLOUR_6','COLOUR_7','COLOUR_8','COLOUR_9','COLOUR_10','COLOUR_11'],
        ],
    },
  ]
};


{ # create_worksheet_file
  my $pool_pdf_generator = wtsi_clarity::util::pdf::layout::pool_analysis_results->new(pdf_data => $TEST_DATA);
  my $file = $pool_pdf_generator->create();
  ok($file,'create method should produce a file.');
 $file->saveas('./test_pool_worksheet.pdf');
  my $pdf = PDF::API2->open('./test_pool_worksheet.pdf');
  ok($pdf, 'Created file could be opened.');
  unlink './test_pool_worksheet.pdf';
}

1;