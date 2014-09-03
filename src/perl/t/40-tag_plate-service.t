use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use_ok('wtsi_clarity::tag_plate::service');

local $ENV{'WTSI_CLARITY_HOME'}        = q[t/data/config];

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/tag_plate/invalid1';

  my $s = wtsi_clarity::tag_plate::service->new(barcode => 'ABCD1234',);
  isa_ok( $s, 'wtsi_clarity::tag_plate::service');
  throws_ok { $s->validate() } qr/Plate status 'created' is not valid/, 'validation error';

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/tag_plate/valid';

  $s = wtsi_clarity::tag_plate::service->new(barcode => 'ABCD1234',);
  lives_ok { $s->validate() } 'no validation error for a valid plate';
  lives_ok { $s->mark_as_used() } 'no error marking as used';
  lives_ok { $s->get_layout() } 'no error getting the layout';
}

1;