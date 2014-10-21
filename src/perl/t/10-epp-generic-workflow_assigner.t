use strict;
use warnings;
use Test::More tests => 10;
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
  print "\n\n --> _new_workflow_details should creates the correct request ?? \n";
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

  print $base_uri. " - ".$res;
  my $expected_raw =  q{<?xml version="1.0" standalone="yes"?>
                        <wkfcnf:workflow name="C44 workflow not QC" status="ACTIVE" uri="http://testserver.com:1234/api/v2/configuration/workflows/11" xmlns:wkfcnf="http://genologics.com/ri/workflowconfiguration">
                          <protocols>
                              <protocol uri="http://testserver.com:1234/configuration/protocols/45" name="prot 1"/>
                              <protocol uri="http://testserver.com:1234/configuration/protocols/2" name="prot 2"/>
                              <protocol uri="http://testserver.com:1234/configuration/protocols/2" name="prot 3"/>
                          </protocols>
                          <stages>
                            <stage name="dev_only_A" uri="http://testserver.com:1234/api/v2/configuration/workflows/11/stages/575"/>
                            <stage name="dev_only_B" uri="http://testserver.com:1234/api/v2/configuration/workflows/11/stages/576"/>
                            <stage name="dev_only_C" uri="http://testserver.com:1234/api/v2/configuration/workflows/11/stages/577"/>
                            <stage name="dev_only_C" uri="http://testserver.com:1234/api/v2/configuration/workflows/11/stages/578"/>
                          </stages>
                        </wkfcnf:workflow>};
  my $expected = XML::LibXML->load_xml(string => $expected_raw );

 my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($res, $expected);
  cmp_ok(scalar @differences, '==', 0, '_new_workflow_details should creates the correct request');
}










# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot unknown',
#     new_step => 'dev_only_C',
#   );

#   throws_ok { $m->_new_step_uri(); }
#   qr{Protocol 'prot unknown' not found!},
#   q{_new_step_uri should throw with the wrong protocol name.} ;
# }

# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot 1',
#     new_step => 'dev_only_Z',
#   );

#   throws_ok { $m->_new_step_uri(); }
#   qr{Step 'dev_only_Z' not found!},
#   q{_new_step_uri should throw with the wrong step name.} ;
# }



















# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot 1',
#     new_step => 'dev_only_C',
#   );

#   my $expected_val = q{http://testserver.com:1234/api/v2/configuration/protocols/45/steps/458};
#   my $uri = $m->_new_step_uri();

#   cmp_ok($uri, 'eq', $expected_val, q{_new_step_uri should find the correct the uri.} );
# }

# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot unknown',
#     new_step => 'dev_only_C',
#   );

#   throws_ok { $m->_new_protocol_uri(); }
#   qr{Protocol 'prot unknown' not found!},
#   q{_new_protocol_uri should throw with the wrong protocol name.} ;
# }

# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot 1',
#     new_step => 'dev_only_C',
#   );

#   my $expected_val = q{http://testserver.com:1234/api/v2/configuration/protocols/45};
#   my $uri = $m->_new_protocol_uri();

#   cmp_ok($uri, 'eq', $expected_val, q{_new_protocol_uri should find the correct the uri.} );
# }

# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow',
#     new_protocol => 'prot 1',
#     new_step => 'dev_only_C',
#   );

#   my $req = XML::LibXML->load_xml( string => $m->_make_request() );

  print $req;
  my $expected_raw = q{<?xml version="1.0" encoding="utf-8"?>
                        <rt:routing xmlns:rt="http://genologics.com/ri/routing">
                          <assign stage-uri="http://testserver.com:1234/api/v2/configuration/workflow/999/stages/458">
                            <artifact uri="http://testserver.com:1234/api/v2/artifacts/2-00001"/>
                            <artifact uri="http://testserver.com:1234/api/v2/artifacts/2-00002"/>
                          </assign>
                        </rt:routing> };
  my $expected = XML::LibXML->load_xml(string => $expected_raw );

 my $comparer = XML::SemanticDiff->new();

#   my @differences = $comparer->compare($req, $expected);
#   cmp_ok(scalar @differences, '==', 0, '_make_request should creates the correct request');
# }

# {
#   use wtsi_clarity::util::config;
#   local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

#   my $config = wtsi_clarity::util::config->new();
#   my $base_uri = $config->clarity_api->{'base_uri'};

#   my $m = wtsi_clarity::epp::generic::workflow_assigner->new(
#     process_url => $base_uri .'/processes/24-103777',
#     new_wf => 'new_workflow'
#   );

#   my $req = XML::LibXML->load_xml( string => $m->_make_request() );

#   print $req;
#   my $expected_raw = q{<?xml version="1.0" encoding="utf-8"?>
#                         <rt:routing xmlns:rt="http://genologics.com/ri/routing">
#                           <assign workflow-uri="http://testserver.com:1234/api/v2/configuration/workflows/999">
#                             <artifact uri="http://testserver.com:1234/api/v2/artifacts/2-00001"/>
#                             <artifact uri="http://testserver.com:1234/api/v2/artifacts/2-00002"/>
#                           </assign>
#                         </rt:routing> };
#   my $expected = XML::LibXML->load_xml(string => $expected_raw );

#   print $expected;

#  my $comparer = XML::SemanticDiff->new();

#   my @differences = $comparer->compare($req, $expected);
#   cmp_ok(scalar @differences, '==', 0, '_make_request should creates the correct request');


#   # my $m = wtsi_clarity::epp::generic::workflow_assigner->new();


# }

1;
