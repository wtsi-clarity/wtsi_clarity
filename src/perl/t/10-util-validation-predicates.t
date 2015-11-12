use strict;
use warnings;

use Test::More tests => 43;

use_ok('wtsi_clarity::util::validation::predicates', qw/has_length_of is_integer has_no_whitespace is_digits_or_uppercase starts_with ends_with/);

{
  my $length_of_3 = has_length_of(3);
  is($length_of_3->('abc'), 1, 'length_of_3 returns 1 when string length equals length');
  isnt($length_of_3->('abcd'), 1, 'length_of_3 does not return 1 when string length does not equal length');
}

{
  is(is_integer()->('123456898'), 1, 'is_integer returns 1 when value is 123456898');
  isnt(is_integer()->('1234a56898'), 1, 'is_integer does not return 1 when value is 1234a56898');
  isnt(is_integer()->('123_456_58'), 1, 'is_integer does not return 1 when value is 123_456_58');
  isnt(is_integer()->('1.1'), 1, 'is_integer does not return 1 when value is 1.1.');
}

{
  is(has_no_whitespace()->('12345'), 1, 'has_no_whitespace returns 1 when value is 12345');
  isnt(has_no_whitespace()->(' 12345'), 1, 'has_no_whitespace does not return 1 when space is at start.');
  isnt(has_no_whitespace()->('12345 '), 1, 'has_no_whitespace does not return 1 when space is at end.');
  isnt(has_no_whitespace()->('12 345'), 1, 'has_no_whitespace does not return 1 when space is in middle.');
  isnt(has_no_whitespace()->('1 23 45'), 1, 'has_no_whitespace does not return 1 when there is more than 1 space.');
  isnt(has_no_whitespace()->("12345\t"), 1, 'has_no_whitespace does not return 1 when there is a tab.');
  isnt(has_no_whitespace()->("12345\n"), 1, 'has_no_whitespace does not return 1 when there is a newline.');
}

{
  is(is_digits_or_uppercase()->('12345'), 1, 'is_digits_or_uppercase returns 1 when value is 12345');
  is(is_digits_or_uppercase()->('ABCDE'), 1, 'is_digits_or_uppercase returns 1 when value is ABCDE');
  is(is_digits_or_uppercase()->('ABC123'), 1, 'is_digits_or_uppercase returns 1 when value is ABC123');
  isnt(is_digits_or_uppercase()->('abcde'), 1, 'is_digits_or_uppercase does not return 1 when value is abcde');
  isnt(is_digits_or_uppercase()->('abcDE'), 1, 'is_digits_or_uppercase does not return 1 when value is abcDE');
  isnt(is_digits_or_uppercase()->('abc12'), 1, 'is_digits_or_uppercase does not return 1 when value is abc12');
  isnt(is_digits_or_uppercase()->('abc12AB'), 1, 'is_digits_or_uppercase does not return 1 when value is abc12AB');
}

{
  is(starts_with('A')->('ABCDE'), 1, "starts_with('A') returns 1 when value is ABCDE");
  isnt(starts_with('A')->('BCDE'), 1, "starts_with('A') does not return 1 when value is BCDE");
  is(starts_with('L')->('LBCDE'), 1, "starts_with('L') returns 1 when value is LBCDE");
  isnt(starts_with('L')->('ABCDE'), 1, "starts_with('L') does not return 1 when value is ABCDE");
  is(starts_with('6')->('6BCDE'), 1, "starts_with('6') returns 1 when value is 6BCDE");
  is(starts_with('6')->(654321), 1, "starts_with('6') returns 1 when value is number 654321");
  is(starts_with(6)->('6BCDE'), 1, "starts_with(6) returns 1 when value is 6BCDE");
  is(starts_with(6)->(654321), 1, "starts_with(6) returns 1 when value is number 654321");
  is(starts_with('ABC')->('ABCDE'), 1, "starts_with('ABC') returns 1 when value is ABCDE");
  isnt(starts_with('ABC')->('BCDE'), 1, "starts_with('ABC') does not return 1 when value is BCDE");
  isnt(starts_with('C')->('ABCDE'), 1, "starts_with('C') does not return 1 when value is ABCDE");
}

{
  is(ends_with('E')->('ABCDE'), 1, "ends_with('E') returns 1 when value is ABCDE");
  isnt(ends_with('E')->('ABCD'), 1, "ends_with('E') does not return 1 when value is ABCD");
  is(ends_with('L')->('ABCDL'), 1, "ends_with('L') returns 1 when value is ABCDL");
  isnt(ends_with('L')->('ABCDE'), 1, "ends_with('L') does not return 1 when value is ABCDE");
  is(ends_with('1')->('ABCD1'), 1, "ends_with('1') returns 1 when value is ABCD1");
  is(ends_with('1')->(654321), 1, "ends_with('1') returns 1 when value is number 654321");
  is(ends_with(1)->('ABCD1'), 1, "ends_with(1) returns 1 when value is ABCD1");
  is(ends_with(1)->(654321), 1, "ends_with(1) returns 1 when value is number 654321");
  is(ends_with('CDE')->('ABCDE'), 1, "ends_with('CDE') returns 1 when value is ABCDE");
  isnt(ends_with('CDE')->('ABCD'), 1, "ends_with('CDE') does not return 1 when value is ABCD");
  isnt(ends_with('C')->('ABCDE'), 1, "ends_with('C') does not return 1 when value is ABCDE");
}

1;