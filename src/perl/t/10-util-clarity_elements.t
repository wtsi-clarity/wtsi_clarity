use strict;
use warnings;
use Moose::Meta::Class;
use Test::More tests => 7;
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
}

# For when an element doesn't exist yet...
{
  my $xml = XML::LibXML->load_xml(location => cwd . '/t/data/util/element_mapper/test_create');
  is($fake_class->find_element($xml, 'volume'), 0, 'Can\'t find the volume because it doesn\'t exist');
  is($fake_class->find_element($xml, 'date_received'), 0, 'Can\'t find the date received because it doesn\'t exist');

  $fake_class->set_element($xml, 'volume', '10.0000');
  is($fake_class->find_element($xml, 'volume')->textContent, '10.0000', 'Can find the new volume node');

  $fake_class->set_element($xml, 'date_received', '19-05-2014');
  is($fake_class->find_element($xml, 'date_received')->textContent, '19-05-2014', 'Can find the new date_received node');
}
