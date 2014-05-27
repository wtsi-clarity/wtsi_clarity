use strict;
use warnings;
use Test::More tests => 5;

use_ok('wtsi_clarity::util::signature');
{
  my $s = wtsi_clarity::util::signature->new();
  isa_ok($s, 'wtsi_clarity::util::signature');
  my @inputs = map "TEST" . $_, 1..96;
  is($s->encode(@inputs), '+GMAEAC+CRFQCWAW/HYACA', 'Converts an array to a hashed string');

  $s = wtsi_clarity::util::signature->new(sig_length => 5);
  is($s->encode(@inputs), '+GMAE', 'Converts an array to a trimmed hashed string');

  @inputs = map "TEST" . $_, 1..2;
  is(wtsi_clarity::util::signature->new()->encode(@inputs), 'WDOLGXXYN8SB0XLJM1TT5W', 'works for short input');
}

1;
