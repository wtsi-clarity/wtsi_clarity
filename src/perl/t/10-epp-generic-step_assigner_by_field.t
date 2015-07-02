use strict;
use warnings;
use Test::More tests => 8;
use XML::LibXML;
use Cwd;
use Carp;
use Test::Exception;
use XML::SemanticDiff;

use Data::Dumper;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/step_assigner_by_field';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

my $testdata_dir  = q{/t/data/epp/generic/step_assigner_by_field/};
my $expected_file = q{expected_next_actions.xml};

use_ok('wtsi_clarity::epp::generic::step_assigner_by_field');

{
  my $step_assigner_by_field = wtsi_clarity::epp::generic::step_assigner_by_field->new(
      process_url       => 'http://my.com/processes/3345',
      step_url          => 'http://my.com/steps/3345',
      next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
      field_name        => 'WTSI Proceed To Sequencing?'
  );
  isa_ok($step_assigner_by_field, 'wtsi_clarity::epp::generic::step_assigner_by_field');
}

{ # Get the available actions for the current step
  my $step_assigner_by_field = wtsi_clarity::epp::generic::step_assigner_by_field->new(
      process_url       => $base_uri . '/processes/24-28533',
      step_url          => $base_uri . '/steps/24-28533',
      next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
      field_name        => 'WTSI Proceed To Sequencing?'
  );

  my $action_list = $step_assigner_by_field->_nextActionsList();
  isa_ok($action_list, 'XML::LibXML::Document');

  my @next_actions = $action_list->findnodes(q{/stp:actions/next-actions/next-action});
  cmp_ok(scalar @next_actions, '>', 0, 'There are available next actions');
}

{ # Gets the current protocol step
  my $step_assigner_by_field = wtsi_clarity::epp::generic::step_assigner_by_field->new(
    process_url       => $base_uri . '/processes/24-28533',
    step_url          => $base_uri . '/steps/24-28533',
    next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
    field_name        => 'WTSI Proceed To Sequencing?'
  );

  my $current_protocol_step = $step_assigner_by_field->_current_protocol_step();
  isa_ok($current_protocol_step, 'XML::LibXML::Document');

  my @available_transitions = $current_protocol_step->findnodes(q{/protstepcnf:step/transitions/transition});
  cmp_ok(scalar @available_transitions, '>', 0, 'There are available transitions');
}

{ # Gets the transitions
  my $step_assigner_by_field = wtsi_clarity::epp::generic::step_assigner_by_field->new(
    process_url       => $base_uri . '/processes/24-28533',
    step_url          => $base_uri . '/steps/24-28533',
    next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
    field_name        => 'WTSI Proceed To Sequencing?'
  );

  my $expected_transitions = {
    'current_step' => 'http://testserver.com:1234/here/configuration/protocols/9/steps/36',
    'Cherrypick Worksheet & Barcode(SM)' => 'http://testserver.com:1234/here/configuration/protocols/9/steps/37'
  };
  
  is_deeply($step_assigner_by_field->_transition_step_uri_by_step_name(), $expected_transitions, 'Got the correct transitions');
}

{
  my $step_assigner_by_field = wtsi_clarity::epp::generic::step_assigner_by_field->new(
    process_url       => $base_uri . '/processes/24-28533',
    step_url          => $base_uri . '/steps/24-28533',
    next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
    field_name        => 'WTSI Proceed To Sequencing?'
  );

  my $actual_actions_xml = $step_assigner_by_field->_set_next_actions;

  my $expected_actions_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($step_assigner_by_field->_nextActionsList, $expected_actions_xml);
  cmp_ok(scalar @differences, '==', 0, 'Updated next actions correctly');
}

1;
