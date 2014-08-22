use strict;
use warnings;
use Test::More tests => 17;
use Test::Warn;
use Test::Exception;
use Test::MockObject::Extends;
use JSON qw/encode_json/;
use wtsi_clarity::util::request;

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

  my $ss_request_mock = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );

  $ss_request_mock->mock(q(get), sub{
    my ($self, $url) = @_;
    return encode_json { 'uuid' => 12345 };
  });

  my $date = '28-May-2013';

  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
     _ss_request => $ss_request_mock,
     _date => $date
  );

  my $sample_doc = $s->fetch_and_parse(q[http://clarity-ap:8080/api/v2/samples/JON1301A293]);
  $s->_update_sample($sample_doc);
  my @nodes = $sample_doc->findnodes( $wtsi_clarity::epp::sm::sample_received::SUPPLIER_NAME_PATH );
  cmp_ok(scalar(@nodes), '==', 1, 'supplier udf should be created.');
  cmp_ok($nodes[0]->textContent, 'eq', 'Test a', 'supplier udf should be correct.');

  @nodes = $sample_doc->findnodes( q{ /smp:sample/name });
  cmp_ok($nodes[0]->textContent, 'eq', '12345', 'should change sample name to uuid');

  @nodes = $sample_doc->findnodes( q{/smp:sample/date-received});
  cmp_ok(scalar(@nodes), '==', 1, 'should find date-received.');
  is ($nodes[0]->textContent, $date, 'should set date-received');
}

# uuid_request
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';

  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
  );

  isa_ok($s->_ss_request, "wtsi_clarity::util::request");
}

# get_uuid
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';

  my $ss_request_mock = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );

  $ss_request_mock->mock(q(get), sub{
    my ($self, $url) = @_;
    return encode_json { 'uuid' => 12345 };
  });

  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
     _ss_request => $ss_request_mock,
  );

  is($s->_get_uuid(), 12345, 'Successfully retrieves a uuid');
}

# get_uuid - croak if empty response
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';

  my $ss_request_mock = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );

  $ss_request_mock->mock(q(get), sub{
    my ($self, $url) = @_;
    return undef;
  });

  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
     _ss_request => $ss_request_mock,
  );

  throws_ok { $s->_get_uuid() } qr/Empty response/, "Throws error if response is empty";
}

# get_uuid - croak no uuid
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sample_received';

  my $ss_request_mock = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );

  $ss_request_mock->mock(q(get), sub{
    my ($self, $url) = @_;
    return encode_json { 'not_uuid' => 12345 };
  });

  my $s = wtsi_clarity::epp::sm::sample_received->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/JAC2A6000],
     _ss_request => $ss_request_mock,
  );

  throws_ok { $s->_get_uuid() } qr/Could not get uuid/, "Throws error if uuid does not exist";
}

1;