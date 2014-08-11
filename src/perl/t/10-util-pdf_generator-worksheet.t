use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Test::Simple;
use DateTime;
use XML::LibXML;
use Carp;
use File::Temp;

use_ok('wtsi_clarity::util::pdf_generator::worksheet', 'can use wtsi_clarity::util::pdf_worksheet_generator' );

my $TEST_DATA = {
  'stamp' => 'made today',
  'pages' => [
    {
      'title' => 'title',
      'input_table' => [[1,2,3],['a','b','c']],
      'input_table_title' => 'input',
      'output_table' => [[1,2,3],['a','b','c']],
      'output_table_title' => 'output',
      'plate_table' => [[0,1,2,3,4,5,6,7,8,9,10,11,12,13],
                        ['A',1,2,3,4,5,6,7,8,9,10,11,12,13],
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
          ['HEADER_STYLE','COLOUR_0','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_2','COLOUR_2','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_3','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_4','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_5','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','EMPTY_STYLE','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','COLOUR_1','HEADER_STYLE',],
          ['HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE',],
        ],
    },
  ]
};

{ # create_worksheet_file
  my $worksheet_pdf_generator = wtsi_clarity::util::pdf_generator::worksheet->new(pdf_data => $TEST_DATA);
  my $file = $worksheet_pdf_generator->create();
  ok($file,'create_worksheet_file should produce a file.');
}

1;