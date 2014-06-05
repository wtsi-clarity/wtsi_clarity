use strict;
use warnings;
use Test::More tests => 2;

use_ok('wtsi_clarity::epp::sm::sample_received');

{
  my $dr = wtsi_clarity::epp::sm::sample_received->new(process_url => 'http://myprocess.com');
  can_ok($dr, qw/ run /);
}
