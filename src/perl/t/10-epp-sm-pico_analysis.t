use strict;
use warnings;
use Carp;
use Test::More tests => 10;
use XML::LibXML;
use Data::Dumper;
use XML::SemanticDiff;

use_ok('wtsi_clarity::epp::sm::pico_analysis');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
my $config = wtsi_clarity::util::config->new();
my $base_url = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/pico_analysis';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981',
  );

  isa_ok($pa, 'wtsi_clarity::epp::sm::pico_analysis');
  can_ok($pa, qw/run/);
}

# Input URIs
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981_b',
  );

  my @output_uris = (
    $base_url . '/artifacts/2-18794?state=7394',
    $base_url . '/artifacts/2-18796?state=7396',
    $base_url . '/artifacts/2-18798?state=7398',
    $base_url . '/artifacts/2-18800?state=7400',
    $base_url . '/artifacts/2-18786?state=7386',
  );

  is_deeply($pa->_input_uris, \@output_uris, 'Finds the lims uris correctly');
}

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981_a',
  );

  my @containers = ('27-382', '27-345');

  # Can't test at the moment as uses batch request which is a POST,
  # which means it isn't cached
  
  # my @map_keys = keys $pa->_container_to_artifact_map;

  # is_deeply(\@map_keys, \@containers, 'Gets the containers');
  # is_deeply(values $pa->_container_to_artifact_map, @artifacts, 'Gets the artifacts');
}

# Extract file url / file name
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981',
  );

  my $parser = XML::LibXML->new();
  my $output_analyte = $parser->parse_file('t/data/sm/pico_analysis/GET/artifacts/92-10870?state=5320');

  is ($pa->_extract_file_url($output_analyte), $base_url . '/files/92-10870-40-178', 'Extracts the file url');
  is ($pa->_extract_file_name($output_analyte), 'PicoAssay', 'Extracts the file name');
}

# Extract file location
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981',
  );

  my $parser = XML::LibXML->new();
  my $file = $parser->parse_file('t/data/sm/pico_analysis/GET/files/92-10870-40-178');

  is ($pa->_extract_file_location($file), 'sftp://web-claritytest-01.internal.sanger.ac.uk/opt/gls/clarity/users/glsftp/Process/2014/7/24-4158/92-10870-40-177', 'Extracts the file location');
}

{ #_output_ids
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981_c',
  );
  my $expected_results = [
          '2-100001',
          '2-100002',
          '2-100003',
          '2-100004',
          '2-100005'
        ];
  is_deeply($pa->_output_ids, $expected_results,'pico_analysis should contains the correct output artifacts uris');
}

{ # _input_to_output_map
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981_c',
  );
  my $expected_results = {
          '2-100005' => {
                        'container_id' => '27-767',
                        'location' => 'E:1',
                        'input_id' => '2-18786'
                      },
          '2-100002' => {
                        'container_id' => '27-767',
                        'location' => 'B:1',
                        'input_id' => '2-18796'
                      },
          '2-100004' => {
                        'container_id' => '27-767',
                        'location' => 'D:1',
                        'input_id' => '2-18800'
                      },
          '2-100001' => {
                        'container_id' => '27-767',
                        'location' => 'A:1',
                        'input_id' => '2-18794'
                      },
          '2-100003' => {
                        'container_id' => '27-767',
                        'location' => 'C:1',
                        'input_id' => '2-18798'
                      }
  };
  my $d = $pa->_input_to_output_map;
  is_deeply($d, $expected_results,'pico_analysis should contains the correct input output map for artifacts');
}

{ # _update_output_artifacts
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    analysis_file => '92-1234',
    process_url => $base_url . '/processes/24-11981_c',
  );

  my $testdata_path = q(./t/data/sm/pico_analysis/);
  my $test_data = q(test_data.xml);

  my $parser = XML::LibXML->new();

  my $expected_results = $parser->load_xml(location => $testdata_path.$test_data) or croak 'File cannot be found at ' . $testdata_path.$test_data;

  my $data = {
    'B:1' => {
                'plateA_fluorescence' => '591995.5',
                'cv' => '0.343403505409531',
                'concentration' => '5.67197315826223',
                'status' => 'Passed',
                'plateB_fluorescence' => '594877.5'
             },
    'C:1' => {
                'plateA_fluorescence' => '1191967',
                'cv' => '2.26924725499107',
                'concentration' => '11.3927891277249',
                'status' => 'Passed',
                'plateB_fluorescence' => '1154318.5'
             },
    'D:1' => {
                'plateA_fluorescence' => '774974',
                'cv' => '0.0376247880107515',
                'concentration' => '7.4614370908395',
                'status' => 'Passed',
                'plateB_fluorescence' => '774561.75'
              },
    'E:1' => {
                'plateA_fluorescence' => '859754',
                'cv' => '0.296488057223671',
                'concentration' => '8.31794537400462',
                'status' => 'Passed',
                'plateB_fluorescence' => '863366.5'
              },
    'A:1' => {
                'plateA_fluorescence' => '380846.5',
                'cv' => '1.8983328621226',
                'concentration' => '3.62517026662824',
                'status' => 'Passed',
                'plateB_fluorescence' => '391210'
               },

  };
  my $d = $pa->_update_output_artifacts($data);
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($d, $expected_results);
  cmp_ok(scalar @differences, '==', 0, 'pico_analysis should create the correct updated artifacts');
}

