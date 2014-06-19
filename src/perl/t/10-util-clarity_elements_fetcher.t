use strict;
use warnings;
use Moose::Meta::Class;
use Test::More tests => 16;
use Cwd;
use XML::LibXML;

use_ok('wtsi_clarity::util::clarity_elements_fetcher');

my $fake_class = Moose::Meta::Class->create_anon_class(
  roles => [qw /wtsi_clarity::util::clarity_elements_fetcher/]
)->new_object();


# Run tests for adding volume element
{
  my $xml = XML::LibXML->load_xml(location => cwd . "/t/data/util/element_mapper/test_update");


  $fake_class->fetch_targets_hash($xml, q/Volume (µL) (SM)/ )
  }

1;
