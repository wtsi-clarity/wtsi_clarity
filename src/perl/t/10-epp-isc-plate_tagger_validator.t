use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use_ok 'wtsi_clarity::epp::isc::plate_tagger_validator';

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/plate_tagger/valid/';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  my $validator = wtsi_clarity::epp::isc::plate_tagger_validator->new(
    process_url => $base_uri . '/processes/a_process',
  );

  can_ok($validator, qw/ run /);
}

{ # Tests process without added reagent tags
  my $validator = wtsi_clarity::epp::isc::plate_tagger_validator->new(
    process_url => $base_uri . '/processes/24-17451_without_reagent_tags',
  );

  throws_ok {$validator->_validate } 
    qr/None of not all of the analytes contains the 'reagent-label' tag.\nMight be the tags has not been added to the analytes, yet./,
    'Errors when the analytes does not contain the reagent-label tag.';
}

{ # Tests process with added reagent tags
  my $validator = wtsi_clarity::epp::isc::plate_tagger_validator->new(
    process_url => $base_uri . '/processes/24-63413_with_reagent_tags',
  );

  is($validator->_validate, 1 , 'Validates the tags has been added to the analytes.');
}

1;