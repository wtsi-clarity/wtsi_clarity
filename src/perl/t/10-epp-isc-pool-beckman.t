use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Test::MockObject::Extends;
use Test::Warn;
use Carp;

use_ok('wtsi_clarity::epp::isc::pool_beckman_creator', 'can create beckman driver file for pooling');

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  my $some_content =[
                      {
                        'Sample' => '1',
                        'Name'=> 'PCRXP1',
                        'Source EAN13' => '1234567890123',
                        'Source Barcode' => 'DN367818',
                        'Source Stock' => 'DN365894',
                        'Source Well' => 'A1',
                        'Destination EAN13' => '1234567890124',
                        'Destination Barcode' => 'DN369421',
                        'Destination Well' => 'A1',
                        'Source Volume' => '38.9',
                      },
                      {
                        'Sample'              => '2',
                        'Name'                 => 'PCRXP1',
                        'Source EAN13'        => '1234567890123',
                        'Source Barcode'      => 'DN367818',
                        'Source Stock'        => 'DN365894',
                        'Source Well'         => 'A2',
                        'Destination EAN13'   => '1234567890124',
                        'Destination Barcode' => 'DN369421',
                        'Destination Well'    => 'B1',
                        'Source Volume'       => '24.94',
                      },
                    ];
  my $expected_result = [
          'Sample, Name, Source EAN13, Source Barcode, Source Stock, Source Well, Destination EAN13, Destination Barcode, Destination Well, Source Volume',
          '1, PCRXP1, 1234567890123, DN367818, DN365894, A2, 1234567890124, DN369421, B1, 24.94',
          '2, PCRXP1, 1234567890123, DN367818, DN365894, A1, 1234567890124, DN369421, A1, 38.9'
        ];
  my $pooling_calculator_result = {
    'PCRXP1' => {
      'A1' => [
              {
                'Molarity' => '15',
                'source_plate' => '1234567890123',
                'Volume' => '38.9',
                'source_well' => 'A1'
              },
          ],
        'B1' => [
              {
                'Molarity' => '12',
                'source_plate' => '1234567890123',
                'Volume' => '24.94',
                'source_well' => 'A2'
              },
          ]
        },
      };
  my $mocked_beckman_creator = Test::MockObject::Extends->new( 
        wtsi_clarity::epp::isc::pool_beckman_creator->new(
          process_url => $base_uri . '/processes/122-21977')
      );

  $mocked_beckman_creator->mock(q(_get_result_from_pool_calculator), sub{
     return $pooling_calculator_result;
  });

  my $file_content = $mocked_beckman_creator->_beckman_file->content;

  is_deeply($file_content, $expected_result, 'get_file returns a file object with the correct content');
}

1;
