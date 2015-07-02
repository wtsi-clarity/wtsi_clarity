use strict;
use warnings;
use Test::More tests => 52;
use Test::Exception;
use Cwd;
use Carp;
use XML::SemanticDiff;
use DateTime;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/label_creator';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::generic::label_creator');

{
  my $l = wtsi_clarity::epp::generic::label_creator->new(process_url => 'some');
  isa_ok($l, 'wtsi_clarity::epp::generic::label_creator');
  ok (!$l->source_plate, 'source_plate flag is false by default');
  $l = wtsi_clarity::epp::generic::label_creator->new(process_url => 'some', source_plate=>1, printer => 'myprinter');
  ok ($l->source_plate, 'source_plate flag can be set to true');
  lives_ok {$l->printer} 'printer given, no access to process url to get the printer';
}

{
  my $l = wtsi_clarity::epp::generic::label_creator->new(
    process_url => $base_uri . '/processes/24-67069');

  lives_and(sub {is $l->printer, 'd304bc'}, 'correct trimmed printer name');
  lives_and(sub {is $l->user, 'D. Brooks'}, 'correct user name');
  lives_and(sub {is $l->_num_copies, 2}, 'number of copies as given');
  lives_and(sub {is $l->_plate_purpose, 'Stock Plate'}, 'plate purpose as given');

  $l = wtsi_clarity::epp::generic::label_creator->new(
    process_url => $base_uri . '/processes/24-67069');
  my $config = join q[/], $ENV{'HOME'}, '.wtsi_clarity', 'config';
  lives_and(sub {like $l->_get_printer_url('d304bc'), qr/c2ed34d0-7214-0131-2f13-005056a81d80/}, 'got printer url');
}

{
  my $l = wtsi_clarity::epp::generic::label_creator->new(
    process_url => $base_uri . '/processes/24-67069_custom');

  throws_ok { $l->printer} qr/Printer udf field should be defined/, 'error when printer not defined';
  lives_and(sub {is $l->user, q[]}, 'no user name by default');
  lives_and(sub {is $l->_num_copies, 1}, 'default number of copies');
  lives_and(sub {is $l->_plate_purpose, undef}, 'plate purpose undefined');
}

