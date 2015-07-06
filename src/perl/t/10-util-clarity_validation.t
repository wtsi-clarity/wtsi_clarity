use strict;
use warnings;

use Test::More tests => 16;

use_ok('wtsi_clarity::util::clarity_validation', (qw/flgen_bc ean13_bc/));

{
  is(flgen_bc(1234567890)->failed, 0, 'Returns 1 for a valid Fluidigm barcode');

  is(flgen_bc(123456789)->failed, 1, 'Returns 0 if barcode is too short');
  is(flgen_bc(123456789)->error_message, 'Validation for value 123456789 failed. The barcode must have a length of 10.',
    'Returns an error messages when barcode is too short');

  is(flgen_bc(12345678901)->failed, 1,
    'Returns 0 when the barcode is too long');
  is(flgen_bc(12345678901)->error_message, 'Validation for value 12345678901 failed. The barcode must have a length of 10.',
    'Returns an error messages when the barcode is too long');

  is(flgen_bc('1234a56898')->failed, 1,
    'Returns an 0 when the barcode is not numeric');
  is(flgen_bc('1234a56898')->error_message, 'Validation for value 1234a56898 failed. The barcode must be numeric.',
    'Returns an error message when the barcode is not numeric');

  is(flgen_bc('1234567890')->failed, 0,
    'Returns true when integers in a string are passed in');

  is(flgen_bc('123_456_58')->failed, 1,
    'Returns 0 when underscores are present');
  is(flgen_bc('123_456_58')->error_message, 'Validation for value 123_456_58 failed. The barcode must be numeric.',
    'Returns an error message when underscores are present');

  is(flgen_bc('abc')->error_message, 'Validation for value abc failed. The barcode must have a length of 10. The barcode must be numeric.',
    'Will concatenate multiple errors');
}

{
  is(ean13_bc(1234567891234)->failed, 0, 'Returns 1 for a valid EAN13 barcode.');
  is(ean13_bc(123)->error_message, 'Validation for value 123 failed. The barcode must have a length of 13.');
  is(ean13_bc(123456789123456789)->error_message, 'Validation for value 123456789123456789 failed. The barcode must have a length of 13.');
  is(ean13_bc('1234aaa654658')->error_message, 'Validation for value 1234aaa654658 failed. The barcode must be numeric.');
}

1;