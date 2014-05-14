use strict;
use warnings;
use Test::More tests=>4;

use_ok('wtsi_clarity::epp::sm::create_label');

{
  my $l = wtsi_clarity::epp::sm::create_label->new(process_url => 'some');
  isa_ok($l, 'wtsi_clarity::epp::sm::create_label');
  ok (!$l->source_plate, 'source_plate flag is false by default');
  $l = wtsi_clarity::epp::sm::create_label->new(process_url => 'some', source_plate=>1);
  ok ($l->source_plate, 'source_plate flag can be set to true');
}

1;