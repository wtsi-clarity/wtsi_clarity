use strict;
use warnings;
use Test::Exception;
use Test::More tests => 19;
use JSON;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::sm::cp_bed_verification');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  can_ok($process, qw/ run /);
}

# Robot ID
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  is($process->_robot_id, '014296', 'Extracts the robot_id correctly');

  $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741_a',
  );

  throws_ok { $process->_robot_id } qr/Robot ID must be set first/, 
    'Throws an error when it can not find the Robot ID';
}

# Ouput Limsid
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  is($process->_output_limsid, '92-699696', 'Extracts the first output limsid correctly');

  $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741_a',
  );

  throws_ok { $process->_output_limsid } qr/Can not find output/, 
    'Throws an error when it can not find the limsid of the first output';
}

# Process Limsid
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  is($process->_process_limsid, '24-104741', 'Extracts the process limsid correctly');
}

# UDF Beds
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  my %result = (
    'Bed 1' => '930020001650',
    'Bed 21' => '930020021696'
  );

  is_deeply($process->_udf_beds, \%result, 'Creates the udf beds hash correctly');
}

# UDF Plates
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  my %result = (
    'Plate 1' => '5260275757817',
    'Plate 21' => '27-7557'
  );

  is_deeply($process->_udf_plates, \%result, 'Creates the udf plates hash correctly');
}

# Input Limsid
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
  );

  is($process->_input_limsid, '2-665711', 'Extracts the limsid of the first input');
}

# File input_output
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
    _tecan_file => 't/data/sm/bed_verification/cherrypick/tecan.gwl',
  );

  my %result = (
    "SCRC1" => "1220332271865",
    "SCRC2" => "1220332272879",
    "DEST1" => "1220345864764",
  );
  is_deeply($process->_file_input_output, \%result, "Creates the file_input_output correctly");
}

# Plate Bed Map
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  open( my $fh, '<:encoding(UTF-8)', 't/data/config/tecan_beds.json' );
  local $/;
  my $json_text = <$fh>;
  my $config = decode_json($json_text);

  my %file_input_output = (
    "SCRC1" => "1220332271865",
    "SCRC2" => "1220332272879",
    "DEST1" => "1220345864764",
  );

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
    _tecan_bed_config => $config,
    _file_input_output => \%file_input_output,
    _robot_id => '014296'
  );

  my @result = (
    {
      'bed' => 21,
      'plate_barcode' => '1220345864764',
      'barcode' => '930020021696'
    },
    {
      'bed' => 2,
      'plate_barcode' => '1220332272879',
      'barcode' => '930020002664'
    },
    {
      'bed' => 1,
      'plate_barcode' => '1220332271865',
      'barcode' => '930020001650'
    }
  );

  is_deeply($process->_plate_bed_map, \@result, "Creates the plate_bed_map correctly");

  $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
    _tecan_bed_config => $config,
    _file_input_output => \%file_input_output,
    _robot_id => '123456789' # False robot id
  );

  throws_ok { $process->_plate_bed_map } qr/Could not find tecan config for robot 123456789/, 
    'Throws an error when the robot id does not exist in the config';

  delete $config->{'014296'}{'beds'}{'SCRC1'};

  $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741',
    _tecan_bed_config => $config,
    _file_input_output => \%file_input_output,
    _robot_id => '014296'
  );

  throws_ok { $process->_plate_bed_map } qr/Could not find config for plate SCRC1/, 
    'Throws an error when the config does not exist for a plate';
}

# Validate
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification/cherrypick/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::cp_bed_verification->new(
    process_url => $base_uri . '/processes/24-104741'
  );

  my $test_input = {
    "plate_bed_map" => [
      {
        'bed' => 21,
        'plate_barcode' => '1220345864764',
        'barcode' => '930020021696'
      },
      {
        'bed' => 1,
        'plate_barcode' => '1220332271865',
        'barcode' => '930020001650'
      }
    ],
    "udf_beds" => {
      'Bed 1' => '930020001650',
      'Bed 21' => '930020021696'
    },
    "udf_plates" => {
      'Plate 1' => '1220332271865',
      'Plate 21' => '1220345864764'
    }
  };

  is($process->validate($test_input->{"plate_bed_map"}, $test_input->{"udf_beds"}, $test_input->{"udf_plates"}), 1, "Validates the whole process correctly");
  
  my @expected = (
    {
      "plate_bed_map" => [
        {
          'bed' => 21,
          'plate_barcode' => '1220345864764',
          'barcode' => '930020021696'
        },
        {
          'bed' => 1,
          'plate_barcode' => '1220332271865',
          'barcode' => '930020001650'
        }
      ],
      "udf_beds" => {
        'Bed 1234' => '930020001650',
        'Bed 21' => '930020021696'
      },
      "udf_plates" => {
        'Plate 1' => '1220332271865',
        'Plate 21' => '1220345864764'
      },
      "error_message" => "Could not find Bed 1",
      "test_name" => "throws an error when a bed udf can not be found"
    },
    {
      "plate_bed_map" => [
        {
          'bed' => 21,
          'plate_barcode' => '1220345864764',
          'barcode' => '930020021696'
        },
        {
          'bed' => 1,
          'plate_barcode' => '1220332271865',
          'barcode' => '930020001650'
        }
      ],
      "udf_beds" => {
        'Bed 1' => '930020001650',
        'Bed 21' => '930020021696222222' # <---- For example if use scans wrong barcode
      },
      "udf_plates" => {
        'Plate 1' => '1220332271865',
        'Plate 21' => '1220345864764'
      },
      "error_message" => "Bed 21 barcode should be 930020021696",
      "test_name" => "throws an error when a bed barcode is wrong"
    },
    {
      "plate_bed_map" => [
        {
          'bed' => 21,
          'plate_barcode' => '1220345864764',
          'barcode' => '930020021696'
        },
        {
          'bed' => 1,
          'plate_barcode' => '1220332271865',
          'barcode' => '930020001650'
        }
      ],
      "udf_beds" => {
        'Bed 1' => '930020001650',
        'Bed 21' => '930020021696'
      },
      "udf_plates" => {
        'Plate 1234' => '1220332271865',
        'Plate 21' => '1220345864764'
      },
      "error_message" => "Could not find Plate 1",
      "test_name" => "throws an error when a plate udf can not be found"
    },
    {
      "plate_bed_map" => [
        {
          'bed' => 21,
          'plate_barcode' => '1220345864764',
          'barcode' => '930020021696'
        },
        {
          'bed' => 1,
          'plate_barcode' => '1220332271865',
          'barcode' => '930020001650'
        }
      ],
      "udf_beds" => {
        'Bed 1' => '930020001650',
        'Bed 21' => '930020021696'
      },
      "udf_plates" => {
        'Plate 1' => '1220332271865789456', # <---- For example if wrong plate is scanned in
        'Plate 21' => '1220345864764'
      },
      "error_message" => "Plate barcode in Bed 1 should be equal to 1220332271865",
      "test_name" => "throws an error when an incorrect plate has been scanned in"
    },
  );

  foreach my $input (@expected) {
    throws_ok { $process->validate($input->{"plate_bed_map"}, $input->{"udf_beds"}, $input->{"udf_plates"}) } qr/$input->{"error_message"}/,
      $input->{"test_name"};
  }
}