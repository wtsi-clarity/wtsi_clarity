use strict;
use warnings;
use Test::More tests => 21;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/analyte_pooler';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::isc::analyte_pooler', 'can use ISC Analyte Pooler');

{
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );

  isa_ok( $pooler, 'wtsi_clarity::epp::isc::analyte_pooler');
}

{ # Test for getting the input artifacts (analytes)
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );

  lives_ok {$pooler->process_doc->input_artifacts} 'got input artifacts';

  my $input_artifacts = $pooler->process_doc->input_artifacts;
  my @nodes = $input_artifacts->findnodes(q{ /art:details/art:artifact });

  is(scalar @nodes, 2, 'correct number of input_artifacts');
}

{ # Test for getting the input artifacts container(s) (analytes) uris
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
  my @expected_container_uris = [ q{http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/containers/27-1890} ];

  my @container_uris = $pooler->_container_uris;

  is(scalar @container_uris, 1, 'correct number of the container(s)');
  is_deeply(@container_uris, @expected_container_uris, 'Got back the correct uri(s) of the containers');
}

{ # Test for getting back the correct container names
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
  my @expected_container_ids = [ q{27-1890} ];

  my @container_ids = $pooler->_container_ids;

  is(scalar @container_ids, 1, 'correct number of container names');
  is_deeply(@container_ids, @expected_container_ids, 'Got back the correct container names');
}

{ # Test for getting back the correct mapping
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
  my @expected_mapping = [
    { 'source_plate' => '27-1890', 'source_well' =>  'A:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'A:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'B:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'C:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'D:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'E:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'F:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'G:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1890', 'source_well' =>  'H:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
  ];
  my $mapping = $pooler->_mapping;

  is(scalar @{$mapping}, 96, 'correct number of mapping elements');
  is_deeply($mapping, @expected_mapping, 'Got back the correct mapping');
}

{ # Tests for getting the well location of the input artifacts
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
  my $expected_input_artifacts_location =
    {
      "A:1" => "http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-55027?state=25327",
      "A:3" => "http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-55028?state=25328",
    };
  my $input_artifacts_location = $pooler->_input_artifacts_location;
  my @expected_keys = keys %{$input_artifacts_location};
  my $expected_size = @expected_keys;
  is($expected_size, 2, 'Correct number of input artifacts');
  is_deeply($input_artifacts_location, $expected_input_artifacts_location, 'Got back the correct hash of artifact locations');
}

{ # tests getting the pool name by destination well with 8 plex
  use wtsi_clarity::epp::isc::pooling_by_8_plex;

  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );

  my $expected_a1_well_pool_name_by_8_plex = 'A1:H1 (A:1)';
  my $expected_d1_well_pool_name_by_8_plex = 'A4:H4 (D:1)';

  my $plexing_by_8 = wtsi_clarity::epp::isc::pooling_by_8_plex->new();
  # my $pool_name_code_ref = sub { return $plexing_by_8->get_pool_name };

  is($pooler->get_pool_name_by_plexing('A:1', $plexing_by_8), $expected_a1_well_pool_name_by_8_plex, 'Returns the expected pool name with 8 plex.');
  is($pooler->get_pool_name_by_plexing('D:1', $plexing_by_8), $expected_d1_well_pool_name_by_8_plex, 'Returns the expected pool name with 8 plex.');
}

{ # tests getting the pool name by destination well with 16 plex
  use wtsi_clarity::epp::isc::pooling_by_16_plex;

  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
    process_url => $base_uri . '/processes/122-21977',
    step_url    => $base_uri . '/steps/122-21977',
    _bait_info  => '16'
  );

  my $expected_a1_well_pool_name_by_16_plex = 'A1:H2 (A:1)';
  my $expected_d1_well_pool_name_by_16_plex = 'A7:H8 (D:1)';
  my $plexing_by_16 = wtsi_clarity::epp::isc::pooling_by_16_plex->new();

  is($pooler->get_pool_name_by_plexing('A:1', $plexing_by_16), $expected_a1_well_pool_name_by_16_plex, 'Returns the expected pool name with 16 plex.');
  is($pooler->get_pool_name_by_plexing('D:1', $plexing_by_16), $expected_d1_well_pool_name_by_16_plex, 'Returns the expected pool name with 16 plex.');
}

{ # Test for getting back the expected pool hash
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
 my $expected_pools_hash =
    {
      '1234567890123 A3:H3 (C:1)' => [
                 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-55028?state=25328'
               ],
      '1234567890123 A1:H1 (A:1)' => [
                 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-55027?state=25327'
               ]
    };
  my $actual_pool_hash = $pooler->_pools;
  my @expected_keys = keys %{$actual_pool_hash};
  my $expected_size = @expected_keys;
  is($expected_size, 2, 'Correct number of pools');
  is_deeply($actual_pool_hash, $expected_pools_hash, 'Got the correct pools');
}

{ # Tests for creating the pooled inputs
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-21977',
  step_url => $base_uri . '/steps/122-21977',
  );
  
  lives_ok {$pooler->_pools_doc} "get a correct response for GET request for the step's pools";
  isa_ok($pooler->_create_pools, 'XML::LibXML::Document');
}

{ # Tests for updating the current step with the created pools
  my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
    process_url => $base_uri . '/processes/122-29034',
    step_url => $base_uri . '/steps/122-29034',
  );
  lives_ok {$pooler->update_step_with_pools} "Get a correct response for updating for the step's pools";
}

1;
