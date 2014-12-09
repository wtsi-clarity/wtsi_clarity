use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;

use_ok('wtsi_clarity::util::artifact_reader');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/artifact_reader';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $lims_id = '1234';
  my $resource_type = 'samples';
  my $artifact_reader = wtsi_clarity::util::artifact_reader->new( 
    resource_type => $resource_type,
    lims_id       => $lims_id);
  isa_ok($artifact_reader, 'wtsi_clarity::util::artifact_reader');
}

{
  my $lims_id = 'SYY154A1';
  my $resource_type = 'samples';
  my $artifact_reader = wtsi_clarity::util::artifact_reader->new( 
    resource_type => $resource_type,
    lims_id       => $lims_id);
  my $artifact_xml;
  lives_ok { $artifact_xml = $artifact_reader->get_xml} 'Returns XML artifact.';
}

1;