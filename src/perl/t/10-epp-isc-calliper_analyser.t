use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use Cwd;
use Carp;
use XML::SemanticDiff;

use Mojo::Collection;

use_ok 'wtsi_clarity::epp::isc::calliper_analyser';

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/calliper_analyser/';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

# Can it run?
{
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  can_ok($analyser, qw/ run /);
}

# Extract input plate barcode
{
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  can_ok($analyser, qw/ _plate_barcode /);
  is($analyser->_plate_barcode, '12345678', 'Extracts the input plate barcode');
}

# Creates the correct file location
{
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://clarityurl.com:8080/processes/24-18045',
    calliper_file_name => 'outputfile',
  );

  is($analyser->_file_path, 't/data/epp/isc/calliper_analyser/12345678.csv', 'Extracts the input plate barcode');
}

{
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://clarityurl.com:8080/processes/24-18045',
    calliper_file_name => 'outputfile',
  );

  my $expected_count = 208;
  is(scalar @{$analyser->_reading_the_caliper_file}, $expected_count, 'Returns the the correct amount of data');
}

{ # get the concentration by wells
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  my $caliper_datum = [
    {
      'Peak Count' => '5',
      'Sample Name' => 'A1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.20151284050569',
      'Total Conc. (ng/ul)' => '0.173425862265629',
      'Well Label' => 'A01'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'A1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.23010180190948',
      'Total Conc. (ng/ul)' => '0.147051987121658',
      'Well Label' => 'B01'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'B1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.53750708774114',
      'Total Conc. (ng/ul)' => '0.182153780398987',
      'Well Label' => 'C01'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'B1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.13750708774114',
      'Total Conc. (ng/ul)' => '0.122153780398987',
      'Well Label' => 'D01'
    }
  ];

  my $expected_concentration_by_wells = {
    "A:1" =>  {
      "concentration" => [0.173425862265629, 0.147051987121658],
      "molarity"      => [2.20151284050569, 2.23010180190948]
    },
    "B:1" => {
      "concentration" => [0.182153780398987, 0.122153780398987],
      "molarity"      => [2.53750708774114, 2.13750708774114]
    },
  };

  is_deeply($analyser->_get_data_by_wells($caliper_datum), $expected_concentration_by_wells,
    'Returns the correct concentrations by well name');
}

{ # test the average concentration calculation
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  my $data_by_wells = [1.12, 1.22];

  my $expected_avarage_and_diluted_concentration = 5.85;

  is($analyser->_averaged_and_diluted_data_for_well($data_by_wells),
    $expected_avarage_and_diluted_concentration,
    'Returns the correct average concentration');
}

{ # calculate the average concentration by wells
  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => 'http://testserver.com:1234/processes/24-18045/',
    calliper_file_name => 'outputfile',
  );

  my $data_by_wells = {
    "A:1" =>  {
      "concentration" => [0.173425862265629, 0.147051987121658],
      "molarity"      => [2.20151284050569, 2.23010180190948]
    },
    "B:1" => {
      "concentration" => [0.182153780398987, 0.122153780398987],
      "molarity"      => [2.53750708774114, 2.13750708774114]
    },
  };

  my $expected_average_data_by_wells = {
    'A:1' => {
      "concentration" => '0.8',
      "molarity"      => '11.07'
    },
    'B:1' => {
      "concentration" => '0.76',
      "molarity"      => '11.68'
    }
  };

  is_deeply($analyser->_avaraged_data_by_well($data_by_wells), $expected_average_data_by_wells,
    'Returns the correct average concentrations by well name');
}

{ # Tests the sample data with location and concentration by URIs
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => $base_uri . '/processes/24-63208/',
    calliper_file_name => 'outputfile',
  );

  my $average_data_by_wells = {
    'E:10'  => {
      'concentration' => '0.16',
      'molarity'      => '11.22'
    },
    'F:10'  => {
      'concentration' => '0.15',
      'molarity'      => '10.56'
    },
    'H:9'   => {
      'concentration' => '1.64',
      'molarity'      => '11.45'
    }
  };

  my $expected_sample_data_by_uris_with_location = [
    {
      'http://testserver.com:1234/here/samples/SV2454A171' => {
        'location'      => 'E:10',
        'concentration' => '0.16',
        'molarity'      => '11.22'
      }
    },
    {
      'http://testserver.com:1234/here/samples/SV2454A172' => {
        'location' => 'F:10',
        'concentration' => '0.15',
        'molarity'      => '10.56'
      }
    },
    {
      'http://testserver.com:1234/here/samples/SV2454A166' => {
        'location' => 'H:9',
        'concentration' => '1.64',
        'molarity'      => '11.45'
      }
    }
  ];

  my $parent_process_doc = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . 'GET/processes.24-63206'
  );

  my $artifacts_from_parent_process = $analyser->_artifacts_from_parent_process($parent_process_doc);

  is_deeply($analyser->_sample_data_by_uris($artifacts_from_parent_process, $average_data_by_wells), $expected_sample_data_by_uris_with_location,
    'Returns the correct sample data with location and concentration by URIs');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => $base_uri . '/processes/24-63208/',
    calliper_file_name => 'outputfile',
  );

  my $parent_process_doc = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . 'GET/processes.24-63206'
  );

  my $average_concentration_by_wells = {
    'E:10'  => {
      'concentration' => '0.16',
      'molarity'      => '11.22'
    },
    'F:10'  => {
      'concentration' => '0.15',
      'molarity'      => '10.56'
    },
    'H:9'   => {
      'concentration' => '1.64',
      'molarity'      => '11.45'
    }
  };

  my $artifacts_from_parent_process = $analyser->_artifacts_from_parent_process($parent_process_doc);

  my $sample_data_by_uris = $analyser->_sample_data_by_uris($artifacts_from_parent_process, $average_concentration_by_wells);

  $analyser->_set_sample_details($sample_data_by_uris);

  my $sample_data = {
    'concentration' => '0.16',
    'molarity'      => '11.22'
  };
  my $sample_uri = 'http://testserver.com:1234/here/samples/SV2454A171';

  $analyser->_update_sample_with_data($sample_uri, $sample_data);

  my $expected_sample_details = q{updated_sample_details.xml};
  my $testdata_dir  = q{/t/data/epp/isc/calliper_analyser/};
  my $expected_sample_details_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_sample_details) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_sample_details ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($analyser->_sample_details, $expected_sample_details_xml);
  cmp_ok(scalar @differences, '==', 0, 'Updated samples with library concentration correctly');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $analyser = wtsi_clarity::epp::isc::calliper_analyser->new(
    process_url => $base_uri . '/processes/24-63208/',
    calliper_file_name => 'outputfile',
  );

  my $average_concentration_by_wells = {
    'E:10'  => {
      'concentration' => '0.16',
      'molarity'      => '11.22'
    },
    'F:10'  => {
      'concentration' => '0.15',
      'molarity'      => '10.56'
    },
    'H:9'   => {
      'concentration' => '1.64',
      'molarity'      => '11.45'
    }
  };

  $analyser->_update_samples_by_location($average_concentration_by_wells);

  my $expected_samples_details = q{updated_sample_details_of_all_samples.xml};
  my $testdata_dir  = q{/t/data/epp/isc/calliper_analyser/};
  my $expected_samples_details_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_samples_details) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_samples_details ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($analyser->_sample_details, $expected_samples_details_xml);
  cmp_ok(scalar @differences, '==', 0, 'Updated all samples with library concentration correctly');
}

1;