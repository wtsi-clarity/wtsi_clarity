use strict;
use warnings;
use Test::More tests => 2;

use_ok('wtsi_clarity::util::config');

{
  my $c = wtsi_clarity::util::config->new();
  isa_ok( $c, 'wtsi_clarity::util::config');
}

1;