use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use_ok('wtsi_clarity::epp::isc::flowcell_barcode_validator');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/flowcell_bc_validator';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

{
  my $flowcell_bc_validator = wtsi_clarity::epp::isc::flowcell_barcode_validator->new(
    process_url => $base_uri . '/processes/24-67601',
  );
  isa_ok($flowcell_bc_validator, 'wtsi_clarity::epp::isc::flowcell_barcode_validator');

  lives_ok { $flowcell_bc_validator->run } 'Exits when barcode is valid';
}

{
  my $flowcell_bc_validator = wtsi_clarity::epp::isc::flowcell_barcode_validator->new(
    process_url => $base_uri . '/processes/24-67602',
  );
  isa_ok($flowcell_bc_validator, 'wtsi_clarity::epp::isc::flowcell_barcode_validator');

  throws_ok { $flowcell_bc_validator->run } qr/Validation for value 123456 failed. The input must have a length of 10./,
    'Throws an error when the barcode is too short';
}

1;