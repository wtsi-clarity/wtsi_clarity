use warnings;
use strict;

use Test::More tests => 6;
use Test::Exception;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::mq::me::fluidigm_enhancer');

{
  my $fe = wtsi_clarity::mq::me::fluidigm_enhancer->new(
    process_url => 'http://testserver.com:1234/processes/999',
    step_url    => 'http://testserver.com:1234/processes/999/step/2',
    timestamp   => '2014-11-25 12:06:27',
  );

  isa_ok($fe, 'wtsi_clarity::mq::me::fluidigm_enhancer');
  can_ok($fe, qw/ process_url step_url prepare_messages /);
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/fluidigm_enhancer';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $fe = wtsi_clarity::mq::me::fluidigm_enhancer->new(
    process_url => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/processes/24-27282',
    step_url    => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/steps/24-27282',
    timestamp   => '2014-11-25 12:06:27',
  );

  my @expected_container_limsids = [ q{27-4520} ];

  my $lims_ids = $fe->_lims_ids;

  is(scalar @{$lims_ids}, 1, 'correct number of container limsids');
  is_deeply($lims_ids, @expected_container_limsids, 'Got back the correct container ids');

  lives_ok { $fe->prepare_messages; } 'Can prepare messages';
}

1;