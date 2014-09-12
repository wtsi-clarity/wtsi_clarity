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
  'DNA Control (tag 6)');

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
  $prefix .'2-24975' => 'DNA Control (tag 89)',
  $prefix .'2-24977' => 'DNA Control (tag 91)',
  $prefix .'2-25404' => 'DNA Control (tag 69)',
  $prefix .'2-25409' => 'DNA Control (tag 61)',
  $prefix .'2-25410' => 'DNA Control (tag 62)',
  $prefix .'2-25411' => 'DNA Control (tag 59)',
  $prefix .'2-25431' => 'DNA Control (tag 1)',
  $prefix .'2-25433' => 'DNA Control (tag 3)',
  $prefix .'2-25509' => 'DNA Control (tag 20)',
  $prefix .'2-25510' => 'DNA Control (tag 17)',
  $prefix .'2-25511' => 'DNA Control (tag 18)',
);

foreach my $output (
      $i->_reagents_doc->findnodes(q[/stp:reagents/output-reagents/output])) {
   my $uri = $output->findvalue(q(@uri));
   my $expected = $tags{$uri};
   is ($output->findvalue(q[reagent-label/@name]), $expected, 'correct tag assigned');
}

1;

