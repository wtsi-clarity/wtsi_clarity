use strict;
use warnings;
use Test::More tests => 170;
use Test::Exception;
use Test::MockObject::Extends;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;
use Data::Dumper;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::generic::worksheet_attacher', 'can use wtsi_clarity::epp::generic::worksheet_attacher' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

my $TEST_DATA = {
  'output_container_info' => {
    'container_uri' => {
      'container_details' => {
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
    'freezer' => '000021', 'shelf' => '0000022', 'rack' => '0000023', 'tray' => '0000024' },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA2 = {
  'output_container_info' => {
    'container_uri' => {
      'container_details' => {
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
    'freezer' => '000021', 'shelf' => '0000022', 'rack' => '0000023', 'tray' => '0000024' },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA3 = {
  'output_container_info' => {
    'container_uri' => {
      'container_details' => {
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
          'input_location' => 'D:8',
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
      'occ_wells' => '9',
      'type' => 'type1',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
    'freezer' => '000021', 'shelf' => '000022', 'rack' => '000023', 'tray' => '000024', 'type' => 'type27', },
    '25' => { 'purpose' => 'PLATE_PURPOSE_25', 'plate_name' => 'PLATE_NAME25', 'barcode' => '00000025', 'wells' => '25',
    'freezer' => '000031', 'shelf' => '000032', 'rack' => '000033', 'tray' => '000034', 'type' => 'type25',  },
    '23' => { 'purpose' => 'PLATE_PURPOSE_23', 'plate_name' => 'PLATE_NAME23', 'barcode' => '00000023', 'wells' => '23',
    'freezer' => '000011', 'shelf' => '000012', 'rack' => '000013', 'tray' => '000014', 'type' => 'type23',  },
  },
  'process_id' => 'PROCESS_ID',
};

my $TEST_DATA4 = {
  'output_container_info' => {
    'container_uri1' => {
      'container_details' => {
        'A:1' => {
          'input_location' => 'C:4',
          'sample_volume' => '1.2',
          'buffer_volume' => '8.8',
          'input_id' => '27',
          'input_uri' => '27',
        },
        'B:1' => {},
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME1',
      'barcode' => '12345678900001',
      'wells' => '96',
      'occ_wells' => '1',
      'type' => 'type1',
    },
    'container_uri2' => {
      'container_details' => {
        'A:1' => {
          'input_location' => 'B:2',
          'sample_volume' => '1.0',
          'buffer_volume' => '7.8',
          'input_id' => '29',
          'input_uri' => '29',
        },
      },
      'purpose' => 'PLATE_PURPOSE_out',
      'plate_name' => 'PLATE_NAME2',
      'barcode' => '12345678900002',
      'occ_wells' => '1',
      'wells' => '96',
      'type' => 'type1',
    },
  },
  'input_container_info' => {
    '27' => { 'purpose' => 'PLATE_PURPOSE_27', 'plate_name' => 'PLATE_NAME27', 'barcode' => '00000027', 'wells' => '27',
    'freezer' => '000021', 'shelf' => '000022', 'rack' => '000023', 'tray' => '000024', 'type' => 'type27', },
    '29' => { 'purpose' => 'PLATE_PURPOSE_29', 'plate_name' => 'PLATE_NAME29', 'barcode' => '00000029', 'wells' => '29',
    'freezer' => '000029', 'shelf' => '000029', 'rack' => '000029', 'tray' => '000029', 'type' => 'type29', },
  },
  'process_id' => 'PROCESS_ID',
  'user_first_name' => 'Le General',
  'user_last_name'  => 'de Castelnau',
};


{
  # _get_TECAN_file_content_per_URI
  my @expected_samples = (
    qq{A;00000027;;type27;27;;1.2\nD;1234567890123456;;type1;1;;1.2\nW;},
    qq{A;00000027;;type27;17;;1.2\nD;1234567890123456;;type1;2;;1.2\nW;},
    qq{A;00000023;;type23;41;;1.2\nD;1234567890123456;;type1;9;;1.2\nW;},
    qq{A;00000023;;type23;34;;1.2\nD;1234567890123456;;type1;10;;1.2\nW;},
    qq{A;00000027;;type27;57;;1.2\nD;1234567890123456;;type1;17;;1.2\nW;},
    qq{A;00000023;;type23;35;;1.2\nD;1234567890123456;;type1;18;;1.2\nW;},
    qq{A;00000025;;type25;60;;1.2\nD;1234567890123456;;type1;25;;1.2\nW;},
    qq{A;00000023;;type23;37;;1.2\nD;1234567890123456;;type1;26;;1.2\nW;},
    qq{A;00000023;;type23;45;;1.2\nD;1234567890123456;;type1;34;;1.2\nW;},
  );
  my @expected_buffers = (
    qq{A;BUFF;;96-TROUGH;27;;8.8\nD;1234567890123456;;type1;1;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;17;;8.8\nD;1234567890123456;;type1;2;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;41;;8.8\nD;1234567890123456;;type1;9;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;34;;8.8\nD;1234567890123456;;type1;10;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;57;;8.8\nD;1234567890123456;;type1;17;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;35;;8.8\nD;1234567890123456;;type1;18;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;60;;8.8\nD;1234567890123456;;type1;25;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;37;;8.8\nD;1234567890123456;;type1;26;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;45;;8.8\nD;1234567890123456;;type1;34;;8.8\nW;},
  );

  my $worksheet_attacher = wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  );

  my ($samples, $buffers) = $worksheet_attacher->_get_TECAN_file_content_per_URI($TEST_DATA3, 'container_uri' );
  cmp_ok(scalar @$samples, '==', 9, "_get_TECAN_file_content_per_URI should return the correct size nb of samples.");
  cmp_ok(scalar @$buffers, '==', 9, "_get_TECAN_file_content_per_URI should return the correct size nb of buffers.");

  foreach my $expected (@expected_samples) {
    my $val = shift @$samples;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content_per_URI(...) should give the correct samples.");
  }

  foreach my $expected (@expected_buffers) {
    my $val = shift @$buffers;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content_per_URI(...) should give the correct buffers.");
  }
}

{
  # _get_TECAN_file_content
  my @expected_data = (
    qq{C;},
    qq{C; benoit},
    qq{C;},
    qq{A;00000027;;type27;27;;1.2\nD;12345678900001;;type1;1;;1.2\nW;},
    qq{A;00000029;;type29;10;;1.0\nD;12345678900002;;type1;1;;1.0\nW;},

    qq{A;BUFF;;96-TROUGH;27;;8.8\nD;12345678900001;;type1;1;;8.8\nW;},
    qq{A;BUFF;;96-TROUGH;10;;7.8\nD;12345678900002;;type1;1;;7.8\nW;},

    qq{C;},
    qq{C; SRC1 = 00000027},
    qq{C; SRC2 = 00000029},
    qq{C;},
    qq{C; DEST1 = 12345678900001},
    qq{C; DEST2 = 12345678900002},
    qq{C;},

  );

  my $worksheet_attacher = wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  );

  my $table = $worksheet_attacher->_get_TECAN_file_content($TEST_DATA4, 'benoit');
  cmp_ok(scalar @$table, '==', 3 + 4 + 2 * 2 + 3, "_get_TECAN_file_content should return an array of the correct size (nb of rows).");

  foreach my $expected (@expected_data) {
    my $val = shift @$table;
    cmp_ok($val, 'eq', $expected, "_get_TECAN_file_content(...) should give the correct content.");
  }
}

{
  # testing _get_location
  my @test_data = (
    { 'in' => [ 0,  0], 'out' => undef, },
    { 'in' => [ 0, 11], 'out' => undef, },
    { 'in' => [11,  0], 'out' => undef, },
    { 'in' => [11, 11], 'out' => undef, },
    { 'in' => [ 0,  1], 'out' => undef, },
    { 'in' => [ 0,  2], 'out' => undef, },
    { 'in' => [ 0, 10], 'out' => undef, },
    { 'in' => [ 1,  0], 'out' => undef, },
    { 'in' => [ 2,  0], 'out' => undef, },
    { 'in' => [10,  0], 'out' => undef, },
    { 'in' => [ 1,  1], 'out' => "A:1", },
    { 'in' => [ 2,  2], 'out' => "B:2", },
    { 'in' => [ 3,  5], 'out' => "E:3", },
    { 'in' => [ 5,  5], 'out' => "E:5", },
  );
  foreach my $datum (@test_data) {
    my ($i, $j, $c, $r) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = wtsi_clarity::epp::generic::worksheet_attacher::_get_location($i, $j, $c, $r);
    if (defined $expected) {
      cmp_ok($val, 'eq', $expected, "_get_location($i, $j,...) should give $expected.");
    } else {
      is($val, undef, "_get_location($i, $j,...) should not give anything.");
    }
  }
}

{
  # _get_legend_content
  my @test_data = (
    { 'in' => [ 0,  0], 'out' => "", },
    { 'in' => [ 0, 11], 'out' => "", },
    { 'in' => [15,  0], 'out' => "", },
    { 'in' => [15, 15], 'out' => "", },
    { 'in' => [ 0,  1], 'out' => ".\nA\n.", },
    { 'in' => [ 0,  2], 'out' => ".\nB\n.", },
    { 'in' => [ 0,  5], 'out' => ".\nE\n.", },
    { 'in' => [ 1,  0], 'out' => "1", },
    { 'in' => [ 2,  0], 'out' => "2", },
    { 'in' => [10,  0], 'out' => "10", },
    { 'in' => [ 1,  1], 'out' => undef, },
    { 'in' => [12,  8], 'out' => undef, },
  );
  foreach my $datum (@test_data) {
    my ($i, $j, $c, $r) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = wtsi_clarity::epp::generic::worksheet_attacher::_get_legend_content($i, $j);

    if (defined $expected) {
      cmp_ok($val, 'eq', $expected, "_get_legend_content($i, $j,...) should give the correct value.");
    } else {
      is($val, undef, "_get_legend_content($i, $j,...) should not give anything.");
    }

  }
}

{
  # _get_table_data
  my @expected_data = (
    { 'in' => [ 0, 0], 'out' => "", },
    { 'in' => [ 1, 1], 'out' => "A:1\n2723\nv2 b9", },
    { 'in' => [ 0, 1], 'out' => ".\nA\n.", },
    { 'in' => [ 0, 2], 'out' => ".\nB\n.", },
    { 'in' => [13, 2], 'out' => ".\nB\n.", },
    { 'in' => [ 1, 0], 'out' => "1", },
    { 'in' => [ 3, 0], 'out' => "3", },
  );
  my ($table, $prop) = wtsi_clarity::epp::generic::worksheet_attacher::_get_table_data($TEST_DATA->{'output_container_info'}->{'container_uri'}->{'container_details'});

  cmp_ok(scalar @{$table}, '==', 8 + 2, "_get_table_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 12 + 2, "_get_table_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i, $j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_table_data(...,$i, $j) should give the correct format.");
  }
}

{
  # _get_containers_data
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/worksheet_attacher';
  my $step = wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  );

  my $data = $step->_get_containers_data();

  my @input_uris = qw{http://testserver.com:1234/here/containers/27-23 http://testserver.com:1234/here/containers/27-27};

  my $container_uri = q{http://testserver.com:1234/here/containers/27-8129};
  my $cont = $data->{'output_container_info'}->{$container_uri}->{'container_details'};

  my @expected_out_data = (
    { 'param' => 'D:1',
    'exp_location' => "B:2",
    'exp_sample_volume' => "1.2",
    'exp_buffer_volume' => "8.8",
    'exp_id' => "7020",
    'exp_type' => "ABgene 0800",
    },
    { 'param' => 'D:3',
    'exp_location' => "B:1",
    'exp_sample_volume' => "1.2",
    'exp_buffer_volume' => "8.8",
    'exp_id' => "273251",
    'exp_type' => "ABgene 0800",
    },
  );
  my $expected_plate_purpose = q{PLATE_PURPOSE_TEST};
  my %expected_plate_name = (
    $base_uri . '/containers/27-23' => '7020',
    $base_uri . '/containers/27-27' => '273251',
  );

  foreach my $datum (@expected_out_data) {
    my $out = $datum->{'param'};
    my $exp_loc = $datum->{'exp_location'};
    my $exp_smp = $datum->{'exp_sample_volume'};
    my $exp_buf = $datum->{'exp_buffer_volume'};
    my $exp_id = $datum->{'exp_id'};
    my $exp_typ = $datum->{'exp_type'};
    my $in_loc = $cont->{$out}->{'input_location'};
    my $in_smp = $cont->{$out}->{'sample_volume'};
    my $in_buf = $cont->{$out}->{'buffer_volume'};
    my $in_id = $cont->{$out}->{'input_id'};
    my $in_type = $data->{'output_container_info'}->{$container_uri}->{'type'};
    cmp_ok($in_loc, 'eq', $exp_loc, qq{_get_containers_data(...) should give the correct relation $out <-> $exp_loc (found $in_loc) });
    cmp_ok($in_smp, 'eq', $exp_smp, qq{_get_containers_data(...) should give the sample volume.   $out <-> $exp_smp (found $in_smp) });
    cmp_ok($in_buf, 'eq', $exp_buf, qq{_get_containers_data(...) should give the buffer volume.   $out <-> $exp_buf (found $in_buf) });
    cmp_ok($in_id, 'eq', $exp_id, qq{_get_containers_data(...) should give the container id.    $out <-> $exp_id  (found $in_id)  });
    cmp_ok($in_type, 'eq', $exp_typ, qq{_get_containers_data(...) should give the container type.  $out <-> $exp_typ (found $in_type)});
  }

  cmp_ok($data->{'output_container_info'}->{$container_uri}->{'wells'}, 'eq', 96, "_get_containers_data(...) should give the correct nb of wells");
  cmp_ok($data->{'output_container_info'}->{$container_uri}->{'occ_wells'}, 'eq', 73, "_get_containers_data(...) should give the correct occupied wells");

  foreach my $input_uri (@input_uris) {
    cmp_ok($data->{'input_container_info'}->{$input_uri}->{'purpose'}, 'eq', $expected_plate_purpose, "_get_containers_data(...) should give the correct plate purpose");
    cmp_ok($data->{'input_container_info'}->{$input_uri}->{'plate_name'}, 'eq', $expected_plate_name{$input_uri}, "_get_containers_data(...) should give the correct barcode of the plate");
  }
}

{
  # _get_cell_properties
  my @expected_data = (
    { 'pos' => "A:1", 'style' => "COLOUR_0", },
    { 'pos' => "A:2", 'style' => "COLOUR_1", },
    { 'pos' => "A:3", 'style' => "COLOUR_0", },
    { 'pos' => "A:4", 'style' => "COLOUR_2", },
    { 'pos' => "A:5", 'style' => "EMPTY_STYLE", },
    { 'pos' => "B:1", 'style' => "COLOUR_0",  },
    { 'pos' => "B:2", 'style' => "COLOUR_1",  },
    { 'pos' => "B:3", 'style' => "COLOUR_1",  },
    { 'pos' => "B:4", 'style' => "COLOUR_1",  },
    { 'pos' => "B:5", 'style' => "COLOUR_1",  },
  );

  my $colour_data = {'27' => 0, '23' => 1, '25' => 2};

  foreach my $datum (@expected_data) {
    my $pos = $datum->{'pos'};
    my $container_details = $TEST_DATA3->{'output_container_info'}->{'container_uri'}->{'container_details'};
    my $prop = wtsi_clarity::epp::generic::worksheet_attacher::_get_cell_properties($container_details, $colour_data, $pos);

    my $exp_style = $datum->{'style'};

    cmp_ok($prop, 'eq', $exp_style, "_get_cell_properties(...,$pos) {style} should give $exp_style.");
  }
}

{
  # _get_colour_indexes
  my %expected_data = (
    '27' => 0,
    '23' => 1,
    '25' => 2,
  );

  my $cols = wtsi_clarity::epp::generic::worksheet_attacher::_get_colour_indexes($TEST_DATA3->{'output_container_info'}->{'container_uri'}->{'container_details'});

  while (my ($id, $exp_col) = each %expected_data ) {
    my $found = $cols->{$id};
    cmp_ok($found, 'eq', $exp_col, "_get_colour_indexes(...) {$id} should give $exp_col.");
  }
}

{
  # _get_title
  my $title = wtsi_clarity::epp::generic::worksheet_attacher::_get_title($TEST_DATA3, 'container_uri', "Cherrypicking");

  my $exp_title = q{Process PROCESS_ID - PLATE_PURPOSE_27 -> PLATE_PURPOSE_out};
  cmp_ok($title, 'eq', $exp_title, "_get_title(...) should give $exp_title.");
}

{
  # _get_legend_properties
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/worksheet_attacher';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  );

  my @expected_data = (
    { 'pos' => [0, 0], 'style' => 'HEADER_STYLE'},
    { 'pos' => [2, 2], 'style' => 'HEADER_STYLE'},
    { 'pos' => [0, 2], 'style' => 'HEADER_STYLE'},
    { 'pos' => [2, 0], 'style' => 'HEADER_STYLE'},
    { 'pos' => [1, 1], 'style' => 'HEADER_STYLE'},
    { 'pos' => [1, 0], 'style' => 'HEADER_STYLE'},
    { 'pos' => [0, 1], 'style' => 'HEADER_STYLE' },
  );

  foreach my $datum (@expected_data) {
    my ($i, $j) = @{$datum->{'pos'}};

    my $prop = wtsi_clarity::epp::generic::worksheet_attacher::_get_legend_properties();

    my $expected = $datum->{'style'};
    cmp_ok($prop, 'eq', $expected, "_get_legend_properties() {style} should give $expected.");
  }
}

{
  # _get_source_plate_data
  my @expected_data = (
    { 'in' => [0, 0], 'out' => "Plate name", },
    { 'in' => [1, 0], 'out' => "Barcode", },
    { 'in' => [2, 0], 'out' => "Freezer", },
    { 'in' => [3, 0], 'out' => "Shelf", },
    { 'in' => [4, 0], 'out' => "Rack", },
    { 'in' => [5, 0], 'out' => "Tray", },

    { 'in' => [0, 1], 'out' => "PLATE_NAME23", },
    { 'in' => [1, 1], 'out' => "00000023", },
    { 'in' => [2, 1], 'out' => "000011", },
    { 'in' => [3, 1], 'out' => "000012", },
    { 'in' => [4, 1], 'out' => "000013", },
    { 'in' => [5, 1], 'out' => "000014", },

    { 'in' => [0, 2], 'out' => "PLATE_NAME25", },
    { 'in' => [1, 2], 'out' => "00000025", },
    { 'in' => [2, 2], 'out' => "000031", },
    { 'in' => [3, 2], 'out' => "000032", },
    { 'in' => [4, 2], 'out' => "000033", },
    { 'in' => [5, 2], 'out' => "000034", },

    { 'in' => [0, 3], 'out' => "PLATE_NAME27", },
    { 'in' => [1, 3], 'out' => "00000027", },
    { 'in' => [2, 3], 'out' => "000021", },
    { 'in' => [3, 3], 'out' => "000022", },
    { 'in' => [4, 3], 'out' => "000023", },
    { 'in' => [5, 3], 'out' => "000024", },
  );
  my $table = wtsi_clarity::epp::generic::worksheet_attacher::_get_source_plate_data($TEST_DATA3, 'container_uri' );

  cmp_ok(scalar @{$table}, '==', 4, "_get_source_plate_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 6, "_get_source_plate_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i, $j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_source_plate_data(..., $i, $j) should give the correct content.");
  }
}


{
  # _get_destination_plate_data
  my @expected_data = (
    { 'in' => [0, 0], 'out' => "Plate name", },
    { 'in' => [1, 0], 'out' => "Barcode", },
    { 'in' => [2, 0], 'out' => "Wells", },

    { 'in' => [0, 1], 'out' => "PLATE_NAME", },
    { 'in' => [1, 1], 'out' => "1234567890123456", },
    { 'in' => [2, 1], 'out' => "9", },
  );
  my $table = wtsi_clarity::epp::generic::worksheet_attacher::_get_destination_plate_data($TEST_DATA3, 'container_uri' );

  cmp_ok(scalar @{$table}, '==', 2, "_get_destination_plate_data should return an array of the correct size (nb of rows).");
  cmp_ok(scalar @{@{$table}[0]}, '==', 3, "_get_destination_plate_data should return an array of the correct size (nb of cols).");

  foreach my $datum (@expected_data) {
    my ($i, $j) = @{$datum->{'in'}};
    my $expected = $datum->{'out'};
    my $val = $table->[$j][$i];
    cmp_ok($val, 'eq', $expected, "_get_destination_plate_data(..., $i, $j) should give the correct content.");
  }
}

{
  # _get_username
  my $string = wtsi_clarity::epp::generic::worksheet_attacher::_get_username($TEST_DATA4, 'api' );
  cmp_ok($string, 'eq', 'Le General de Castelnau (via api)', "_get_username should return the correct value.");
}

{
  # _get_pdf_data
  my $expected = {
    'stamp' => 'my stamp',
    'pages' => [
      {
        'title' => 'Process PROCESS_ID - PLATE_PURPOSE_29 -> PLATE_PURPOSE_out',
        'input_table' => [['Plate name', 'Barcode', 'Freezer', 'Shelf', 'Rack', 'Tray'],
        ['PLATE_NAME29', '00000029', '000029', '000029', '000029', '000029' ]],
        'input_table_title' => 'Source plates',
        'output_table' => [['Plate name', 'Barcode', 'Wells'],
        ['PLATE_NAME2', '12345678900002', '1']],
        'output_table_title' => 'Destination plates',
        'plate_table' => [['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ''],
        [".\nA\n.", "B:2\n29\nv1 b8", '', '', '', '', '', '', '', '', '', '', '', ".\nA\n."],
        [".\nB\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nB\n."],
        [".\nC\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nC\n."],
        [".\nD\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nD\n."],
        [".\nE\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nE\n."],
        [".\nF\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nF\n."],
        [".\nG\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nG\n."],
        [".\nH\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nH\n."],
        ['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ''],
        ],
        'plate_table_title' => 'Required buffer',
        'plate_table_cell_styles' => [
          ['HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'COLOUR_0', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE',],
        ],
      },
      {
        'title' => 'Process PROCESS_ID - PLATE_PURPOSE_27 -> PLATE_PURPOSE_out',
        'input_table' => [['Plate name', 'Barcode', 'Freezer', 'Shelf', 'Rack', 'Tray'],
        ['PLATE_NAME27', '00000027', '000021', '000022', '000023', '000024' ]],
        'input_table_title' => 'Source plates',
        'output_table' => [['Plate name', 'Barcode', 'Wells'],
        ['PLATE_NAME1', '12345678900001', '1']],
        'output_table_title' => 'Destination plates',
        'plate_table' => [['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ''],
        [".\nA\n.", "C:4\n27\nv2 b9", '', '', '', '', '', '', '', '', '', '', '', ".\nA\n."],
        [".\nB\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nB\n."],
        [".\nC\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nC\n."],
        [".\nD\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nD\n."],
        [".\nE\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nE\n."],
        [".\nF\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nF\n."],
        [".\nG\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nG\n."],
        [".\nH\n.", '', '', '', '', '', '', '', '', '', '', '', '', ".\nH\n."],
        ['', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, ''],
        ],
        'plate_table_title' => 'Required buffer',
        'plate_table_cell_styles' => [
          ['HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'COLOUR_0', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'EMPTY_STYLE', 'HEADER_STYLE',],
          ['HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE', 'HEADER_STYLE',],
        ],
      },
    ]
  };

  my $pdf_data = wtsi_clarity::epp::generic::worksheet_attacher::_get_pdf_data($TEST_DATA4, 'my stamp', {'action_title' => 'Cherrypicking'} );

  cmp_ok( $pdf_data->{'stamp'}, 'eq', $expected->{'stamp'}, "_get_pdf_data() should give the correct stamp.");
  cmp_ok( scalar @{$pdf_data->{'pages'}}, '==', 2, "_get_pdf_data() should give the correct number of pages.");
  my $page0 = @{$pdf_data->{'pages'}}[0];
  my $exp_page0 = @{$expected->{'pages'}}[0];

  foreach my $key (qw{title input_table_title output_table_title plate_table_title}) {
    cmp_ok( $page0->{$key}, 'eq', $exp_page0->{$key}, "_get_pdf_data() should give the correct $key.");
  }

  is_deeply( $page0->{'input_table'}, $exp_page0->{'input_table'}, "input_table from _get_pdf_data() should be correct.");
  is_deeply( $page0->{'output_table'}, $exp_page0->{'output_table'}, "output_table from _get_pdf_data() should be correct.");

  is_deeply( $page0->{'plate_table'}, $exp_page0->{'plate_table'}, "plate_table from _get_pdf_data() should be correct.");
  is_deeply( $page0->{'plate_table_cell_styles'}, $exp_page0->{'plate_table_cell_styles'}, "plate_table_cell_styles from _get_pdf_data() should be correct.");

  my $page1 = @{$pdf_data->{'pages'}}[1];
  my $exp_page1 = @{$expected->{'pages'}}[1];

  foreach my $key (qw{title input_table_title output_table_title plate_table_title}) {
    cmp_ok( $page1->{$key}, 'eq', $exp_page1->{$key}, "_get_pdf_data() should give the correct $key.");
  }

  is_deeply( $page1->{'input_table'}, $exp_page1->{'input_table'}, "input_table from _get_pdf_data() should be correct.");
  is_deeply( $page1->{'output_table'}, $exp_page1->{'output_table'}, "output_table from _get_pdf_data() should be correct.");

  is_deeply( $page1->{'plate_table'}, $exp_page1->{'plate_table'}, "plate_table from _get_pdf_data() should be correct.");
  is_deeply( $page1->{'plate_table_cell_styles'}, $exp_page1->{'plate_table_cell_styles'}, "plate_table_cell_styles from _get_pdf_data() should be correct.");
}

{
  is(wtsi_clarity::epp::generic::worksheet_attacher::_is_integer(1), 1, 'Correct verifies 1 is an integer');
  is(wtsi_clarity::epp::generic::worksheet_attacher::_is_integer(1000), 1, 'Correct verifies 1000 is an integer');
  is(wtsi_clarity::epp::generic::worksheet_attacher::_is_integer('A:1'), 0, 'Correct verifies A:1 is not an integer');
  is(wtsi_clarity::epp::generic::worksheet_attacher::_is_integer(8.3), 0, 'Correct verifies 8.3 is not an integer');
  is(wtsi_clarity::epp::generic::worksheet_attacher::_is_integer([1, 2, 3]), 0, 'Correct verifies an array ref is not an integer');
}

{
  my $worksheet_attacher = Test::MockObject::Extends->new( wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  ));

  $worksheet_attacher->mock(q{_get_well_position}, sub {
    return 1.5;
  });

  throws_ok {
    $worksheet_attacher->_get_TECAN_file_content_per_URI($TEST_DATA3, 'container_uri');
  }
    qr/Output location is not an integer: 1.5/,
    "Throws an error when well mapper does return an integer";
}

{

  my $worksheet_attacher = Test::MockObject::Extends->new( wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-102407',
    worksheet_type => 'cherrypicking',
    worksheet_filename => 'xxxxx_worksheet.pdf',
    tecan_filename => 'xxxxx_tecan.gwl',
  ));

  my $i = 0;
  $worksheet_attacher->mock(q{_get_well_position}, sub {
    if ($i == 0) {
      $i++;
      return 1;
    } else {
      return 4.5;
    }
  });

  throws_ok {
    $worksheet_attacher->_get_TECAN_file_content_per_URI($TEST_DATA3, 'container_uri');
  }
    qr/Input location is not an integer: 4.5/,
    "Throws an error when well mapper does return an integer";
}

# No buffer lines if buffer is empty
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/worksheet_attacher/no_buffers';

  my $worksheet_attacher = wtsi_clarity::epp::generic::worksheet_attacher->new(
    process_url => $base_uri . '/processes/24-26963',
    worksheet_filename => 'blah.pdf',
    worksheet_type => 'fluidigm',
    tecan_filename => 'blah.gwl',
  );

  my $containers_data = {
    'user_first_name' => 'Christopher',
    'process_id' => '2426963',
    'output_container_info' => {
      $base_uri . '/containers/27-4345' => {
        'container_details' => {
          'A:2' => {
            'input_location' => 'B:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'C:1' => {
            'input_location' => 'C:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'G:1' => {
            'input_location' => 'F:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'G:2' => {
            'input_location' => 'D:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'A:1' => {
            'input_location' => 'H:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'H:1' => {
            'input_location' => 'G:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'C:2' => {
            'input_location' => 'A:2',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'A:3' => {
            'input_location' => 'H:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'E:1' => {
            'input_location' => 'B:2',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'D:2' => {
            'input_location' => 'A:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'B:2' => {
            'input_location' => 'A:2',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'B:1' => {
            'input_location' => 'A:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'F:2' => {
            'input_location' => 'F:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'D:1' => {
            'input_location' => 'E:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'C:3' => {
            'input_location' => 'C:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'H:2' => {
            'input_location' => 'B:2',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'F:1' => {
            'input_location' => 'D:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4304',
            'input_uri' => $base_uri . '/containers/27-4304'
          },
          'E:2' => {
            'input_location' => 'E:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'B:3' => {
            'input_location' => 'G:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          },
          'D:3' => {
            'input_location' => 'B:1',
            'sample_volume' => '1.25',
            'buffer_volume' => 0,
            'input_id' => '27-4330',
            'input_uri' => $base_uri . '/containers/27-4330'
          }
        },
        'plate_name' => '274345',
        'purpose' => 'Unknown',
        'type' => 'ABgene 0800',
        'barcode' => '5260274330776',
        'occ_wells' => 20,
        'wells' => 96
      }
    },
    'user_last_name' => 'Smith',
    'input_container_info' => {
      $base_uri . '/containers/27-4330' => {
        'freezer' => 'Unknown',
        'purpose' => 'Working Dilution',
        'tray' => 'Unknown',
        'barcode' => '5260274330776',
        'shelf' => 'Unknown',
        'rack' => 'Unknown',
        'plate_name' => '274330',
        'type' => 'ABgene 0800'
      },
      $base_uri . '/containers/27-4304' => {
        'freezer' => 'Unknown',
        'purpose' => 'Working Dilution',
        'tray' => 'Unknown',
        'barcode' => '5260274304753',
        'shelf' => 'Unknown',
        'rack' => 'Unknown',
        'plate_name' => '274304',
        'type' => 'ABgene 0800'
      }
    }
  };
  my ($sample_output, $buffer_output) = $worksheet_attacher->_get_TECAN_file_content_per_URI($containers_data, $base_uri . '/containers/27-4345');

  is_deeply($buffer_output, [], 'Buffer output is empty array when buffer volume is 0');
}

1;
