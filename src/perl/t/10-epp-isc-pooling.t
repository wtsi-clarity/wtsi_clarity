use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/analyte_pooler';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

use_ok('wtsi_clarity::epp::isc::analyte_pooler', 'can use ISC Analyte Pooler');

my $pooler = wtsi_clarity::epp::isc::analyte_pooler->new(
  process_url => $base_uri . '/processes/122-18165'
);

isa_ok( $pooler, 'wtsi_clarity::epp::isc::analyte_pooler');

{ # test for getting the input artifacts (analytes)
  lives_ok {$pooler->_input_artifacts} 'got input artifacts';

  my $input_artifacts = $pooler->_input_artifacts;
  my @nodes = $input_artifacts->findnodes(q{ /art:details/art:artifact });

  is(scalar @nodes, 2, 'correct number of input_artifacts');
}

{ # test for getting the input artifacts container(s) (analytes) uris
  my @expected_container_uris = [ q{http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/containers/27-1890} ];

  my @container_uris = $pooler->_container_uris;

  is(scalar @container_uris, 1, 'correct number of the container(s)');
  is_deeply(@container_uris, @expected_container_uris, 'Got back the correct uri(s) of the containers');
}

{
  my @expected_container_names = [ q{27-1890} ];

  my @container_names = $pooler->_container_names;

  is(scalar @container_names, 1, 'correct number of container names');
  is_deeply(@container_names, @expected_container_names, 'Got back the correct container names');
}

1;
