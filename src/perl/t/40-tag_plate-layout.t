use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use File::Slurp;
use JSON;

use_ok( 'wtsi_clarity::tag_plate::layout' );

{
  throws_ok { wtsi_clarity::tag_plate::layout->new() } 
    qr/Attribute \(gatekeeper_info\) is required /,
    'error creating an object without required attributes';
  
  my $layout = from_json(read_file('t/data/tag_plate/valid/GET/1/19876'));
  my $l;
  lives_ok {$l = wtsi_clarity::tag_plate::layout->new(gatekeeper_info => $layout)}
    'layout object created';
  isa_ok($l, 'wtsi_clarity::tag_plate::layout');

  is($l->tag_set_name, 'Sanger_168tags - 10 mer tags', 'tag set name');
  is(join(q[:], $l->tag_info('B:1')), '2:CGATGTTT', 'tag info for B:1 retrieved');
  is(join(q[:], $l->tag_info('H:11')), '88:GATAGAGG', 'tag info for H:11 retrieved');

  throws_ok { $l->tag_info('H:14') }
   qr/Invalid column address '14' for 8:12 layout/,
   'error for invalid input location';
}

1;
