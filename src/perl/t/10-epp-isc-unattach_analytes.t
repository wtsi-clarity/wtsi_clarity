use strict;
use warnings;
use Test::Exception;
use Test::More tests => 4;
use Cwd;
use Carp;
use XML::SemanticDiff;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/unattach_analytes';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::isc::analytes_unattacher');

{
  my $unattacher = wtsi_clarity::epp::isc::analytes_unattacher->new(
    process_url => $base_uri . '/processes/24-64187');

  lives_ok {$unattacher->_unattach()} "No exceptions raised";

  my $expected_file = q{expected_generated_data.xml};
  my $testdata_dir  = q{/t/data/epp/isc/unattach_analytes/};
  my $expected_actions_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare(
    $unattacher->_unattach(), $expected_actions_xml);
  cmp_ok(scalar @differences, '==', 0, 'Created output-placement tag correctly');
}

{
  my $unattacher = wtsi_clarity::epp::isc::analytes_unattacher->new(
    process_url => $base_uri . '/processes/24-64185');

  throws_ok {$unattacher->_unattach()} qr/No analytes found in progress in step./,  "Expection raised"
}

1;