use strict;
use warnings;
use Test::More tests => 4;

use_ok('wtsi_clarity::util::signature');
can_ok('wtsi_clarity::util::signature', qw / encode /);

{
  my @inputs = map "TEST" . $_, 1..96;

  is(wtsi_clarity::util::signature->encode(@inputs), 'eJwl0clxBCAMAMGUDDqAADYCb/6x2DSf', 'Converts an array to a hashed string');
}

{
  my @inputs = map "TEST" . $_, 1..2;

  is(wtsi_clarity::util::signature->encode(@inputs), '00000000eJwLcQ0OMQwBEkYAEFQC5A==', 'Prepends with zeroes if less than 16 characters');
}
