use strict;
use warnings;
use Test::More tests => 12;
use XML::LibXML;
use Data::Dumper;




{
  use_ok('wtsi_clarity::epp::sm::assign_to_workflow', 'can use wtsi_clarity::epp::sm::assign_to_workflow' );



}




{
  use_ok('wtsi_clarity::epp::sm::assign_to_workflow', 'can use wtsi_clarity::epp::sm::assign_to_workflow' );

  my @uris =  ( 'uri1',
                'uri2',
                'uri3',
              );

  my @expected_values = ( 'uri1',
                          'uri2',
                          'uri3',
                        );

  my $doc = wtsi_clarity::epp::sm::assign_to_workflow::_make_rerouting_request("my_uri", \@uris);
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
