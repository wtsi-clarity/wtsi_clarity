use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

use Mojo::Collection;

use_ok 'wtsi_clarity::epp::isc::calliper_analyser';

# Can it run?
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://claritytest.com:8080/api/v2/processes/24-18045/',
    _calliper_file_name => 'outputfile',
  );

  can_ok($process, qw/ run /);
}

# Extract input plate barcode
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://claritytest.com:8080/api/v2/processes/24-18045/',
    _calliper_file_name => 'outputfile',
  );

  can_ok($process, qw/ _plate_barcode /);
  is($process->_plate_barcode, '12345678', 'Extracts the input plate barcode');
}

# Creates the correct file location
{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://clarityurl.com:8080/api/v2/processes/24-18045',
    _calliper_file_name => 'outputfile',
  );

  is($process->_file_path, 't/data/epp/isc/calliper_analyser/12345678.csv', 'Extracts the input plate barcode');
}

# Add that molarity
{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://claritytest.com:8080/api/v2/processes/24-18155',
    _calliper_file_name => 'outputfile',
  );

  $process->_add_molarity_to_analytes(Mojo::Collection->new({
    'Peak Count' => '0',
    'Sample Name' => 'F12_ISC_1_5',
    'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
    'Region[200-1400] Molarity (nmol/l)' => '0.00741017327953466',
    'Total Conc. (ng/ul)' => '0',
    'Well Label' => 'D9'
  },
  {
    'Peak Count' => '0',
    'Sample Name' => 'G12_ISC_1_5',
    'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
    'Region[200-1400] Molarity (nmol/l)' => '0.0417860183721143',
    'Total Conc. (ng/ul)' => '0',
    'Well Label' => 'I9'
  },
  ));

  my $artifact_d9 = $process->_output_analytes->findnodes('art:details/art:artifact[location/value="D:9"]')->pop();
  my $artifact_i9 = $process->_output_analytes->findnodes('art:details/art:artifact[location/value="I:9"]')->pop();

  my $artifact_d9_molarity = $artifact_d9->findvalue('udf:field');
  my $artifact_i9_molarity = $artifact_i9->findvalue('udf:field');

  is($artifact_d9_molarity, 0.00741017327953466, 'Updates the correct molarity for d9');
  is($artifact_i9_molarity, 0.0417860183721143, 'Updates the correct molarity for i9');
}