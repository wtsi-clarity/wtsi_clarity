use strict;
use warnings;

use Test::MockObject::Extends;
use Test::More tests => 12;

use wtsi_clarity::clarity::step;
use wtsi_clarity::epp;

use diagnostics;

use_ok 'wtsi_clarity::clarity::step::programstatus';

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/step';

{
  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/GET/steps/24-30034.programstatus');
  my $step = get_step();
  my $step_programstatus = $step->programstatus;

  can_ok($step_programstatus, qw/uri send_warning send_error send_ok/);
  can_ok($step, qw/send_warning send_error send_ok/);

  is($step_programstatus->uri, 'http://testserver.com:1234/here/steps/24-30034/programstatus', 'Creates its uri correctly');

  $xml = $step_programstatus->_set_status_message($xml, 'WARNING', 'Danger, Will Robinson!');

  is($xml->findvalue('stp:program-status/status'), 'WARNING', '_set_status_message sets the status correctly');
  is($xml->findvalue('stp:program-status/message'), 'Danger, Will Robinson!', '_set_status_message sets the message correctly');
}

{
  my $step_programstatus = get_step()->programstatus;

  $step_programstatus = Test::MockObject::Extends->new($step_programstatus);

  my $xml;

  $step_programstatus->mock('_update', sub {
    my ($self, $programstatus) = @_;
    $xml = $programstatus;
  });

  my $message_tests = {
    'send_warning' => { status => 'WARNING', message => 'Something bad has happened but don\'t worry about it'},
    'send_error'   => { status => 'ERROR',   message => 'Can not recover from this blunder'},
    'send_ok'      => { status => 'OK',      message => 'Everything is just great'},
  };

  foreach my $method (keys %{$message_tests}) {
    $step_programstatus->$method($message_tests->{$method}->{'message'});

    is($xml->findvalue('stp:program-status/status'), $message_tests->{$method}->{'status'}, 'status is set correctly for ' . $method);
    is($xml->findvalue('stp:program-status/message'), $message_tests->{$method}->{'message'}, 'message is set correctly for ' . $method);
  }
}

sub get_step {
  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/step1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  return wtsi_clarity::clarity::step->new(
    xml => $xml,
    parent => $epp,
  );
}

1;