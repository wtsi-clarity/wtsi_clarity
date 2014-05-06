use strict;
use warnings;
use Test::More tests => 2;

use_ok('wtsi_clarity::util::request');

{
  my $r = wtsi_clarity::util::request->new();
  isa_ok( $r, 'wtsi_clarity::util::request');
}