{
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/24-67069',
     source_plate => 1,
     _date => my $dt = DateTime->new(
        year       => 2014,
        month      => 5,
        day        => 21,
        hour       => 15,
        minute     => 04,
        second     => 23,
    ),
  );
  lives_ok {$l->_container} 'got containers';
  my @containers = keys %{$l->_container};
  is (scalar @containers, 1, 'correct number of containers');
  my $container_url = $containers[0];
  is (scalar @{$l->_container->{$container_url}->{'samples'}}, 12, 'correct number of samples');

  my $doc = $l->_container->{$container_url}->{'doc'};
  my @nodes = $doc->findnodes(q{ /con:container/name });
  is ($nodes[0]->textContent(), 'ces_tester_101_', 'old container name');

  lives_ok {$l->_set_container_data} 'container data set';

  @nodes = $doc->findnodes( q{ /con:container/name } );
  is ($nodes[0]->textContent(), '5260271204834', 'new container name');
  my $xml =  $doc->toString;
  like ($xml, qr/WTSI Container Purpose Name\">Stock Plate/, 'container purpose present');
  like ($xml, qr/Supplier Container Name\">ces_tester_101_/, 'container supplier present');

  lives_ok {$l->_set_container_data} 'container data set is run again';
  $xml =  $doc->toString;
  like ($xml, qr/Supplier Container Name\">ces_tester_101_/, 'container supplier unchanged');

  my $label = {
          'label_printer' => { 'footer_text' => {
                                                  'footer_text2' => 'Wed May 21 15:04:23 2014',
                                                  'footer_text1' => 'footer by D. Brooks'
                                                },
                               'header_text' => {
                                                  'header_text2' => 'Wed May 21 15:04:23 2014',
                                                  'header_text1' => 'header by D. Brooks'
                                                },
                               'labels' => [
                                             {
                                               'template' => 'clarity_plate',
                                               'plate' => {
                                                            'ean13' => '5260271204834',
                                                            'label_text' => {
                                                                              'date_user' => '21-May-2014 ',
                                                                              'purpose'   => 'Stock Plate',
                                                                              'num'       => 'SM-271204S',
                                                                              'signature' => 'EL2LO'
                                                                            }
                                                          }
                                             },
                                           ]
                             }
        };
  $label->{'label_printer'}->{'labels'}->[1] = $label->{'label_printer'}->{'labels'}->[0];

  is_deeply($l->_generate_labels(), $label, 'label hash representation');
}

{
  my $dt = DateTime->new(
        year       => 2014,
        month      => 5,
        day        => 21,
        hour       => 15,
        minute     => 04,
        second     => 23,
  );

  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/24-97619',
     increment_purpose => 1,
     _date => $dt,
  );
  lives_ok {$l->_container} 'got containers';
  my @urls = keys %{$l->_container};
  is (scalar @urls, 2, 'correct number of containers');
  is (scalar @{$l->_container->{$urls[0]}->{'samples'}}, 95, 'correct number of samples');
  is (scalar @{$l->_container->{$urls[1]}->{'samples'}}, 95, 'correct number of samples');

  lives_ok {$l->_set_container_data} 'container data set';

  my $label = {
          'label_printer' => {
                               'footer_text' => {
                                                  'footer_text2' => 'Wed May 21 15:04:23 2014',
                                                  'footer_text1' => 'footer by D. Jones'
                                                },
                               'header_text' => {
                                                  'header_text2' => 'Wed May 21 15:04:23 2014',
                                                  'header_text1' => 'header by D. Jones'
                                                },
                               'labels' => [
                                             {
                                               'template' => 'clarity_plate',
                                               'plate' => {
                                                            'ean13' => '5260276710705',
                                                            'label_text' => {
                                                                              'date_user' => '21-May-2014 D. Jones',
                                                                              'purpose'   => 'Pico Assay A',
                                                                              'num'       => 'SM-276710F',
                                                                              'signature' => 'HP2MX'
                                                                            }
                                                          }
                                             },
                                             {
                                               'template' => 'clarity_plate',
                                               'plate' => {
                                                            'ean13' => '5260276711719',
                                                            'label_text' => {
                                                                              'date_user' => '21-May-2014 D. Jones',
                                                                              'purpose'   => 'Pico Assay',
                                                                              'num'       => 'SM-276711G',
                                                                              'signature' => 'HP2MX'
                                                                            }
                                                          }
                                             }
                                           ]
                             }
        };

  is_deeply($l->_generate_labels(), $label, 'label hash representation');

  $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/24-97619',
     _date => $dt,
  );

  lives_ok {$l->_container} 'got containers';
  lives_ok {$l->_set_container_data} 'container data set';

  # increment_purpose flag is false
  $label->{'label_printer'}->{'labels'}->[0]->{'plate'}->{'label_text'}->{'purpose'} = 'Pico Assay';
  is_deeply($l->_generate_labels(), $label, 'purpose is not incremented in the label');

  is($l->_barcode_prefix, 'SM', 'default barcode prefix');
  $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/24-97619_custom',
     _date => $dt,
  );
  is($l->_barcode_prefix, 'IC', 'barcode prefix from the process');
}

{ # label creation after pooling
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26306',
  );
  my $containers;
  lives_ok {$containers = $l->_container;} 'got containers';
  my @urls = keys %{$containers};
  is (scalar @urls, 1, 'correct number of containers');
}

# signature for when there's only controls e.g. Pico: Run Standard and Control Plate
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/label_creator/no_samples';

  my $label_creator = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/24-28536',
     source_plate => 1,
  );

  $label_creator->_set_container_data();

  my $container = $label_creator->_container->{'http://testserver.com:1234/here/containers/27-4580'};

  is($container->{'signature'}, q{}, 'Signature is blank when there are no samples');
}

{ # get the tube location
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $input_analyte_uri1 = 'http://testserver.com:1234/here/artifacts/LAB106A289PA1?state=63032';
  my $input_analyte_dom1 = $l->fetch_and_parse($input_analyte_uri1);
  my $input_analyte_uri2 = 'http://testserver.com:1234/here/artifacts/LAB106A305PA1?state=63016';
  my $input_analyte_dom2 = $l->fetch_and_parse($input_analyte_uri2);

  my $expected_tube1_location = 'A:1';
  my $expected_tube2_location = 'A:3';

  is($l->_get_tube_location($input_analyte_dom1), $expected_tube1_location,
    'Returns the correct tube location');
  is($l->_get_tube_location($input_analyte_dom2), $expected_tube2_location,
    'Returns the correct tube location');
}

{ # get the Bait Library Name of the sample
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $input_analyte_uri1 = 'http://testserver.com:1234/here/artifacts/LAB106A289PA1?state=63032';
  my $input_analyte_dom1 = $l->fetch_and_parse($input_analyte_uri1);

  my $expected_bait_library_name  = '14M_haemv1';
  my $expected_sample_limsid      = 'LAB106A289';

  is($l->_sample_data($input_analyte_dom1)->{'bait_library_name'}, $expected_bait_library_name,
    'Returns the correct bait library name');
  is($l->_sample_data($input_analyte_dom1)->{'limsid'}, $expected_sample_limsid,
    'Returns the correct limsid of a sample');
}

