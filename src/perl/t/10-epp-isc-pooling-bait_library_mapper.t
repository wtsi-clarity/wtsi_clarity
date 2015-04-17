use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use Cwd;
use Carp;
use XML::SemanticDiff;
use File::Temp qw/tempdir/;
use File::Slurp;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pooling/bait_library_mapper';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::isc::pooling::bait_library_mapper');

{
  my $bait_mapper = wtsi_clarity::epp::isc::pooling::bait_library_mapper->new();
  isa_ok($bait_mapper, 'wtsi_clarity::epp::isc::pooling::bait_library_mapper');
}

{ # Tests if the bait library is registered
  my $bait_mapper = wtsi_clarity::epp::isc::pooling::bait_library_mapper->new();

  my $expedted_plexing_mode = '16_plex';

  is($bait_mapper->plexing_mode_by_bait_library('14M_haemv1'), $expedted_plexing_mode, 'Got back the expected plexing mode for valid bait library');
  throws_ok { $bait_mapper->plexing_mode_by_bait_library('not valid bait library')}
    qr/This Bait Library is not registered\: not valid bait library./,
    'Got error when the Bait Library is not registered in the config file.';
}

1;
