#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/default_next_step';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::generic::default_next_step');

{
  my $input_process = $base_uri.'/processes/24-77215';
  my $actions_uri = $base_uri.'/steps/24-77215/actions';
  my $output_step = $base_uri.'/configuration/protocols/2/steps/4';

  my $epp = wtsi_clarity::epp::generic::default_next_step->new(
    process_url => $input_process,
    next_step   => 'Volume Check (SM)',
  );

  is($epp->actions_uri, $actions_uri, 'Gets action uri');
  is($epp->next_step_uri, $output_step, 'Get next step uri');

  my $output_xml = $epp->edit_actions_doc;

  my @next_action_nodes = $output_xml->findnodes('stp:actions/next-actions/next-action');

  for my $next_action (@next_action_nodes) {
    is($next_action->findvalue('@action'), 'nextstep', 'Sets the output action correctly');
    is($next_action->findvalue('@step-uri'), $output_step, 'Sets the output step uri correctly');
  }

  lives_ok{
      $epp->set_next_step
    } q{Doesn't throw error.};
}

{
  my $input_process = $base_uri.'/processes/24-77215';

  my $epp = wtsi_clarity::epp::generic::default_next_step->new(
    process_url => $input_process,
    next_step   => 'Fake step',
  );

  throws_ok {
      $epp->next_step_uri;
    } qr{No next step called 'Fake step' found.}, 'Throws error if no such next step exists';
}