{ # get the plexing strategy from the Bait Library Name of the sample - 16 plex
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $bait_library_name = '14M_haemv1';

  isa_ok( $l->_plexing_strategy_by_bait_library($bait_library_name),
          'wtsi_clarity::epp::isc::pooling::pooling_by_16_plex',
          'Returns the correct plexing startegy.');
}

{ # get the plexing strategy from the Bait Library Name of the sample - 8 plex
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $bait_library_name = 'V5 Exome';

  isa_ok( $l->_plexing_strategy_by_bait_library($bait_library_name),
          'wtsi_clarity::epp::isc::pooling::pooling_by_8_plex',
          'Returns the correct plexing startegy.');
}

{ # gets the pool range
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $input_analyte_uri1 = 'http://testserver.com:1234/here/artifacts/LAB106A297PA1?state=62966';
  my $input_analyte_dom1 = $l->fetch_and_parse($input_analyte_uri1);
  my $bait_library_name = '14M_haemv1';

  my $expected_pool_range = 'A5H6';
  is( $l->_pooling_range($input_analyte_dom1, $bait_library_name), $expected_pool_range,
      'Returns the correct pool range.');
}

{ # gets an exception message when pool range is outside of allowed values
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . '/processes/122-26669',
  );

  my $input_analyte_uri1 = 'http://testserver.com:1234/here/artifacts/LAB106A321PA1?state=62964';
  my $input_analyte_dom1 = $l->fetch_and_parse($input_analyte_uri1);
  my $bait_library_name = '14M_haemv1';

  throws_ok { $l->_pooling_range($input_analyte_dom1, $bait_library_name)}
              qr/Pool name \(A:5\) is not defined for this destination well /,
              'error when pool name not defined';
}

{ # search artifact by process and samplelimsid
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . 'anything',
  );

  my $samplelimsid = 'SV2454A149';
  my $process_type = 'Lib PCR Purification';

  my $expected_file = q{expected_artifact_by_samplelimsid_and_processtype.xml};
  my $testdata_dir  = q{/t/data/epp/generic/label_creator/};
  my $expected_container_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare(
    $l->_search_artifact_by_process_and_samplelimsid($process_type, $samplelimsid), $expected_container_xml);
  cmp_ok(scalar @differences, '==', 0, 'Returns the correct artifact XML.');
}

{ # gets an exception message when the artifact could not be found
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . 'anything',
  );

  my $samplelimsid = 'SV2454A999';
  my $process_type = 'Lib PCR Purification';

  throws_ok { $l->_search_artifact_by_process_and_samplelimsid($process_type, $samplelimsid)}
              qr/The artifact could not be found by the given process\: 'Lib PCR Purification' and samplelimsid: 'SV2454A999'./,
              'error when the artifact could not be found';
}

{ # Test for getting the container doc
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . 'anything',
  );

  my $samplelimsid = 'SV2454A149';
  my $process_type = 'Lib PCR Purification';
  my $artifact_doc = $l->_search_artifact_by_process_and_samplelimsid($process_type, $samplelimsid);

  my $expected_file = q{expected_container_by_artifact.xml};
  my $testdata_dir  = q{/t/data/epp/generic/label_creator/};
  my $expected_container_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare(
    $l->_container_doc($artifact_doc), $expected_container_xml);
  cmp_ok(scalar @differences, '==', 0, 'Returns the correct container XML.');
}

{ # Test for getting the signature UDF field from the container
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . 'anything',
  );

  my $samplelimsid = 'SV2454A149';
  my $process_type = 'Lib PCR Purification';
  my $artifact_doc = $l->_search_artifact_by_process_and_samplelimsid($process_type, $samplelimsid);
  my $container_xml = $l->_container_doc($artifact_doc);

  my $expected_signature = 'aBcDe';

  is( $l->_signature_from_container($container_xml), $expected_signature,
      'Returns the correct signature.');
}

{ # Test for getting the signature UDF field from the container
  my $l = wtsi_clarity::epp::generic::label_creator->new(
     process_url => $base_uri . 'anything',
  );

  my $samplelimsid = 'SV2454A159';
  my $process_type = 'Lib PCR Purification';
  my $artifact_doc = $l->_search_artifact_by_process_and_samplelimsid($process_type, $samplelimsid);
  my $container_xml = $l->_container_doc($artifact_doc);

  throws_ok { $l->_signature_from_container($container_xml)}
              qr/The signature has not been registered on this container./,
              'error when the signature could not be found';
}

1;
