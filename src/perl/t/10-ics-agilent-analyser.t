use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;

use_ok('wtsi_clarity::ics::agilent::analyser');

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $testdata_path => q(./t/data/ics/agilent/);
Readonly::Scalar my $file1_name => q(1234567890_A1_B4.xml);
Readonly::Scalar my $file2_name => q(1234567890_A1_B4_wrong.xml);
## use critic

{ # get_analysis_results should work
  my $parser = XML::LibXML->new();
  my $file1 = $parser->load_xml(location => $testdata_path.$file1_name) or croak 'File can not be found at ' . $testdata_path.$file1_name;
  my $mapping = {
    'A:1' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '1', '2' ]},
    'A:2' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '3', '4' ]},
    'A:3' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '5', '6' ]},
    'A:4' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '7', '8' ]},
    'A:5' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '11', '12' ]},
    'A:6' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '9', '10' ]},
  };
  my $files_content = {
    '1234567890_A1_B4' => $file1,
  };
  my $instance = wtsi_clarity::ics::agilent::analyser->new(mapping_details => $mapping, files_content => $files_content);
  isa_ok( $instance, 'wtsi_clarity::ics::agilent::analyser');

  my $results = $instance->get_analysis_results();
  my $expected = {
          'A:3' => {
                     'molarity' => '103.43167',
                     'concentration' => '19.82783',
                     'size' => '289.97505'
                   },
          'A:6' => {
                     'molarity' => '152.25185',
                     'concentration' => '35.79975',
                     'size' => '369.9737'
                   },
          'A:2' => {
                     'molarity' => '145.8582',
                     'concentration' => '28.20428',
                     'size' => '292.60725'
                   },
          'A:4' => {
                     'molarity' => '133.61655',
                     'concentration' => '32.818185',
                     'size' => '372.8842'
                   },
          'A:1' => {
                     'molarity' => '93.703835',
                     'concentration' => '18.361455',
                     'size' => '296.99425'
                   },
          'A:5' => {
                     'molarity' => '265.53055',
                     'concentration' => '12.588155',
                     'size' => '156.2668'
                   }
    };
  is_deeply($results, $expected, qq/get_analysis_results should return the correct results./);
}


{ #_data_set should build properly with correct input
  my $parser = XML::LibXML->new();
  my $file1 = $parser->load_xml(location => $testdata_path.$file1_name) or croak 'File can not be found at ' . $testdata_path.$file1_name;
  my $mapping = {
    'A:1' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '1', '2' ]},
    'A:2' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '3', '4' ]},
    'A:3' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '5', '6' ]},
    'A:4' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '7', '8' ]},
    'A:5' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '11', '12' ]},
    'A:6' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '9', '10' ]},
  };
  my $files_content = {
    '1234567890_A1_B4' => $file1,
  };

  my $instance = wtsi_clarity::ics::agilent::analyser->new(mapping_details => $mapping, files_content => $files_content);
  my $results = $instance->_data_set();
  my $expected = { '1234567890_A1_B4' => {
                                  '6' => {
                                         'molarity' => '73.45164',
                                         'concentration' => '13.97738',
                                         'size' => '288.3233'
                                       },
                                  '11' => {
                                          'molarity' => '106.8191',
                                          'concentration' => '20.97631',
                                          'size' => '297.5336'
                                        },
                                  '3' => {
                                         'molarity' => '74.814',
                                         'concentration' => '14.41023',
                                         'size' => '291.8393'
                                       },
                                  '7' => {
                                         'molarity' => '134.7697',
                                         'concentration' => '25.52816',
                                         'size' => '287.0005'
                                       },
                                  '9' => {
                                         'molarity' => '124.0543',
                                         'concentration' => '36.3524',
                                         'size' => '443.9938'
                                       },
                                  '12' => {
                                          'molarity' => '424.242',
                                          'concentration' => '4.2',
                                          'size' => '15'
                                        },
                                  '2' => {
                                         'molarity' => '99.88341',
                                         'concentration' => '19.48127',
                                         'size' => '295.515'
                                       },
                                  '8' => {
                                         'molarity' => '132.4634',
                                         'concentration' => '40.10821',
                                         'size' => '458.7679'
                                       },
                                  '1' => {
                                         'molarity' => '87.52426',
                                         'concentration' => '17.24164',
                                         'size' => '298.4735'
                                       },
                                  '4' => {
                                         'molarity' => '216.9024',
                                         'concentration' => '41.99833',
                                         'size' => '293.3752'
                                       },
                                  '10' => {
                                          'molarity' => '180.4494',
                                          'concentration' => '35.2471',
                                          'size' => '295.9536'
                                        },
                                  '5' => {
                                         'molarity' => '133.4117',
                                         'concentration' => '25.67828',
                                         'size' => '291.6268'
                                       }
                                }
        };
  is_deeply($results, $expected, qq/_data_set should build properly with correct input./);
}


