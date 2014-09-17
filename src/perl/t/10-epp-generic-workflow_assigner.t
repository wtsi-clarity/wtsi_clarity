use strict;
use warnings;
use Test::More tests => 10;
use XML::LibXML;
use Test::Exception;

{
  use_ok('wtsi_clarity::epp::generic::workflow_assigner', 'can use wtsi_clarity::epp::generic::workflow_assigner' );

  my $data_raw = q{<?xml version="1.0" standalone="yes"?><wkfcnf:workflows xmlns:wkfcnf="http://genologics.com/ri/workflowconfiguration"><workflow status="ACTIVE" uri="uri0" name="really?"/><workflow status="ACTIVE" uri="uri1" name="my workflow"/><workflow status="ACTIVE" uri="uri2" name="my other workflow"/></wkfcnf:workflows>   };
  my $workflows = XML::LibXML->load_xml(string => $data_raw );

  my $uri = wtsi_clarity::epp::generic::workflow_assigner::_get_workflow_url("my workflow", $workflows);
  cmp_ok($uri, 'eq', 'uri1', q{_get_workflow_url should find the correct the uri.} );
  throws_ok { wtsi_clarity::epp::generic::workflow_assigner::_get_workflow_url('not there', $workflows); }
    qr{Workflow 'not there' not found}, '_get_workflow_url should croak if the workflow cannot be found.'
}

{
  use_ok('wtsi_clarity::epp::generic::workflow_assigner', 'can use wtsi_clarity::epp::generic::workflow_assigner' );

  my @uris =  ( 'uri1',
                'uri2',
                'uri3',
              );

  my @expected_values = ( 'uri1',
                          'uri2',
                          'uri3',
                        );

  my $doc = wtsi_clarity::epp::generic::workflow_assigner::_make_rerouting_request("my_uri", \@uris);
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

1;
