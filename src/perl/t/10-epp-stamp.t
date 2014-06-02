use strict;
use warnings;
use Test::More tests => 2;

use_ok('wtsi_clarity::epp::stamp');

{
  my $s = wtsi_clarity::epp::stamp->new(process_url => 'some');
  isa_ok($s, 'wtsi_clarity::epp::stamp');
}

1;
