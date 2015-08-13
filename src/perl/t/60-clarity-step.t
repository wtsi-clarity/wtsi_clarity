use strict;
use warnings;
use XML::LibXML;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;

use wtsi_clarity::epp;

use Data::Dumper;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/step';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok 'wtsi_clarity::clarity::step';

{
  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/step1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $step = wtsi_clarity::clarity::step->new(
    xml => $xml,
    parent => $epp,
  );

  isa_ok($step, 'wtsi_clarity::clarity::step', 'Builds the object correctly');
}

# Gets the URIs of the input containers and their count
{
  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/step1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $step = wtsi_clarity::clarity::step->new(
    xml => $xml,
    parent => $epp,
  );

  my @expected_container_uris = (
    'http://testserver.com:1234/here/containers/27-5785',
    'http://testserver.com:1234/here/containers/27-5786',
    'http://testserver.com:1234/here/containers/27-5787',
    'http://testserver.com:1234/here/containers/27-5788',
  );
  my $expected_input_container_count = 4;

  isa_ok($step->_placement_doc, 'XML::LibXML::Document');

  is_deeply($step->_output_containers_uri, \@expected_container_uris, 'Returns the correct output containers uri');
  is($step->output_container_count, $expected_input_container_count, 'Returns the correct output container count.');
}

1;