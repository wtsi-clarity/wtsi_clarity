use strict;
use warnings;
use Test::More tests => 12;
use Test::Warn;

use_ok('wtsi_clarity::epp::sm::sample_received');

{
  my $dr = wtsi_clarity::epp::sm::sample_received->new(process_url => 'http://myprocess.com');
  isa_ok($dr, 'wtsi_clarity::epp::sm::sample_received');
  can_ok($dr, qw/ run /);
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';
  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
  );

  my $sample_doc = $s->fetch_and_parse(q[http://clarity-ap:8080/api/v2/samples/JON1407A937]);
  my $is_new;
  warning_like { $is_new = $s->_is_new_sample($sample_doc, 'my:url') }
  qr/Supplier name already set for the sample/, 'warning logged';
  is( $is_new, 0, 'wtsi supplier sample name set - not a new sample');

  $sample_doc = $s->fetch_and_parse(q[http://clarity-ap:8080/api/v2/samples/JAC2A6]);
  warning_like { $is_new = $s->_is_new_sample($sample_doc, 'my:url') }
  qr/Date received \d\d\d\d-\d\d-\d\d already set for the sample/, 'warning logged';
  is( $is_new, 0, 'date received set - not a new sample');

  $sample_doc = $s->fetch_and_parse(q[http://clarity-ap:8080/api/v2/samples/JON1301A293]);
  ok( $s->_is_new_sample($sample_doc), 'a new sample' );
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';
  my $uuid = 'jdghfdhgfdgfh';
  my $date = '28-May-2013';
  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
     _uuid => $uuid,
     _date => $date
  );
  my $sample_doc = $s->fetch_and_parse(q[http://clarity-ap:8080/api/v2/samples/JON1301A293]);
  $s->_update_sample($sample_doc);
  my @nodes = $sample_doc->findnodes( $wtsi_clarity::epp::sm::sample_received::SUPPLIER_NAME_PATH );
  is (scalar(@nodes), 1, 'supplier udf created');
  is ($nodes[0]->textContent, 'Test a', 'supplier udf set correctly');
  @nodes = $sample_doc->findnodes( q{ /smp:sample/name });
  is ($nodes[0]->textContent, $uuid, 'sample name changed to uuid');
  @nodes = $sample_doc->findnodes( q{ /smp:sample/date-received });
  is ($nodes[0]->textContent, $date, 'date received set');
}

1;
