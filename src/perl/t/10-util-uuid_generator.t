use strict;
use warnings;

use Test::More tests => 3;

use_ok('wtsi_clarity::util::uuid_generator');
can_ok('wtsi_clarity::util::uuid_generator', qw/new_uuid/);

{
  like(wtsi_clarity::util::uuid_generator::new_uuid(),
    qr/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i,
    'Returns a valid UUID.');
}

1;