use strict;
use warnings;
use Moose::Meta::Class;
use Test::More tests => 16;
use Cwd;
use XML::LibXML;

use_ok('wtsi_clarity::util::clarity_elements');

my $result = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_result");
my $fake_class = Moose::Meta::Class->create_anon_class(
  roles => [qw /wtsi_clarity::util::clarity_elements /]
)->new_object();


# Run tests for adding volume element
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_element($xml, 'volume')->textContent, '35.5077', 'Can find the volume');

  $fake_class->set_element($xml, 'volume', '10.0000');

  is($fake_class->find_element($xml, 'volume')->textContent, '10.0000', 'Can find the volume element and has set the volume correctly');

  my @nodes = $xml->findnodes(q{ /smp:sample/udf:field[@name='} . "Volume (\N{U+00B5}L) (SM)" . q{'] });
  ok(@nodes, 'new node found with direct XPath expression');
  is($nodes[0]->textContent, '10.0000', 'volume retrieved correctly');
}

# For when an element doesn't exist yet...
{
  my $xml = XML::LibXML->load_xml(location => cwd . '/t/data/util/element_mapper/test_create');
  is($fake_class->find_element($xml, 'volume'), undef, 'Can\'t find the volume because it doesn\'t exist');
  is($fake_class->find_element($xml, 'date_received'), undef, 'Can\'t find the date received because it doesn\'t exist');

  $fake_class->set_element($xml, 'volume', '10.0000');
  is($fake_class->find_element($xml, 'volume')->textContent, '10.0000', 'Can find the new volume node');

  $fake_class->set_element($xml, 'date_received', '19-05-2014');
  is($fake_class->find_element($xml, 'date_received')->textContent, '19-05-2014', 'Can find the new date_received node');

  my $el = $fake_class->create_udf_element($xml, 'New Field', 'red dog');
  $xml->documentElement()->appendChild($el);
  my @nodes = $xml->findnodes(q{ /smp:sample/udf:field[@name='New Field'] });
  is($nodes[0]->textContent, 'red dog', 'Can find the new udf element');

  $fake_class->update_text($el, 'Blue cat');
  is($nodes[0]->textContent, 'Blue cat', 'new text retrieved');
  $el->removeChildNodes();
  $fake_class->update_text($el, 'Blue ball');
  is($nodes[0]->textContent, 'Blue ball', 'new text retrieved');
}

# set_element_if_absent() only updates an XML element when it is NOT present
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_element($xml, 'volume')->textContent, '35.5077', '(Test fixture)');
  $fake_class->set_element_if_absent($xml, 'volume', '10.0000');
  is($fake_class->find_element($xml, 'volume')->textContent, '35.5077', 'When present, an element should not be updated using set_element_if_absent()');

  is($fake_class->find_element($xml, 'name'), undef, '(Test fixture)');
  $fake_class->set_element_if_absent($xml, 'name', '10.0000');
  is($fake_class->find_element($xml, 'name')->textContent, '10.0000', 'When absent, an element should be updated using set_element_if_absent()');
}


1;
