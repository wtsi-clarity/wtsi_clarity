use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use_ok('wtsi_clarity::epp::sm::fluidigm_barcode_validator');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/fluidigm_bc_validator';

{
  my $fluidigm_bc_validator = wtsi_clarity::epp::sm::fluidigm_barcode_validator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-61775',
  );
  isa_ok($fluidigm_bc_validator, 'wtsi_clarity::epp::sm::fluidigm_barcode_validator');

  throws_ok { $fluidigm_bc_validator->run } qr/Validation for value 123456 failed. The input must have a length of 10./,
    'Throws an error when the barcode is too short';
}

{
  my %tests = (
    'abcdefgasd'   => 'Validation for value abcdefgasd failed. The input must be numeric.',
    '123456789123' => 'Validation for value 123456789123 failed. The input must have a length of 10.',
    'abc1234'      => 'Validation for value abc1234 failed. The input must have a length of 10. The input must be numeric',
  );

  while (my ($barcode, $error_message) = each %tests) {
    my $fluidigm_bc_validator = wtsi_clarity::epp::sm::fluidigm_barcode_validator->new(
      output_barcode => $barcode,
      process_url    => 'unimportant',
    );

    throws_ok { $fluidigm_bc_validator->run } qr/$error_message/,
      'Throws when output barcode is ' . $barcode;
  }
}

1;