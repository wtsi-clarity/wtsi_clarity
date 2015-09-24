use strict;
use warnings;
use Test::More tests => 25;
use XML::LibXML;
use Test::Exception;
use XML::SemanticDiff;


local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/workflow_assigner';

use wtsi_clarity::util::config;

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::generic::workflow_assigner');

{
  my $data_raw = q{<?xml version="1.0" standalone="yes"?>
                    <wkfcnf:workflows xmlns:wkfcnf="http://genologics.com/ri/workflowconfiguration">
                      <workflow status="ACTIVE" uri="uri0" name="really?"/>
                      <workflow status="ACTIVE" uri="uri1" name="my workflow"/>
                      <workflow status="ACTIVE" uri="uri2" name="my other workflow"/>
                    </wkfcnf:workflows>   };
  my $workflows = XML::LibXML->load_xml(string => $data_raw );

  my $uri = wtsi_clarity::epp::generic::workflow_assigner::_get_workflow_uri("my workflow", $workflows);
  cmp_ok($uri, 'eq', 'uri1', q{_get_workflow_uri should find the correct the uri.} );
  throws_ok { wtsi_clarity::epp::generic::workflow_assigner::_get_workflow_uri('not there', $workflows); }
    qr{Workflow 'not there' not found}, '_get_workflow_uri should croak if the workflow cannot be found.'
}

{
  my $raw = q{http://random.com/configuration/workflows/101};

  my $uri = wtsi_clarity::epp::generic::workflow_assigner::_get_id_from_uri($raw);
  cmp_ok($uri, 'eq', '101', q{_get_id_from_uri should find the correct the uri.} );
}

{
  my @uris =  ( 'uri1',
                'uri2',
                'uri3',
              );

  my @expected_values = ( 'uri1',
                          'uri2',
                          'uri3',
                        );

  my $workflow_assigner = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'some_process',
    new_wf => 'new_workflow'
  );

  my $doc = $workflow_assigner->_make_workflow_rerouting_request_doc("my_uri", \@uris);
  my $xpc = XML::LibXML::XPathContext->new($doc->getDocumentElement());

  my @elements = $doc->firstChild->childNodes();
  cmp_ok(scalar @elements, '==', 1, q{The request contains only one child tag.} );

  @elements = $xpc->findnodes( q{ /rt:routing/assign });
  cmp_ok(scalar @elements, '==', 1, q{The request contains an 'assign' tag.} );

  @elements = $xpc->findnodes( q{ /rt:routing/assign/artifact });
  cmp_ok(scalar @elements, '==', 3, q{The request contains three artifacts.} );

  @elements = $xpc->findnodes( q{/rt:routing/assign/artifact/@uri });
  my @vals = map { $_->getValue(); } @elements;

  foreach my $val (sort @vals) {
    my $expected_val = shift @expected_values;
    cmp_ok($val, 'eq', $expected_val, 'The artifacts have the correct uri.');
  }
}

