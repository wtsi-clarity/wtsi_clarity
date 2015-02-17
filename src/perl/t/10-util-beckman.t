use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use Text::CSV;

use_ok('wtsi_clarity::util::beckman', 'can use beckman');

{
  my $beckman = wtsi_clarity::util::beckman->new();
  my $some_content =[
                      {
                        'Sample' => '1',
                        'Name'=> '2',
                        'Source EAN13' => '4',
                        'Source Barcode' => 'g',
                        'Source Stock' => '5',
                        'Source Well' => '6',
                        'Destination EAN13' => '7',
                        'Destination Barcode' => '8',
                        'Destination Well' => '9',
                        'Source Volume' => '10',
                      },
                      {
                        'Sample'              => '2',
                        'Name'                 => '3',
                        'Source EAN13'        => '4',
                        'Source Barcode'      => 'h',
                        'Source Stock'        => '5',
                        'Source Well'         => '6',
                        'Destination EAN13'   => '7',
                        'Destination Barcode' => '8',
                        'Destination Well'    => '9',
                        'Source Volume'       => '10',
                      },
                    ];
  my $expected_result = [
          'Sample,Name,Source EAN13,Source Barcode,Source Stock,Source Well,Destination EAN13,Destination Barcode,Destination Well,Source Volume',
          '1,2,4,g,5,6,7,8,9,10',
          '2,3,4,h,5,6,7,8,9,10'
        ];
  my $file = $beckman->get_file($some_content);
  is_deeply($file->content, $expected_result, 'get_file returns a file object with the correct content');
}

1;
