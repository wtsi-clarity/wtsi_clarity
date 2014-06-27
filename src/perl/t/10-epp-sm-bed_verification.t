use strict;
use warnings;
use Test::Exception;
use Test::More tests => 15;

use_ok('wtsi_clarity::epp::sm::bed_verification');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433',
    step_name => 'working_dilution',
  );

  can_ok($process, qw/ run /);
}

# _extract_plate_number
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433',
    step_name => 'working_dilution',
  );

  is($process->_extract_plate_number('Bed 2 (Input Plate 1)'), '2', '1) Can extract the correct barcode from the udf string');
  is($process->_extract_plate_number('Bed 3 (Output Plate 1)'), '3', '2) Can extract the correct barcode from the udf string');
  throws_ok { $process->_extract_plate_number('jibberish') } qr/Plate number not found\n/, 
    'Throws an error when it can not find a number';
}

# _robot_barcode
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433',
    step_name => 'working_dilution',
  );

  is($process->_robot_barcode(), '009851', 'Can extract the robot barcode from the process doc');

  # Note different process XML
  $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433_a',
    step_name => 'working_dilution',
  );

  throws_ok { $process->_robot_barcode() } qr/Robot ID must be set for bed verification\n/, 
    'Throws an error when it can not find the Robot ID';
}

# _get_input_plates
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433_b',
    step_name => 'working_dilution',
  );

  my $node_list = $process->_get_input_plates();

  isa_ok($node_list, 'XML::LibXML::NodeList');
  is($node_list->size(), 4, 'It returns the correct number of input plates');

  $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433_a',
    step_name => 'working_dilution',
  );

  throws_ok { $process->_get_input_plates() } qr/Could not find any input plates\n/,
    'Throws an error if it can not find any input plates';
}

# _extract_plate_name
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433_b',
    step_name => 'working_dilution',
  );

  is($process->_extract_plate_name('Bed 2 (Input Plate 1)'), 'Input Plate 1', '1) Extracts the plate name correctly');
  is($process->_extract_plate_name('Bed 3 (Output Plate 1)'), 'Output Plate 1', '2) Extracts the plate name correctly');

  throws_ok { $process->_extract_plate_name('nothing to extract here')} qr/Could not find matching plate name/,
    'Throws an error if it can not extract a plate name';
}

# _get_output_plate_from_input
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/bed_verification';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::sm::bed_verification->new(
    process_url => 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-102433_b',
    step_name => 'working_dilution',
  );

  my $output_plate = $process->_get_output_plate_from_input('Input Plate 1');
  isa_ok($output_plate, 'XML::LibXML::Element');
  is($output_plate->findvalue('@name'), 'Bed 3 (Output Plate 1)');
}