{
  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow'
  );

  my $res = $m->_new_workflow_details();
  my $expected_raw =  q{<?xml version="1.0" standalone="yes"?>
                        <wkfcnf:workflow name="new_workflow" status="ACTIVE" uri="http://testserver.com:1234/here/configuration/workflows/11" xmlns:wkfcnf="http://genologics.com/ri/workflowconfiguration">
                          <protocols>
                              <protocol uri="http://testserver.com:1234/here/configuration/protocols/1" name="prot 1"/>
                              <protocol uri="http://testserver.com:1234/here/configuration/protocols/2" name="prot 2"/>
                              <protocol uri="http://testserver.com:1234/here/configuration/protocols/3" name="prot 3"/>
                          </protocols>
                          <stages>
                            <stage name="step_name_1" uri="http://testserver.com:1234/here/configuration/workflows/11/stages/001"/>
                            <stage name="step_name_2" uri="http://testserver.com:1234/here/configuration/workflows/11/stages/002"/>
                            <stage name="step_name_2" uri="http://testserver.com:1234/here/configuration/workflows/11/stages/003"/>
                            <stage name="step_name_2" uri="http://testserver.com:1234/here/configuration/workflows/11/stages/004"/>
                            <stage name="step_name_3" uri="http://testserver.com:1234/here/configuration/workflows/11/stages/005"/>
                          </stages>
                        </wkfcnf:workflow>};
  my $expected = XML::LibXML->load_xml(string => $expected_raw );

 my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($res, $expected);
  cmp_ok(scalar @differences, '==', 0, '_new_workflow_details should return the correct workflow');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $step_name = 'step_name_2';

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
    new_step => $step_name,
  );

  my $res = $m->get_step_uri($step_name);

  my $expected =  q{http://testserver.com:1234/here/configuration/workflows/11/stages/003};
  cmp_ok($res, 'eq', $expected, 'get_step_uri should return the correct uri');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
  );
  throws_ok {
    $m->get_step_uri();
  }
  qr{One cannot search for a step if the its name has not been defined!},
  qq{get_step_uri should throw when there is no new_step'};
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $step_name = 'step_name_2';

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_step => $step_name,
  );
  throws_ok {
    $m->get_step_uri($step_name);
  }
  qr{One cannot search for a step if the protocol name has not been defined!},
  qq{get_step_uri should throw when there is no new_protocol'};
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
    new_step => 'step_name_2',
  );

  my $res = $m->_new_protocol_uri();
  my $expected =  q{http://testserver.com:1234/here/configuration/protocols/2};
  cmp_ok($res, 'eq', $expected, '_new_protocol_uri should return the correct uri');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'wrong_workflow',
    new_protocol => 'prot 2',
    new_step => 'step_name_2',
  );
  throws_ok {
    $m->_new_protocol_uri();
  }
  qr{There can only be one protocol name},
  qq{_new_protocol_uri should throw when there are more than one protocol with a given name'};
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $step_name = 'step_name_2';

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot unknown',
    new_step => $step_name,
  );

  throws_ok { $m->get_step_uri($step_name); }
  qr{The protocol 'prot unknown' requested could not be found!},
  q{get_step_uri should throw with the wrong protocol name.} ;
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

   my $step_name = 'dev_only_Z';

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 1',
    new_step => $step_name,
  );

  throws_ok { $m->get_step_uri($step_name); }
  qr{Step 'dev_only_Z' not found!},
  q{get_step_uri should throw with the wrong step name.} ;
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
    new_step => 'step_name_2',
  );

  my $req = XML::LibXML->load_xml( string => $m->_make_request() );

  my $expected_raw = q{<?xml version="1.0" encoding="utf-8"?>
                        <rt:routing xmlns:rt="http://genologics.com/ri/routing">
                          <assign stage-uri="http://testserver.com:1234/here/configuration/workflows/11/stages/003">
                            <artifact uri="http://testserver.com:1234/here/artifacts/2-00001"/>
                            <artifact uri="http://testserver.com:1234/here/artifacts/2-00002"/>
                          </assign>
                        </rt:routing> };

  my $expected = XML::LibXML->load_xml(string => $expected_raw );

  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($req, $expected);
  cmp_ok(scalar @differences, '==', 0, '_make_request should creates the correct request for new step');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow'
  );

  my $req = XML::LibXML->load_xml( string => $m->_make_request() );

  my $expected_raw = q{<?xml version="1.0" encoding="utf-8"?>
                        <rt:routing xmlns:rt="http://genologics.com/ri/routing">
                          <assign workflow-uri="http://testserver.com:1234/here/configuration/workflows/999">
                            <artifact uri="http://testserver.com:1234/here/artifacts/2-00001"/>
                            <artifact uri="http://testserver.com:1234/here/artifacts/2-00002"/>
                          </assign>
                        </rt:routing> };
  my $expected = XML::LibXML->load_xml(string => $expected_raw );
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($req, $expected);
  cmp_ok(scalar @differences, '==', 0, '_make_request should creates the correct request for new workflow');
}

{ # Gets the list of workflows
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $workflow_assigner = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'workflow b'
  );

  my @expected_workflows = (
    'new_workflow',
    'wrong_workflow',
    'workflow a',
    'workflow a_20150609',
    'workflow a_20150909',
    'workflow b',
    'workflow b_20150609',
    'workflow b_20150909',
  );

  is_deeply($workflow_assigner->_get_workflow_names, \@expected_workflows, 'Correctly returns the list of workflow names.')
}

{ # Gets the current workflow by name
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $workflow_assigner = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'workflow b'
  );

  my $given_workflow_name = "new_workflow";
  my $expected_workflow_name = "new_workflow";

  is($workflow_assigner->_get_current_workflow_by_name($given_workflow_name), $expected_workflow_name,
    'Returns the current workflow name correctly.');

  $given_workflow_name = 'workflow a';
  $expected_workflow_name = "workflow a_20150909";
  $workflow_assigner->_get_current_workflow_by_name($given_workflow_name);
  is($workflow_assigner->_get_current_workflow_by_name($given_workflow_name), $expected_workflow_name,
    'Returns the current workflow name correctly.');

  $given_workflow_name = 'workflow x';
  throws_ok { $workflow_assigner->_get_current_workflow_by_name($given_workflow_name); }
  qr{The given workflow 'workflow x' is not exist.},
  q{Got exception when workflow does not exist.} ;
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $workflow_assigner = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'workflow b'
  );

  my $expected_workflow_name = "workflow b_20150909";

  is($workflow_assigner->new_filtered_wf, $expected_workflow_name, 'Returns the current workflow name correctly.')
}

1;
