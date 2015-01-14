use warnings;
use strict;

use Test::More tests => 10;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::sample_enhancer');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/sample_enhancer';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $me = wtsi_clarity::mq::me::sample_enhancer->new(
    process_url => 'http://testserver.com:1234/processes/999',
    step_url    => 'http://testserver.com:1234/processes/999/step/2',
    timestamp   => '2014-11-25 12:06:27',
  );

  isa_ok($me, 'wtsi_clarity::mq::me::sample_enhancer');
  can_ok($me, qw/ process_url step_url prepare_messages /);
}

{ # Test for getting the input artifacts (samples)
  my $me = wtsi_clarity::mq::me::sample_enhancer->new(
    process_url => $base_uri . '/processes/24-22682',
    step_url    => $base_uri . '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  );

  lives_ok {$me->input_artifacts} 'got input artifacts';

  my $input_artifacts = $me->input_artifacts;
  my @nodes = $input_artifacts->findnodes(q{ /art:details/art:artifact });

  is(scalar @nodes, 3, 'correct number of input_artifacts');
}

{ # Test for getting back the correct sample limsids
  my $me = wtsi_clarity::mq::me::sample_enhancer->new(
    process_url => $base_uri . '/processes/24-22682',
    step_url    => $base_uri . '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  );

  my @expected_sample_limsids = [ q{SYY154A2}, q{SYY154A3}, q{SYY154A1} ];

  my $lims_ids = $me->_lims_ids;

  is(scalar @{$lims_ids}, 3, 'correct number of sample limsids');
  is_deeply($lims_ids, @expected_sample_limsids, 'Got back the correct sample ids');
}

{
  my $me = Test::MockObject::Extends->new( wtsi_clarity::mq::me::sample_enhancer->new(
    process_url => $base_uri . '/processes/24-22682',
    step_url    => $base_uri . '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  ) ) ;

  $me->mock(q{_get_sample_message}, sub {
    my %test_msg = ( 'key1' => 'value1', 'key2' => 'value2');

    return \%test_msg;
  });

  my $messages = $me->prepare_messages;

  is(scalar @{$messages}, 3, 'correct number of sample messages');
  is(scalar keys %{@{$messages}[0]}, 2, 'Got back the right number of keys');
  my @expected_keys = ('lims', 'sample');
  is(scalar keys %{@{$messages}[0]}, @expected_keys, 'Got back the correct keys');
}

1;