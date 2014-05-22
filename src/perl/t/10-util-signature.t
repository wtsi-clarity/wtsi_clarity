use strict;
use warnings;
use Test::More tests => 5;

use_ok('wtsi_clarity::util::signature');
{
  my $s = wtsi_clarity::util::signature->new();
  isa_ok($s, 'wtsi_clarity::util::signature');
  my @inputs = map "TEST" . $_, 1..96;
  is($s->encode(@inputs), 'eJwl0clxBCAMAMGUDDqAADYCb/6x2DSf', 'Converts an array to a hashed string');

  $s = wtsi_clarity::util::signature->new(sig_length => 5);
  is($s->encode(@inputs), 'eJwl0', 'Converts an array to a trimmed hashed string');

  @inputs = map "TEST" . $_, 1..2;
  is(wtsi_clarity::util::signature->new()->encode(@inputs), '00000000eJwLcQ0OMQwBEkYAEFQC5A==', 'Prepends with zeroes if less than 16 characters');
}

1;
