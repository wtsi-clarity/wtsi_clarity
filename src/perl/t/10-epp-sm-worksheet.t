use strict;
use warnings;
use Test::More tests => 294;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;
use Data::Dumper;

use_ok('wtsi_clarity::epp::sm::worksheet', 'can use wtsi_clarity::epp::sm::worksheet' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

my $TEST_DATA = {
  'output_container_info' => {
    'container_uri' => {
      'container_details' =>{
                  'D:5' => {
                           'input_location' => 'C:4',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'E:4' => {
                           'input_location' => 'A:3',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'C:2' => {
                           'input_location' => 'A:6',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'B:2' => {
                           'input_location' => 'B:5',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'C:4' => {
                           'input_location' => 'D:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'B:6' => {
                           'input_location' => 'D:5',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'A:2' => {
                           'input_location' => 'A:5',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'B:4' => {
                           'input_location' => 'C:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'A:3' => {
                           'input_location' => 'A:11',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'C:6' => {
                           'input_location' => 'E:5',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'B:1' => {
                           'input_location' => 'B:1',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'A:4' => {
                           'input_location' => 'B:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'B:3' => {
                           'input_location' => 'A:12',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'E:5' => {
                           'input_location' => 'D:4',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'C:1' => {
                           'input_location' => 'A:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'E:6' => {
                           'input_location' => 'B:6',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'B:5' => {
                           'input_location' => 'A:4',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'D:2' => {
                           'input_location' => 'B:6',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'A:5' => {
                           'input_location' => 'E:3',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'E:2' => {
                           'input_location' => 'D:12',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'E:3' => {
                           'input_location' => 'C:1',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'A:1' => {
                           'input_location' => 'A:1',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'A:6' => {
                           'input_location' => 'C:5',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'E:1' => {
                           'input_location' => 'A:3',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'D:1' => {
                           'input_location' => 'B:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-23'
                         },
                  'C:3' => {
                           'input_location' => 'A:1',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'D:6' => {
                           'input_location' => 'A:6',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'C:5' => {
                           'input_location' => 'B:4',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'D:4' => {
                           'input_location' => 'E:2',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         },
                  'D:3' => {
                           'input_location' => 'B:1',
                           'sample_volume' => '1.2',
                           'buffer_volume' => '8.8',
                           'input_id' => '27-27'
                         }
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME',
      'barcode' => '1234567890123456',
      'wells' => '96',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
              'freezer' => '000021', 'shelf' => '0000022', 'rack' => '0000023', 'tray'=> '0000024' },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA2 = {
  'output_container_info' => {
    'container_uri' => {
      'container_details' =>{
        'A:1' => {
          'input_location' => 'C:4',
          'sample_volume' => '1.2',
          'buffer_volume' => '8.8',
          'input_id' => '27'
        },
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME',
      'barcode' => '1234567890123456',
      'wells' => '96',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
              'freezer' => '000021', 'shelf' => '0000022', 'rack' => '0000023', 'tray'=> '0000024' },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA3 = {
  'output_container_info' => {
    'container_uri' => {
        'container_details' =>{
          'A:1' => {
                 'input_location' => 'C:4',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '27',
                 'input_uri' => '27',
               },
          'A:2' => {
                 'input_location' => 'A:6',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '23',
                 'input_uri' => '23',
               },
          'A:3' => {
                 'input_location' => 'A:8',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '27',
                 'input_uri' => '27',
               },
          'A:4' => {
                 'input_location' => 'Z:8',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '25',
                 'input_uri' => '25',
                },
          'B:1' => {
                 'input_location' => 'A:3',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '27',
                 'input_uri' => '27',
               },
          'B:2' => {
                 'input_location' => 'B:5',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '23',
                 'input_uri' => '23',
               },
          'B:3' => {
                 'input_location' => 'C:5',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '23',
                 'input_uri' => '23',
               },
          'B:4' => {
                 'input_location' => 'E:5',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '23',
                 'input_uri' => '23',
               },
          'B:5' => {
                 'input_location' => 'E:6',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '23',
                 'input_uri' => '23',
               },
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME',
      'barcode' => '1234567890123456',
      'wells' => '96',
      'type' => 'type1',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
              'freezer' => '000021', 'shelf' => '000022', 'rack' => '000023', 'tray'=> '000024', 'type' => 'type27', },
    '25' => { 'purpose' => 'PLATE_PURPOSE_25', 'plate_name' => 'PLATE_NAME25', 'barcode' => '00000025', 'wells' => '25',
              'freezer' => '000031', 'shelf' => '000032', 'rack' => '000033', 'tray'=> '000034', 'type' => 'type25',  },
    '23' => { 'purpose' => 'PLATE_PURPOSE_23', 'plate_name' => 'PLATE_NAME23', 'barcode' => '00000023', 'wells' => '23',
              'freezer' => '000011', 'shelf' => '000012', 'rack' => '000013', 'tray'=> '000014', 'type' => 'type23',  },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA4 = {
  'output_container_info' => {
    'container_uri1' => {
        'container_details' =>{
          'A:1' => {
                 'input_location' => 'C:4',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '27',
                 'input_uri' => '27',
               },
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME1',
      'barcode' => '12345678900001',
      'wells' => '96',
      'type' => 'type1',
    },
    'container_uri2' => {
        'container_details' =>{
          'A:1' => {
                 'input_location' => 'B:2',
                 'sample_volume' => '1.2',
                 'buffer_volume' => '8.8',
                 'input_id' => '29',
                 'input_uri' => '29',
               },
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME2',
      'barcode' => '12345678900002',
      'wells' => '96',
      'type' => 'type1',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
              'freezer' => '000021', 'shelf' => '000022', 'rack' => '000023', 'tray'=> '000024', 'type' => 'type27', },
    '29' => { 'purpose' => 'PLATE_PURPOSE_29', 'plate_name' => 'PLATE_NAME29', 'barcode' => '00000029', 'wells' => '29',
              'freezer' => '000029', 'shelf' => '000029', 'rack' => '000029', 'tray'=> '000029', 'type' => 'type29', },
  },
  'process_id' => 'PROCESS_ID',
};


{ # _get_TECAN_file_content_per_URI
  my @expected_samples = (
    qq{A;00000027;;type27;27;;1.2},
    qq{D;1234567890123456;;type1;1;;1.2},
    qq{W;},
    qq{A;00000023;;type23;41;;1.2},
    qq{D;1234567890123456;;type1;9;;1.2},
    qq{W;},
    qq{A;00000027;;type27;57;;1.2},
    qq{D;1234567890123456;;type1;17;;1.2},
    qq{W;},
    qq{A;00000025;;type25;82;;1.2},
    qq{D;1234567890123456;;type1;25;;1.2},
    qq{W;},
    qq{A;00000027;;type27;17;;1.2},
    qq{D;1234567890123456;;type1;2;;1.2},
    qq{W;},
    qq{A;00000023;;type23;34;;1.2},
    qq{D;1234567890123456;;type1;10;;1.2},
    qq{W;},
    qq{A;00000023;;type23;35;;1.2},
    qq{D;1234567890123456;;type1;18;;1.2},
    qq{W;},
    qq{A;00000023;;type23;37;;1.2},
    qq{D;1234567890123456;;type1;26;;1.2},
    qq{W;},
    qq{A;00000023;;type23;45;;1.2},
    qq{D;1234567890123456;;type1;34;;1.2},
    qq{W;},
  );
  my @expected_buffers = (
    qq{A;BUFF;;96-TROUGH;27;;8.8},
    qq{D;1234567890123456;;type1;1;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;41;;8.8},
    qq{D;1234567890123456;;type1;9;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;57;;8.8},
    qq{D;1234567890123456;;type1;17;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;82;;8.8},
    qq{D;1234567890123456;;type1;25;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;17;;8.8},
    qq{D;1234567890123456;;type1;2;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;34;;8.8},
    qq{D;1234567890123456;;type1;10;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;35;;8.8},
    qq{D;1234567890123456;;type1;18;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;37;;8.8},
    qq{D;1234567890123456;;type1;26;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;45;;8.8},
    qq{D;1234567890123456;;type1;34;;8.8},
    qq{W;},
  );
  my ($samples, $buffers) = wtsi_clarity::epp::sm::worksheet::_get_TECAN_file_content_per_URI($TEST_DATA3, 'container_uri' );
  cmp_ok(scalar @$samples, '==', 9*3, "_get_TECAN_file_content_per_URI should return the correct size nb of samples.");
  cmp_ok(scalar @$buffers, '==', 9*3 , "_get_TECAN_file_content_per_URI should return the correct size nb of buffers.");

  foreach my $expected (@expected_samples) {
    my $val = shift $samples;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content_per_URI(...) should give the correct samples.");
  }

  foreach my $expected (@expected_buffers) {
    my $val = shift $buffers;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content_per_URI(...) should give the correct buffers.");
  }
}

{ # _get_TECAN_file_content
  my @expected_data = (
    qq{C;},
    qq{C; This file created by benoit on today},
    qq{C;},
    qq{A;00000027;;type27;27;;1.2},
    qq{D;12345678900001;;type1;1;;1.2},
    qq{W;},
    qq{A;00000029;;type29;10;;1.2},
    qq{D;12345678900002;;type1;1;;1.2},
    qq{W;},

    qq{A;BUFF;;96-TROUGH;27;;8.8},
    qq{D;12345678900001;;type1;1;;8.8},
    qq{W;},
    qq{A;BUFF;;96-TROUGH;10;;8.8},
    qq{D;12345678900002;;type1;1;;8.8},
    qq{W;},

    qq{C;},
    qq{C; SRC1 = 00000027},
    qq{C; SRC2 = 00000029},
    qq{C;},
    qq{C; DEST1 = 12345678900001},
    qq{C; DEST2 = 12345678900002},
    qq{C;},

  );
  my $table = wtsi_clarity::epp::sm::worksheet::_get_TECAN_file_content($TEST_DATA4, 'benoit', 'today' );
  cmp_ok(scalar @$table, '==', 3 + 3*4 + 2*2 + 3 , "_get_TECAN_file_content should return an array of the correct size (nb of rows).");

  foreach my $expected (@expected_data) {
    my $val = shift $table;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content(...) should give the correct content.");
  }
}

{ # _get_TECAN_file_content
  my %expected_data = (
    'A:1' =>  1,
    'B:1' =>  2,
    'C:1' =>  3,
    'D:1' =>  4,
    'E:1' =>  5,
    'F:1' =>  6,
    'G:1' =>  7,
    'H:1' =>  8,
    'A:2' =>  9,
    'B:2' => 10,
    'C:2' => 11,
    'D:2' => 12,
    'E:2' => 13,
    'F:2' => 14,
    'G:2' => 15,
    'H:2' => 16,
    'A:3' => 17,
    'B:3' => 18,
    'C:3' => 19,
    'D:3' => 20,
    'E:3' => 21,
    'F:3' => 22,
    'G:3' => 23,
    'H:3' => 24,
    'A:4' => 25,
    'B:4' => 26,
    'C:4' => 27,
    'D:4' => 28,
    'E:4' => 29,
    'F:4' => 30,
    'G:4' => 31,
    'H:4' => 32,
    'A:5' => 33,
    'B:5' => 34,
    'C:5' => 35,
    'D:5' => 36,
    'E:5' => 37,
    'F:5' => 38,
    'G:5' => 39,
    'H:5' => 40,
    'A:6' => 41,
    'B:6' => 42,
    'C:6' => 43,
    'D:6' => 44,
    'E:6' => 45,
    'F:6' => 46,
    'G:6' => 47,
    'H:6' => 48,
    'A:7' => 49,
    'B:7' => 50,
    'C:7' => 51,
    'D:7' => 52,
    'E:7' => 53,
    'F:7' => 54,
    'G:7' => 55,
    'H:7' => 56,
    'A:8' => 57,
    'B:8' => 58,
    'C:8' => 59,
    'D:8' => 60,
    'E:8' => 61,
    'F:8' => 62,
    'G:8' => 63,
    'H:8' => 64,
    'A:9' => 65,
    'B:9' => 66,
    'C:9' => 67,
    'D:9' => 68,
    'E:9' => 69,
    'F:9' => 70,
    'G:9' => 71,
    'H:9' => 72,
    'A:10' =>73,
    'B:10' =>74,
    'C:10' =>75,
    'D:10' =>76,
    'E:10' =>77,
    'F:10' =>78,
    'G:10' =>79,
    'H:10' =>80,
    'A:11' =>81,
    'B:11' =>82,
    'C:11' =>83,
    'D:11' =>84,
    'E:11' =>85,
    'F:11' =>86,
    'G:11' =>87,
    'H:11' =>88,
    'A:12' =>89,
    'B:12' =>90,
    'C:12' =>91,
    'D:12' =>92,
    'E:12' =>93,
    'F:12' =>94,
    'G:12' =>95,
    'H:12' =>96,
  );


  while (my ($loc, $exp_loc) = each %expected_data ) {
    # print $loc," ", $exp_loc, "<\n";
    my $val = wtsi_clarity::epp::sm::worksheet::_get_location_in_decimal( $loc );
    cmp_ok($val, 'eq', $exp_loc, "_get_location_in_decimal(...) should give the correct content.");
  }
}

{ # testing _get_location
  my @test_data = (
    { 'in' => [ 0, 0,10,10], 'out' => undef, },
    { 'in' => [ 0,11,10,10], 'out' => undef, },
    { 'in' => [11, 0,10,10], 'out' => undef, },
    { 'in' => [11,11,10,10], 'out' => undef, },
    { 'in' => [ 0, 1,10,10], 'out' => undef, },
    { 'in' => [ 0, 2,10,10], 'out' => undef, },
    { 'in' => [ 0,10,10,10], 'out' => undef, },
    { 'in' => [ 1, 0,10,10], 'out' => undef, },
    { 'in' => [ 2, 0,10,10], 'out' => undef, },
    { 'in' => [10, 0,10,10], 'out' => undef, },
    { 'in' => [ 1, 1,10,10], 'out' => "A:1", },
    { 'in' => [ 2, 2,10,10], 'out' => "B:2", },
    { 'in' => [ 3, 5,10,10], 'out' => "E:3", },
    { 'in' => [10,10,10,10], 'out' => "J:10", },
  );
  foreach my $datum (@test_data) {
    my ($i,$j, $c, $r) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = wtsi_clarity::epp::sm::worksheet::_get_location($i,$j, $c, $r);
    if (defined $expected){
      cmp_ok($val, 'eq', $expected, "_get_location($i, $j,...) should give $expected.");
    } else {
      is($val, undef, "_get_location($i, $j,...) should not give anything.");
    }
  }
}

{ # _get_legend_content
  my @test_data = (
    { 'in' => [ 0, 0,10,10], 'out' => "", },
    { 'in' => [ 0,11,10,10], 'out' => "", },
    { 'in' => [11, 0,10,10], 'out' => "", },
    { 'in' => [11,11,10,10], 'out' => "", },
    { 'in' => [ 0, 1,10,10], 'out' => ".\nA\n.", },
    { 'in' => [ 0, 2,10,10], 'out' => ".\nB\n.", },
    { 'in' => [ 0,10,10,10], 'out' => ".\nJ\n.", },
    { 'in' => [ 1, 0,10,10], 'out' => "1", },
    { 'in' => [ 2, 0,10,10], 'out' => "2", },
    { 'in' => [10, 0,10,10], 'out' => "10", },
    { 'in' => [ 1, 1,10,10], 'out' => undef, },
    { 'in' => [10,10,10,10], 'out' => undef, },
  );
  foreach my $datum (@test_data) {
    my ($i,$j, $c, $r) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = wtsi_clarity::epp::sm::worksheet::_get_legend_content($i,$j, $c, $r);

    if (defined $expected){
      cmp_ok($val, 'eq', $expected, "_get_legend_content($i, $j,...) should give the correct value.");
    } else {
      is($val, undef, "_get_legend_content($i, $j,...) should not give anything.");
    }

  }
}

{ # _get_table_data
  my @expected_data = (
    { 'in' => [0,0],  'out' => "", },
    { 'in' => [1,1],  'out' => "A:1\n2723\nv1 b8", },
    { 'in' => [0,1],  'out' => ".\nA\n.", },
    { 'in' => [0,2],  'out' => ".\nB\n.", },
    { 'in' => [6,2],  'out' => ".\nB\n.", },
    { 'in' => [1,0],  'out' => "1", },
    { 'in' => [3,0],  'out' => "3", },
  );
  my ($table, $prop) = wtsi_clarity::epp::sm::worksheet::_get_table_data($TEST_DATA->{'output_container_info'}->{'container_uri'}->{'container_details'}, 5,6);

  cmp_ok(scalar @{$table}, '==', 6+2 , "_get_table_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 5+2 , "_get_table_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i,$j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_table_data(...,$i, $j) should give the correct format.");
  }
}

{ # _get_containers_data
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/worksheet';
  my $step = wtsi_clarity::epp::sm::worksheet->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-102407');

  my $data = $step->_get_containers_data();
  my $container_uri = q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-8129};
  my $cont = $data->{'output_container_info'}->{$container_uri}->{'container_details'};
  my @expected_data = (
    { 'param' => 'D:1',
      'exp_location' => "B:2",
      'exp_sample_volume' => "1.2",
      'exp_buffer_volume' => "8.8",
      'exp_id' => "27-23",
      'exp_type' => "ABgene 0800",
    },
    { 'param' => 'D:3',
      'exp_location' => "B:1",
      'exp_sample_volume' => "1.2",
      'exp_buffer_volume' => "8.8",
      'exp_id' => "27-27",
      'exp_type' => "ABgene 0800",
    },
  );

  foreach my $datum (@expected_data) {
    my $out = $datum->{'param'};
    my $exp_loc = $datum->{'exp_location'};
    my $exp_smp = $datum->{'exp_sample_volume'};
    my $exp_buf = $datum->{'exp_buffer_volume'};
    my $exp_id  = $datum->{'exp_id'};
    my $exp_typ = $datum->{'exp_type'};
    my $in_loc  = $cont->{$out}->{'input_location'};
    my $in_smp  = $cont->{$out}->{'sample_volume'};
    my $in_buf  = $cont->{$out}->{'buffer_volume'};
    my $in_id   = $cont->{$out}->{'input_id'};
    my $in_type = $data->{'output_container_info'}->{$container_uri}->{'type'};
    cmp_ok($in_loc, 'eq', $exp_loc, "_get_containers_data(...) should give the correct relation $out <-> $exp_loc (found $in_loc). ");
    cmp_ok($in_smp, 'eq', $exp_smp, "_get_containers_data(...) should give the sample volume. $out <-> $exp_smp (found $in_smp)");
    cmp_ok($in_buf, 'eq', $exp_buf, "_get_containers_data(...) should give the buffer volume. $out <-> $exp_buf (found $in_buf)");
    cmp_ok($in_id,  'eq', $exp_id,  "_get_containers_data(...) should give the container id. $out <-> $exp_id (found $in_id)");
    cmp_ok($in_type,'eq', $exp_typ, "_get_containers_data(...) should give the container type. $out <-> $exp_typ (found $in_type)");
  }
}

{ # _get_cell_properties
  my @expected_data = (
    { 'pos' => "A:1",  'background_color' => "red", 'font_size' => '7' },
    { 'pos' => "A:2",  'background_color' => "green", 'font_size' => '7' },
    { 'pos' => "A:3",  'background_color' => "red", 'font_size' => '7' },
    { 'pos' => "A:4",  'background_color' => "blue", 'font_size' => '7' },
    { 'pos' => "A:5",  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => "B:1",  'background_color' => "red", 'font_size' => '7' },
    { 'pos' => "B:2",  'background_color' => "green", 'font_size' => '7' },
    { 'pos' => "B:3",  'background_color' => "green", 'font_size' => '7' },
    { 'pos' => "B:4",  'background_color' => "green", 'font_size' => '7' },
    { 'pos' => "B:5",  'background_color' => "green", 'font_size' => '7' },
  );

  my $colour_data = {'27' => 'red', '23' => 'green', '25' => 'blue'} ;

  foreach my $datum (@expected_data) {
    my $pos = $datum->{'pos'};

    my $prop = wtsi_clarity::epp::sm::worksheet::_get_cell_properties($TEST_DATA3->{'output_container_info'}->{'container_uri'}->{'container_details'}, $colour_data, $pos);

    my $exp_bg = $datum->{'background_color'};
    my $exp_fs = $datum->{'font_size'};
    my $bg = $prop->{'background_color'};
    my $fs = $prop->{'font_size'};
    cmp_ok($bg, 'eq', $exp_bg, "_get_cell_properties(...,$pos) {background_color} should give $exp_bg.");
    cmp_ok($fs, 'eq', $exp_fs, "_get_cell_properties(...,$pos) {font_size} should give $exp_fs.");
  }
}

{ # _get_colour_data
  my %expected_data = (
     '27' => "red" ,
     '23' => "green" ,
     '25' => "blue" ,
  );
  my @list_of_colours = ('red', 'green', 'blue', 'yellow', 'orange');

  my $cols = wtsi_clarity::epp::sm::worksheet::_get_colour_data($TEST_DATA3->{'output_container_info'}->{'container_uri'}->{'container_details'}, @list_of_colours);

  while (my ($id, $exp_col) = each %expected_data ) {
    my $found = $cols->{$id};
    cmp_ok($found, 'eq', $exp_col, "_get_colour_data(...) {$id} should give $exp_col.");
  }
}

{ # _get_title
  my $title = wtsi_clarity::epp::sm::worksheet::_get_title($TEST_DATA3, 'container_uri', "Cherrypicking");

  my $exp_title = q{Process PROCESS_ID - PLATE_PURPOSE_out - Cherrypicking};
  # my $found = $cols->{$id};
  cmp_ok($title, 'eq', $exp_title, "_get_title(...) should give $exp_title.");
}

{ # _get_legend_properties
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/worksheet';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::worksheet->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-102407');

  my @expected_data = (
    { 'pos' => [0,0],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [2,2],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [0,2],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [2,0],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [1,1],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [1,0],  'background_color' => "white", 'font_size' => '7' },
    { 'pos' => [0 ,1],  'background_color' => "white", 'font_size' => '7' },
  );

  foreach my $datum (@expected_data) {
    my ($i,$j) = @{$datum->{'pos'}};

    my $prop = wtsi_clarity::epp::sm::worksheet::_get_legend_properties($TEST_DATA, $i, $j, 1, 1);

    my $exp_bg = $datum->{'background_color'};
    my $exp_fs = $datum->{'font_size'};
    my $bg = $prop->{'background_color'};
    my $fs = $prop->{'font_size'};
    cmp_ok($bg, 'eq', $exp_bg, "_get_legend_properties(..., $i, $j) {background_color} should give $exp_bg.");
    cmp_ok($fs, 'eq', $exp_fs, "_get_legend_properties(..., $i, $j) {font_size} should give $exp_fs.");
  }
}

{ # _get_source_plate_data
  my @expected_data = (
    { 'in' => [0,0],  'out' => "Plate name", },
    { 'in' => [1,0],  'out' => "Barcode", },
    { 'in' => [2,0],  'out' => "Freezer", },
    { 'in' => [3,0],  'out' => "Shelf", },
    { 'in' => [4,0],  'out' => "Rack", },
    { 'in' => [5,0],  'out' => "Tray", },

    { 'in' => [0,1],  'out' => "PLATE_NAME23", },
    { 'in' => [1,1],  'out' => "00000023", },
    { 'in' => [2,1],  'out' => "000011", },
    { 'in' => [3,1],  'out' => "000012", },
    { 'in' => [4,1],  'out' => "000013", },
    { 'in' => [5,1],  'out' => "000014", },

    { 'in' => [0,2],  'out' => "PLATE_NAME25", },
    { 'in' => [1,2],  'out' => "00000025", },
    { 'in' => [2,2],  'out' => "000031", },
    { 'in' => [3,2],  'out' => "000032", },
    { 'in' => [4,2],  'out' => "000033", },
    { 'in' => [5,2],  'out' => "000034", },

    { 'in' => [0,3],  'out' => "PLATE_NAME27", },
    { 'in' => [1,3],  'out' => "00000027", },
    { 'in' => [2,3],  'out' => "000021", },
    { 'in' => [3,3],  'out' => "000022", },
    { 'in' => [4,3],  'out' => "000023", },
    { 'in' => [5,3],  'out' => "000024", },
  );
  my $table = wtsi_clarity::epp::sm::worksheet::_get_source_plate_data($TEST_DATA3, 'container_uri' );

  cmp_ok(scalar @{$table}, '==', 4 , "_get_source_plate_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 6 , "_get_source_plate_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i,$j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_source_plate_data(..., $i, $j) should give the correct content.");
  }
}


{ # _get_destination_plate_data
  my @expected_data = (
    { 'in' => [0,0],  'out' => "Plate name", },
    { 'in' => [1,0],  'out' => "Barcode", },
    { 'in' => [2,0],  'out' => "Wells", },

    { 'in' => [0,1],  'out' => "PLATE_NAME", },
    { 'in' => [1,1],  'out' => "1234567890123456", },
    { 'in' => [2,1],  'out' => "96", },
  );
  my $table = wtsi_clarity::epp::sm::worksheet::_get_destination_plate_data($TEST_DATA3, 'container_uri' );

  cmp_ok(scalar @{$table}, '==', 2 , "_get_destination_plate_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 3 , "_get_destination_plate_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i,$j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_destination_plate_data(..., $i, $j) should give the correct content.");
  }
}



1;
