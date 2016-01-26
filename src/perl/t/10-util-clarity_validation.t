use strict;
use warnings;

use Test::More tests => 36;

use_ok('wtsi_clarity::util::clarity_validation', (qw/flgen_bc ean13_bc flowcell_bc/));

{
  is(flgen_bc(1234567890)->failed, 0, 'Returns 1 for a valid Fluidigm input');

  is(flgen_bc(123456789)->failed, 1, 'Returns 0 if input is too short');
  is(flgen_bc(123456789)->error_message, 'Validation for value 123456789 failed. The input must have a length of 10.',
  'Returns an error messages when input is too short');

  is(flgen_bc(12345678901)->failed, 1,
  'Returns 0 when the input is too long');
  is(flgen_bc(12345678901)->error_message, 'Validation for value 12345678901 failed. The input must have a length of 10.',
  'Returns an error messages when the input is too long');

  is(flgen_bc('1234a56898')->failed, 1,
  'Returns an 0 when the input is not numeric');
  is(flgen_bc('1234a56898')->error_message, 'Validation for value 1234a56898 failed. The input must be numeric.',
  'Returns an error message when the input is not numeric');

  is(flgen_bc('1234567890')->failed, 0,
  'Returns true when integers in a string are passed in');

  is(flgen_bc('123_456_58')->failed, 1,
  'Returns 0 when underscores are present');
  is(flgen_bc('123_456_58')->error_message, 'Validation for value 123_456_58 failed. The input must be numeric.',
  'Returns an error message when underscores are present');

  is(flgen_bc('abc')->error_message, 'Validation for value abc failed. The input must have a length of 10. The input must be numeric.',
  'Will concatenate multiple errors');

  is(flgen_bc('123456789 ')->error_message, 'Validation for value 123456789  failed. The input must not contain spaces.');
}

{
  is(ean13_bc(1234567891234)->failed, 0, 'Returns 1 for a valid EAN13 input.');
  is(ean13_bc(123)->error_message, 'Validation for value 123 failed. The input must have a length of 13.');
  is(ean13_bc(123456789123456789)->error_message, 'Validation for value 123456789123456789 failed. The input must have a length of 13.');
  is(ean13_bc('1234aaa654658')->error_message, 'Validation for value 1234aaa654658 failed. The input must be numeric.');

  is(ean13_bc('123456789123 ')->error_message, 'Validation for value 123456789123  failed. The input must not contain spaces.');
}

{
  # Valid
  is(flowcell_bc('H234567XX')->failed, 0, 'Returns 1 for a valid flowcell input.');
  is(flowcell_bc('C234567XX')->failed, 0, 'Returns 1 for a valid flowcell input.');
  is(flowcell_bc('HAB4567XX')->failed, 0, 'Returns 1 for a valid flowcell input.');
  is(flowcell_bc('HBCDEFGXX')->failed, 0, 'Returns 1 for a valid flowcell input.');

  # Invalid
  is(flowcell_bc('1234567')->error_message, 'Validation for value 1234567 failed. The input must have a length of 9. The input must start with C or H. The input must end with XX.');

  # Length checks
  is(flowcell_bc('H12AXX')->error_message, 'Validation for value H12AXX failed. The input must have a length of 9.');
  is(flowcell_bc('H234567890AXX')->error_message, 'Validation for value H234567890AXX failed. The input must have a length of 9.');
  is(flowcell_bc('H234567890XX')->error_message, 'Validation for value H234567890XX failed. The input must have a length of 9.');

  # Spaces checks
  is(flowcell_bc('H23456XX ')->error_message, 'Validation for value H23456XX  failed. The input must not contain spaces.');
  is(flowcell_bc('H234567XX ')->error_message, 'Validation for value H234567XX  failed. The input must have a length of 9. The input must not contain spaces.');

  # Start and end checks
  is(flowcell_bc('1234567XX')->error_message, 'Validation for value 1234567XX failed. The input must start with C or H.');
  is(flowcell_bc('A234567XX')->error_message, 'Validation for value A234567XX failed. The input must start with C or H.');
  is(flowcell_bc('G234567XX')->error_message, 'Validation for value G234567XX failed. The input must start with C or H.');

  is(flowcell_bc('H23456789')->error_message, 'Validation for value H23456789 failed. The input must end with XX.');
  is(flowcell_bc('H2345678X')->error_message, 'Validation for value H2345678X failed. The input must end with XX.');

  is(flowcell_bc('123456789')->error_message, 'Validation for value 123456789 failed. The input must start with C or H. The input must end with XX.');
  is(flowcell_bc('123H56789')->error_message, 'Validation for value 123H56789 failed. The input must start with C or H. The input must end with XX.');
  is(flowcell_bc('1234XX789')->error_message, 'Validation for value 1234XX789 failed. The input must start with C or H. The input must end with XX.');
}

1;