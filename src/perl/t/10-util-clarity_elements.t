use strict;
use warnings;
use Moose::Meta::Class;
use Test::More tests => 36;
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

  is($fake_class->find_udf_element($xml, q/Volume (µL) (SM)/ )->textContent, '35.5077', 'Should find the volume');

  $fake_class->update_udf_element($xml, q/Volume (µL) (SM)/, '10.0000');

  is($fake_class->find_udf_element($xml, q/Volume (µL) (SM)/)->textContent, '10.0000', 'Should find the volume element and set the volume correctly');

  my @nodes = $xml->findnodes(q{/smp:sample/udf:field[@name='Volume (µL) (SM)']});
  ok(@nodes, 'Should new node found with direct XPath expression');
  is($nodes[0]->textContent, '10.0000', 'volume should be retrieved and be correct');
}

# For when an element doesn't exist yet...
{
  my $xml = XML::LibXML->load_xml(location => cwd . '/t/data/util/element_mapper/test_create');
  is($fake_class->find_udf_element($xml, 'volume'), undef, 'Can\'t find the volume because it doesn\'t exist');
  is($fake_class->find_clarity_element($xml, 'date_received'), undef, 'Can\'t find the date received because it doesn\'t exist');

  $fake_class->update_udf_element($xml, 'volume', '10.0000');
  is($fake_class->find_udf_element($xml, 'volume')->textContent, '10.0000', 'Can find the new volume node');

  $fake_class->update_clarity_element($xml, 'date_received', '19-05-2014');
  is($fake_class->find_clarity_element($xml, 'date_received')->textContent, '19-05-2014', 'Can find the new date_received node');

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

# set_udf_element_if_absent() only updates an XML element when it is NOT present
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '35.5077', '(Test fixture)');
  $fake_class->set_udf_element_if_absent($xml, 'Volume (µL) (SM)', '10.0000');
  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '35.5077',
      'When present, an element should not be updated using set_udf_element_if_absent()');

  is($fake_class->find_udf_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->set_udf_element_if_absent($xml, 'nope', '10.0000');
  is($fake_class->find_udf_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using set_udf_element_if_absent()');
}

# set_clarity_element_if_absent() only updates an XML element when it is NOT present
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, '01-05-2014', '(Test fixture)');
  $fake_class->set_clarity_element_if_absent($xml, 'date-received', 'today');
  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, '01-05-2014',
      'When present, an element should not be updated using set_clarity_element_if_absent()');

  is($fake_class->find_clarity_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->set_clarity_element_if_absent($xml, 'nope', '10.0000');
  is($fake_class->find_clarity_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using set_clarity_element_if_absent()');
}


# add_udf_element() updates an XML element regardless of its presence
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '35.5077', '(Test fixture)');
  $fake_class->add_udf_element($xml, 'Volume (µL) (SM)', '10.0000');
  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '10.0000',
      'Even when present, an element should be updated using add_udf_element()');

  is($fake_class->find_udf_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->add_udf_element($xml, 'nope', '10.0000');
  is($fake_class->find_udf_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using add_udf_element()');
}

# add_clarity_element() updates an XML element regardless of its presence
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, '01-05-2014', '(Test fixture)');
  $fake_class->add_clarity_element($xml, 'date-received', 'today');
  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, 'today',
      'Even when present, an element should be updated using add_clarity_element()');

  is($fake_class->find_clarity_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->add_clarity_element($xml, 'nope', '10.0000');
  is($fake_class->find_clarity_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using add_clarity_element()');
}

# update_udf_element() updates an XML element regardless of its presence
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '35.5077', '(Test fixture)');
  $fake_class->update_udf_element($xml, 'Volume (µL) (SM)', '10.0000');
  is($fake_class->find_udf_element($xml, 'Volume (µL) (SM)')->textContent, '10.0000',
      'Even when present, an element should be updated using update_udf_element()');

  is($fake_class->find_udf_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->update_udf_element($xml, 'nope', '10.0000');
  is($fake_class->find_udf_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using update_udf_element()');
}

# update_clarity_element() updates an XML element regardless of its presence
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");

  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, '01-05-2014', '(Test fixture)');
  $fake_class->update_clarity_element($xml, 'date-received', 'today');
  is($fake_class->find_clarity_element($xml, 'date-received')->textContent, 'today',
      'Even when present, an element should be updated using update_clarity_element()');

  is($fake_class->find_clarity_element($xml, 'nope'), undef, '(Test fixture)');
  $fake_class->add_clarity_element($xml, 'nope', '10.0000');
  is($fake_class->find_clarity_element($xml, 'nope')->textContent, '10.0000',
      'When absent, an element should be added using update_clarity_element()');
}



1;
