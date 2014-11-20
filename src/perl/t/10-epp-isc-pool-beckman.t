use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Test::MockObject::Extends;
use Test::Warn;
use Carp;

use wtsi_clarity::epp::isc::pool_calculator;

use_ok('wtsi_clarity::epp::isc::pool_beckman_creator', 'can create beckman driver file for pooling');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pool_beckman';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
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
          process_url => $base_uri . '/processes/122-22459')
      );

  $mocked_beckman_creator->mock(q(_get_result_from_pool_calculator), sub{
     return $pooling_calculator_result;
  });

  my $file_content = $mocked_beckman_creator->_beckman_file->content;

  is_deeply($file_content, $expected_result, 'get_file returns a file object with the correct content');
}

{
  my $beckman_creator = wtsi_clarity::epp::isc::pool_beckman_creator->new(
          process_url => $base_uri . '/processes/122-22459');
  can_ok($beckman_creator, qw/ run /);
}

{
  my $beckman_creator = wtsi_clarity::epp::isc::pool_beckman_creator->new(
          process_url => $base_uri . '/processes/122-22459');
  is($beckman_creator->_file_path, 't/data/epp/isc/pool_beckman/122-22459.csv', 'Creates the correct file name.');
}

1;
