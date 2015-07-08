use strict;
use warnings;

use Test::More tests => 7;

use_ok('wtsi_clarity::util::validation::predicates', qw/has_length_of is_integer/);

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

1;