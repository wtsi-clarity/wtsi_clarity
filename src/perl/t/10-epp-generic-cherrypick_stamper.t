use strict;
use warnings;
use Test::More tests => 23;
use Test::Exception;
use Cwd;
use Carp;
use XML::SemanticDiff;
use File::Temp qw/tempdir/;
use File::Slurp;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/cherrypick_stamper';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::generic::cherrypick_stamper');

{
  my $s = wtsi_clarity::epp::generic::cherrypick_stamper->new(process_url => 'some', step_url => 'some');
  isa_ok($s, 'wtsi_clarity::epp::generic::cherrypick_stamper');
}

{ # gets the base placement XML
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $placement_xml = $stamper->_base_placement_doc;
  isa_ok($placement_xml, 'XML::LibXML::Document');
  is($placement_xml->findnodes(q{/stp:placements/output-placements/output-placement})->size, 0,
    'The base placement doc has not got any output-placement tag.')
}

{ # Gets the first container data
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $expected_basic_container_data = {
    'limsid' => '27-5504',
    'uri' => 'http://testserver.com:1234/here/containers/27-5504'
  };
  is_deeply($stamper->get_basic_container_data, $expected_basic_container_data, 'Got back the correct data of the basic container');
}

{
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $expected_container_type_data = {
    'name' => '96 Well Plate',
    'uri' => 'http://testserver.com:1234/here/containertypes/4'
  };
  my $container_type_data = $stamper->_get_new_container_type_data_by_name('96 Well Plate');
  is_deeply($container_type_data, $expected_container_type_data, 'Got back the correct container type data');
  throws_ok { $stamper->_get_new_container_type_data_by_name('966 Well Plate')}
    qr/Container type can not be found by this name: 966 Well Plate/,
    'Got error when not defined container name';
}

{ # create a new container
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $container_xml = $stamper->create_new_container('96 Well Plate');
  isa_ok($container_xml, 'XML::LibXML::Document');
}

{ # Get container data from new container
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $container_xml = $stamper->create_new_container('96 Well Plate');
  my $expected_container_data = {
    'limsid' => '27-5481',
    'uri' => 'http://testserver.com:1234/here/containers/27-5481',
    'barcode' => '27-5481'
  };
  is_deeply($stamper->get_container_data($container_xml), $expected_container_data, 'Got back the correct data of a new container');
}

{ # add container to placement xml
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $placement_xml = $stamper->_base_placement_doc;
  my $container_count_before = $placement_xml->findnodes(q{/stp:placements/selected-containers/container})->size;
  $stamper->add_container_to_placement($placement_xml, 'http://testserver.com:1234/here/containers/27-9999');
  my $container_count_after = $placement_xml->findnodes(q{/stp:placements/selected-containers/container})->size;
  cmp_ok($container_count_before, '<', $container_count_after, 'Container has been added to the placement doc.');
}

{ # create output placement location values
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my @expected_location_values = (
    'A:1', 'B:1', 'C:1', 'D:1', 'E:1', 'F:1', 'G:1', 'H:1',
    'A:2', 'B:2', 'C:2', 'D:2', 'E:2', 'F:2', 'G:2', 'H:2',
    'A:3', 'B:3', 'C:3', 'D:3', 'E:3', 'F:3', 'G:3', 'H:3',
    'A:4', 'B:4', 'C:4', 'D:4', 'E:4', 'F:4', 'G:4', 'H:4',
    'A:5', 'B:5', 'C:5', 'D:5', 'E:5', 'F:5', 'G:5', 'H:5',
    'A:6', 'B:6', 'C:6', 'D:6', 'E:6', 'F:6', 'G:6', 'H:6',
    'A:7', 'B:7', 'C:7', 'D:7', 'E:7', 'F:7', 'G:7', 'H:7',
    'A:8', 'B:8', 'C:8', 'D:8', 'E:8', 'F:8', 'G:8', 'H:8',
    'A:9', 'B:9', 'C:9', 'D:9', 'E:9', 'F:9', 'G:9', 'H:9',
    'A:10', 'B:10', 'C:10', 'D:10', 'E:10', 'F:10', 'G:10', 'H:10',
    'A:11', 'B:11', 'C:11', 'D:11', 'E:11', 'F:11', 'G:11', 'H:11',
    'A:12', 'B:12', 'C:12', 'D:12', 'E:12', 'F:12', 'G:12', 'H:12',
  );
  is_deeply($stamper->init_96_well_location_values, \@expected_location_values, 'Generates location values correctly.');
}

{ # create a new output-placement tag
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $placement_xml = $stamper->_base_placement_doc;
  my $placement_uri = 'http://testserver.com:1234/here/artifacts/2-223132';
  my $container_data = {
    'limsid' => '27-5236',
    'uri' => 'http://testserver.com:1234/here/containers/27-5236'
  };
  my $location_value = 'A:2';

  my $expected_file = q{expected_placement_fragment.xml};
  my $testdata_dir  = q{/t/data/epp/generic/cherrypick_stamper/};
  my $expected_actions_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare(
    $stamper->create_output_placement_tag($placement_xml, $placement_uri, $container_data, $location_value), $expected_actions_xml);
  cmp_ok(scalar @differences, '==', 0, 'Created output-placement tag correctly');

}

{
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29592',
    step_url    => $base_uri . '/steps/24-29592');

  my $placement_xml = $stamper->build_placement_xml;
  lives_and {is ref($placement_xml), 'XML::LibXML::Document'} 'Builds correct placement XML.';
  lives_ok  {$stamper->post_placement_doc($placement_xml)} 'Successfully POST the placement XML.';
}

{
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => $base_uri . '/processes/24-29896',
    step_url    => 'whatever',
  );

  my @expected = qw/DEA103A625PA1 DEA103A626PA1 DEA103A627PA1 DEA103A530PA1 DEA103A531PA1 DEA103A532PA1/;

  my $sorted_analytes = $stamper->sorted_io($stamper->process_doc, $stamper->init_96_well_location_values);

  foreach my $io ($sorted_analytes->get_nodelist()) {
    is($io->findvalue('./input/@limsid'), shift @expected, 'Inputs are in the correct order');
  }
}

{
  my $stamper = wtsi_clarity::epp::generic::cherrypick_stamper->new(
    process_url => 'whateva',
    step_url    => 'whateva',
  );

  my $analyte_a = { location => 'A:1' };
  my $analyte_b = { location => 'B:1' };

  my $sort_by   = ['A:1', 'B:1', 'C:1', 'D:1', 'E:1', 'F:1', 'G:1', 'H:1'];

  is($stamper->_sort_analyte($sort_by, $analyte_a, $analyte_b), -1, 'Sorts correctly');
  is($stamper->_sort_analyte($sort_by, $analyte_b, $analyte_a), 1, 'Sorts correctly');
  is($stamper->_sort_analyte($sort_by, $analyte_a, $analyte_a), 0, 'Sorts correctly');
}

1;
