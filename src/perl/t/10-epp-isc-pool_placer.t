use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pool_placer';
# local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

use_ok('wtsi_clarity::epp::isc::pool_placer', 'can use ISC pool placer');

my $placer = wtsi_clarity::epp::isc::pool_placer->new(
  process_url => $base_uri . '/processes/122-22172',
  step_url => $base_uri . '/steps/122-22172',
);

isa_ok( $placer, 'wtsi_clarity::epp::isc::pool_placer');

{ # Tests for getting the placements XML response
  my $placement_response = $placer->_placements_doc;
  lives_ok {$placement_response} "get a correct response body when sending a GET request for the step's placements";
  isa_ok($placement_response, 'XML::LibXML::Document');
}

{ # Tests for updating output-placement tag (pool) with location
  my $out_placement_uri = "http://web-claritytest-01.internal.sanger.ac.uk:8080/artifacts/2-76901";
  my $expected_location_value = "A:1";

  is($placer->_pool_location($out_placement_uri), $expected_location_value, 'Correct pool location');
}

{ # Tests the expected container uri
  my $expected_container_uri = q{http://web-claritytest-01.internal.sanger.ac.uk:8080/containers/27-2133};

  is($placer->_container_uri, $expected_container_uri, 'Gets the correct container uri');
}

{ # Tests for updating the current step with the created pools placing to their related wells
  $placer->_update_output_placements_with_location;
  
  lives_ok {$placer->update_step_with_placements} "Get a correct response for updating for the step's placements";
}