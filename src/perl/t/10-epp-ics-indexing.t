use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use Test::Deep;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/tag_plate/valid';

use_ok ('wtsi_clarity::epp::ics::indexing');
my $i = wtsi_clarity::epp::ics::indexing->new(
    process_url => 'http://clarity.ac.uk:8080/api/v2/processes/151-12090',
    step_url => 'http://clarity.ac.uk:8080/api/v2/steps/151-12090'
);
isa_ok( $i, 'wtsi_clarity::epp::ics::indexing');

my $reagents_doc;
lives_ok { $reagents_doc = $i->_reagents_doc } 'reagents listing retrieved';

my $map;
lives_ok { $map = $i->_output_location_map } 'output location map created';

is ($i->_reagent_name(6, 'ATCDT'),
  'Tag: plate {ABCD1234}, set {Sanger_168tags - 10 mer tags}, {6 ATCDT}',
  'reagent name');

lives_ok {$i->_output_location_map } 'got output map';
my $prefix = q[http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/];
my %map = (
  $prefix .'2-24975' => 'A:12',
  $prefix .'2-24977' => 'C:12',
  $prefix .'2-25404' => 'E:9',
  $prefix .'2-25409' => 'E:8',
  $prefix .'2-25410' => 'F:8',
  $prefix .'2-25411' => 'C:8',
  $prefix .'2-25431' => 'A:1',
  $prefix .'2-25433' => 'C:1',
  $prefix .'2-25509' => 'D:3',
  $prefix .'2-25510' => 'A:3',
  $prefix .'2-25511' => 'B:3',
);

is(scalar keys %{$i->_output_location_map}, 11, 'correct number of artifacts in the output map');
is_deeply($i->_output_location_map, \%map, 'output map content correct');

lives_ok { $i->_index } 'indexing runs ok';

my %tags = (
  $prefix .'2-24975' => '89 GTGTGTCG',
  $prefix .'2-24977' => '91 GACCTTAG',
  $prefix .'2-25404' => '69 GGTGAGTT',
  $prefix .'2-25409' => '61 TGCTGATA',
  $prefix .'2-25410' => '62 TAGACGGA',
  $prefix .'2-25411' => '59 TAGAACAC',
  $prefix .'2-25431' => '1 ATCACGTT',
  $prefix .'2-25433' => '3 TTAGGCAT',
  $prefix .'2-25509' => '20 TTGGAGGT',
  $prefix .'2-25510' => '17 TGTACCTT',
  $prefix .'2-25511' => '18 TTCTGTGT',
);

foreach my $output (
      $i->_reagents_doc->findnodes(q[/stp:reagents/output-reagents/output])) {
   my $uri = $output->findvalue(q(@uri));
   my $expected = $tags{$uri};
   like ($output->findvalue(q[reagent-label/@name]), qr/$expected/, 'correct tag assigned');
}

1;

