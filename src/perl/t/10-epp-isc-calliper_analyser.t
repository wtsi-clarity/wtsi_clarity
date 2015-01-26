use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

use Mojo::Collection;

use_ok 'wtsi_clarity::epp::isc::calliper_analyser';

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

# Can it run?
{
  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  can_ok($process, qw/ run /);
}

# Extract input plate barcode
{
  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  can_ok($process, qw/ _plate_barcode /);
  is($process->_plate_barcode, '12345678', 'Extracts the input plate barcode');
}

# Creates the correct file location
{
  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://clarityurl.com:8080/processes/24-18045',
    calliper_file_name => 'outputfile',
  );

  is($process->_file_path, 't/data/epp/isc/calliper_analyser/12345678.csv', 'Extracts the input plate barcode');
}

# Add that molarity
{
  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18155',
    calliper_file_name => 'outputfile',
  );

  $process->_add_molarity_to_analytes(Mojo::Collection->new({
    'Peak Count' => '0',
    'Sample Name' => 'F12_ISC_1_5',
    'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
    'Region[200-1400] Molarity (nmol/l)' => '0.00741017327953466',
    'Total Conc. (ng/ul)' => '0',
    'Well Label' => 'D09'
  },
  {
    'Peak Count' => '0',
    'Sample Name' => 'G12_ISC_1_5',
    'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
    'Region[200-1400] Molarity (nmol/l)' => '0.0417860183721143',
    'Total Conc. (ng/ul)' => '0',
    'Well Label' => 'I09'
  },
  ));

  my $artifact_d9 = $process->_output_analytes->findnodes('art:details/art:artifact[location/value="D:9"]')->pop();
  my $artifact_i9 = $process->_output_analytes->findnodes('art:details/art:artifact[location/value="I:9"]')->pop();

  my $artifact_d9_molarity = $artifact_d9->findvalue('udf:field');
  my $artifact_i9_molarity = $artifact_i9->findvalue('udf:field');

  is($artifact_d9_molarity, 0.00741017327953466, 'Updates the correct molarity for d9');
  is($artifact_i9_molarity, 0.0417860183721143, 'Updates the correct molarity for i9');
}

# Check missing molarity column in the caliper data file
{
  my $process = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => => 'http://testserver.com:1234/processes/24-18155',
    calliper_file_name => 'outputfile',
  );

  throws_ok
    { $process->_add_molarity_to_analytes(Mojo::Collection->new({
        'Peak Count' => '15',
        'Sample Name' => 'A1_ISC_1_5',
        'Plate Name' => 'Caliper2_377031_ISC_1_5_2014-12-13_02-13-05',
        'Region[200-700] (nmol/l)' => '37.6361466180786',
        'Total Conc. (ng/ul)' => '6.90993167766489',
        'Well Label' => 'A15'
      }));
    }
    qr{No Molarity related column presents in the template file.},
    q{_add_molarity_to_analytes should croak if there is no Molarity related columns in the data file};
}