{ #_data_set should fail properly with the wrong input.
  my $parser = XML::LibXML->new();
  my $file1 = $parser->load_xml(location => $testdata_path.$file2_name) or croak 'File can not be found at ' . $testdata_path.$file2_name;
  my $mapping = {
    'A:1' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '1', '2' ]},
    'A:2' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '3', '4' ]},
    'A:3' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '5', '6' ]},
    'A:4' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '7', '8' ]},
    'A:5' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '11', '12' ]},
    'A:6' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '9', '10' ]},
  };
  my $files_content = {
    '1234567890_A1_B4' => $file1,
  };

  my $instance = wtsi_clarity::ics::agilent::analyser->new(mapping_details => $mapping, files_content => $files_content);
  throws_ok { $instance->_data_set(); print Dumper $instance->_data_set; }
  qr/The number of 'Concentration' tag is not correct. The XML '1234567890_A1_B4' is not well formed/,
  qq/_data_set should fail properly with the wrong input./;
}

{ #_average_of_measurement should return the correct results.
  my $data_set = {
    "truc" => {
        '1' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '2' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '3' => {
         'molarity' => '200',
         'concentration' => '300',
         'size' => '500',
        },
      },
    };
  my $source = "A:1";
  my $output_wells = ['1', '3'];
  my $measure = 'concentration';
  my $filename = "truc";

  my $results = wtsi_clarity::ics::agilent::analyser::_average_of_measurement($data_set, $filename, $source, $output_wells, $measure);
  my $expected = 200;
  cmp_ok($results, '==', $expected, qq/_average_of_measurement should return the correct results./);
}

{ # _average_of_measurement should fail well an output well is missing.
  my $data_set = {
    "truc" => {
        '1' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '2' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '3' => {
         'molarity' => '200',
         'concentration' => '300',
         'size' => '500',
        },
      },
    };
  my $source = "A:1";
  my $output_wells = ['1', '7'];
  my $measure = 'concentration';
  my $filename = "truc";

  throws_ok { wtsi_clarity::ics::agilent::analyser::_average_of_measurement($data_set, $filename, $source, $output_wells, $measure) }
    qr/The plate $filename is expected to contain a well 7!/,
    qq/_average_of_measurement should fail when an output well is missing./;
}

{ # _average_of_measurement should fail well an output well is missing.
  my $data_set = {
    "truc" => {
        '1' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '2' => {
          'molarity' => '100',
          'concentration' => '100',
          'size' => '100',
         },
        '3' => {
         'molarity' => '200',
         'concentration' => '300',
         'size' => '500',
        },
      },
    };
  my $source = "A:1";
  my $output_wells = [ ];
  my $measure = 'concentration';
  my $filename = "truc";

  throws_ok { wtsi_clarity::ics::agilent::analyser::_average_of_measurement($data_set, $filename, $source, $output_wells, $measure) }
    qr/One needs at least one output well value for the source well .* in $filename to calculate an average 'concentration'/,
    qq/_average_of_measurement should fail when there is no output well./;
}

1;
