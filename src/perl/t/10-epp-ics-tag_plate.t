use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;


local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/tag_plate/valid';

use_ok ('wtsi_clarity::epp::ics::tag_plate');

throws_ok {
  wtsi_clarity::epp::ics::tag_plate->new(
    process_url => 'http://some.com/processes/151-12090'
) } qr /Either "validate" or "exhaust" option should be specified/,
    'error when none of the options defined';

throws_ok {
  wtsi_clarity::epp::ics::tag_plate->new(
    process_url => 'http://some.com/processes/151-12090',
    exhaust => 1, validate => 1
) } qr /Both "validate" and "exhaust" options cannot be true/,
    'error when both of the options true';

my $epp = wtsi_clarity::epp::ics::tag_plate->new(
  process_url => 'http://some.com/processes/151-12090',
  validate    => 1
);
isa_ok( $epp, 'wtsi_clarity::epp::ics::tag_plate');
is($epp->_barcode, 'ABCD1234', 'Gets the tag plate barcode correctly');
lives_ok { $epp->run } 'runs validation';

$epp = wtsi_clarity::epp::ics::tag_plate->new(
  process_url => 'http://some.com/processes/151-12090',
  validate    => 1
);
lives_ok { $epp->run } 'runs marking as used';


