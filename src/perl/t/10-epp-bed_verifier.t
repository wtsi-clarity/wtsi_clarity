use strict;
use warnings;
use Test::Exception;
use Test::More tests => 20;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};


use_ok('wtsi_clarity::epp::generic::bed_verifier');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433',
    step_name => 'working_dilution',
  );

  can_ok($process, qw/ run /);
}

# _extract_plate_number
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433',
    step_name => 'working_dilution',
  );

  is($process->_extract_bed_number('Bed 2 (Input Plate 1)'), '2', '1) Can extract the correct barcode from the udf string');
  is($process->_extract_bed_number('Bed 3 (Output Plate 1)'), '3', '2) Can extract the correct barcode from the udf string');
  is($process->_extract_bed_number('Bed 8 (Output Plate 1b)'), '8', '3) Can extract the correct barcode from the udf string (that has a letter in)');

  throws_ok { $process->_extract_bed_number('jibberish') } qr/Plate number not found\n/,
    'Throws an error when it can not find a number';
}

# _robot_barcode
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433',
    step_name => 'working_dilution',
  );

  is($process->_robot_barcode, '009851', 'Can extract the robot barcode from the process doc');

  # Note different process XML
  $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433_a',
    step_name => 'working_dilution',
  );

  throws_ok { $process->_robot_barcode() } qr/Robot ID must be set for bed verification\n/,
    'Throws an error when it can not find the Robot ID';
}

# _extract_plate_name
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433_b',
    step_name => 'working_dilution',
  );

  is($process->_extract_plate_name('Bed 2 (Input Plate 1)', 0), 'Input Plate 1', '1) Extracts the plate name correctly');
  is($process->_extract_plate_name('Bed 3 (Output Plate 1)', 0), 'Output Plate 1', '2) Extracts the plate name correctly');
  is($process->_extract_plate_name('Bed 14 (Output Plate 1a)', 0), 'Output Plate 1a', '3) Extracts the plate name correctly');
  is($process->_extract_plate_name('Bed 14 (Output Plate 1a)', 1), 'Output Plate 1', '3) Extracts the plate name correctly');

  throws_ok { $process->_extract_plate_name('nothing to extract here')} qr/Could not find matching plate name/,
    'Throws an error if it can not extract a plate name';
}

# _get_output_plate_from_input
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433_b',
    step_name => 'working_dilution',
  );

  my $output_plate = $process->_get_output_plate_from_input('Input Plate 1');
  isa_ok($output_plate, 'XML::LibXML::NodeList');

  throws_ok { $process->_get_output_plate_from_input('plate that does not exist') } qr/Could not find output plate/,
    'Throws an error if it can not find the matching output plate';

  my $process2 = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-103751',
    step_name   => 'working_dilution',
  );

  my $output_plates = $process2->_get_output_plate_from_input('Input Plate 1');
  isa_ok($output_plates, 'XML::LibXML::NodeList');
  is($output_plates->size(), 2, 'Gets the correct number of output plates');
}

# _bed_container_pairs
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/pico_green/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-103751',
    step_name => 'pico_assay_plate',
  );

  my @source = ({ bed => 6, barcode => 580030006666});
  my @destination = ({ bed => 7, barcode => 580030007670}, { bed => 8, barcode => 580030008684 });
  my @mappings = ({
    source => \@source,
    destination => \@destination
  });

  is_deeply($process->_bed_container_pairs, \@mappings, "Builds the bed container pairs correctly");

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-102433_c',
    step_name => 'working_dilution',
  );

  my @source1 = ({ bed => 2, barcode => 580040002672});
  my @destination1 = ({ bed => 3, barcode => 580040003686});
  my @source2 = ({ bed => 5, barcode => 580040005703});
  my @destination2 = ({ bed => 6, barcode => 580040006717});

  @mappings = ({
    source => \@source1,
    destination => \@destination1
  },{
    source => \@source2,
    destination => \@destination2,
  });

  is_deeply($process->_bed_container_pairs, \@mappings, "Builds bed container pairs correctly");

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/fluidigm_many_to_one/';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  $process = wtsi_clarity::epp::generic::bed_verifier->new(
    process_url => $base_uri . '/processes/24-103751',
    step_name => 'fludigm_192_24_ifc',
  );

  @source = ({ bed => 1, barcode => 580020001794}, {bed => 2, barcode => 580020002807 });
  @destination = ({ bed => 21, barcode => 580020021839});

  @mappings = ({
    source => \@source,
    destination => \@destination
  });

  is_deeply($process->_bed_container_pairs, \@mappings, "Builds bed container pairs correctly");
}