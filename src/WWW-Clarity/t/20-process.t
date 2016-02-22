#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockObject::Extends;

use WWW::Clarity;
use WWW::Clarity::Mocks::MockRequest;

BEGIN {
  my $mock_request = WWW::Clarity::Mocks::MockRequest->new(
    username => 'testuser',
    password => 'testpass',
  );
  my $clarity = WWW::Clarity->new(
    username => 'testuser',
    password => 'testpass',
    request  => $mock_request,
  );
  my $uri = 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/processes/24-68287';
  my $process = $clarity->get_process($uri);

  isa_ok($process, 'WWW::Clarity::Models::Process', 'Object returned by Clarity');

  is($process->get_uri, $uri, 'Gets the uri correctly.');

  my $expected_date = DateTime->new(
    year  => 2015,
    month => 12,
    day   => 2,
  );

  is($process->get_type, 'Fluidigm 96.96 IFC Analysis (SM)', 'Has correct process type.');
  is($process->get_date, $expected_date, 'Has correct date.');

  my $new_date = DateTime->new(
    year  => 2016,
    month => 02,
    day   => 18,
  );

  $process->set_date($new_date)->set_type('Some step');
  is($process->xml->findvalue('date-run'), '2016-02-18', 'Sets date correctly.');
  is($process->xml->findvalue('type'), 'Some step', 'Can chain setters.');

  isa_ok($process->get_researcher, 'WWW::Clarity::Models::Researcher', 'Object get_researcher method returns');
  throws_ok {
      $process->set_researcher('foo');
    } qr/Can't locate object method "set_researcher"/, 'Researcher is read only.';
  isa_ok($process->get_researcher, 'WWW::Clarity::Models::Researcher', 'Object get_researcher method returns still');

  my @input_artifacts = @{$process->get_input_artifacts};
  is(scalar @input_artifacts, 86, 'Returns the correct number of input artifacts');
  isa_ok($input_artifacts[0], 'WWW::Clarity::Models::Artifact', 'First returned input artifact');
  throws_ok {
      $process->set_input_artifacts('foo');
    } qr/Can't locate object method "set_input_artifacts"/, 'Input artifacts is read only.';

  my @output_artifacts = @{$process->get_output_artifacts};
  is(scalar @output_artifacts, 87, 'Returns the correct number of output artifacts');
  isa_ok($output_artifacts[0], 'WWW::Clarity::Models::Artifact', 'First returned output artifact');
  throws_ok {
      $process->set_output_artifacts('foo');
    } qr/Can't locate object method "set_output_artifacts"/, 'Output artifacts is read only.';

  my @input_samples = @{$process->get_input_samples};
  is(scalar @input_samples, 86, 'Returns the correct number of input samples');
  isa_ok($input_samples[0], 'WWW::Clarity::Models::Sample', 'First returned input sample');

  my @output_samples = @{$process->get_output_samples};
  is(scalar @output_samples, 86, 'Returns the correct number of output samples');
  isa_ok($output_samples[0], 'WWW::Clarity::Models::Sample', 'First returned output sample');
}

done_testing();
