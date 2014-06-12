use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;

use_ok('wtsi_clarity::epp::sm::plate_purpose', 'can use wtsi_clarity::epp::sm::plate_purpose' );


sub find_elements {
  my ($xml, $name) = @_;
  my $parser = XML::LibXML->new;
  my $doc = $parser->parse_string($xml);
  my $xpc = XML::LibXML::XPathContext->new($doc->getDocumentElement());
  return $xpc->findnodes($name);
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/plate_purpose';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $plate_purpose = wtsi_clarity::epp::sm::plate_purpose->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-99911');

  lives_ok { $plate_purpose->_fetch_and_update_containers($plate_purpose->process_doc) } 'managed to fetch and updates the containers';

  cmp_ok(scalar keys %{$plate_purpose->_containers}, '==', 1,
    'There should be only one container for the 5 artifacts as they have the same container.');

  my $PURPOSE_PATH = '/con:container/udf:field';

  foreach my $containerURI (keys %{$plate_purpose->_containers})
  {
    my @elements = find_elements( $plate_purpose->_containers->{$containerURI}, $PURPOSE_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The purpose has been added to the container.');
  }
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/plate_purpose';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $plate_purpose = wtsi_clarity::epp::sm::plate_purpose->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-99912');

  lives_ok { $plate_purpose->_fetch_and_update_containers($plate_purpose->process_doc) } 'managed to fetch and updates the containers';

  cmp_ok(scalar keys %{$plate_purpose->_containers}, '==', 2,
    'There should be two containers for the 5 artifacts as they have different containers.');

  my $PURPOSE_PATH = '/con:container/udf:field';

  foreach my $containerURI (keys %{$plate_purpose->_containers})
  {
    my @elements = find_elements( $plate_purpose->_containers->{$containerURI}, $PURPOSE_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The purpose has been added to the container.');
  }
}

1;
