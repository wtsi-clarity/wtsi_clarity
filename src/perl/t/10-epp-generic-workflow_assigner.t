use strict;
use warnings;
use Test::More tests => 20;
use XML::LibXML;
use Test::Exception;
use XML::SemanticDiff;


local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/workflow_assigner';

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

  my $doc = wtsi_clarity::epp::generic::workflow_assigner::_make_workflow_rerouting_request("my_uri", \@uris);
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
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

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
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
    new_step => 'step_name_2',
  );

  my $res = $m->_get_step_uri();

  my $expected =  q{http://testserver.com:1234/here/configuration/workflows/11/stages/003};
  cmp_ok($res, 'eq', $expected, '_get_step_uri should return the correct uri');
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 2',
  );
  throws_ok {
    $m->_get_step_uri();
  }
  qr{One cannot search for a step if the its name has not been defined!},
  qq{_get_step_uri should throw when there is no new_step'};
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_step => 'step_name_2',
  );
  throws_ok {
    $m->_get_step_uri();
  }
  qr{One cannot search for a step if the protocol name has not been defined!},
  qq{_get_step_uri should throw when there is no new_protocol'};
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

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
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/epp/generic/workflow_assigner/config];

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

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
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot unknown',
    new_step => 'step_name_2',
  );

  throws_ok { $m->_get_step_uri(); }
  qr{The protocol 'prot unknown' requested could not be found!},
  q{_get_step_uri should throw with the wrong protocol name.} ;
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
    process_url => $base_uri .'/processes/24-103777',
    new_wf => 'new_workflow',
    new_protocol => 'prot 1',
    new_step => 'dev_only_Z',
  );

  throws_ok { $m->_get_step_uri(); }
  qr{Step 'dev_only_Z' not found!},
  q{_get_step_uri should throw with the wrong step name.} ;
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

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
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

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

1;
