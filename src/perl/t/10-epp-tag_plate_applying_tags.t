use strict;
use warnings;
use Test::MockObject::Extends;
use Test::More tests => 20;

sub get_fake_response {
  my $response_file = shift;
  my $response = do {
    local $/ = undef;
    open my $fh, "<", $response_file
        or die "could not open $response_file: $!";
    <$fh>;
  };

  return $response;
}

my $chome_name = 'WTSI_CLARITY_HOME';
my $test_dir = 't/data/sm/tag_plate';

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
local $ENV{$chome_name}= q[t/data/config];

use_ok('wtsi_clarity::epp::sm::tag_plate');

my $epp = wtsi_clarity::epp::sm::tag_plate->new(
    process_url           => 'http://some.com/processes/151-12090',
    step_url              => 'http://some.com/steps/151-16106',
    tag_layout_file_name  => 'test_layout_file_name',
  );

# tests whether the attributtes are correct
{
  isa_ok( $epp, 'wtsi_clarity::epp::sm::tag_plate');

  is($epp->_tag_plate_barcode, '1234567890123', 'Gets the tag plate barcode correctly');
  is($epp->_gatekeeper_url, 'http://dev.psd.sanger.ac.uk:6610/api/1', 'Gets the correct url for Gatekeeper.');
  is($epp->_find_qcable_by_barcode_uuid, '11111111-2222-3333-4444-555555555555', 'Gets the _find_qcable_by_barcode_uuid correctly');
  is($epp->_valid_status, 'available', 'Gets the valid status correctly');
  is($epp->_valid_lot_type, 'IDT Tags', 'Gets the valid lot type correctly');
}

# tests to get the artifacts URIs from '/reagents' response
{
  my $reagents_response_file = $test_dir. '/GET/reagents/151-16105';
  my $reagents_response = get_fake_response($reagents_response_file);

  my $mocked_reagents_request = Test::MockObject::Extends->new( $epp->request );
  $mocked_reagents_request->mock(q(get), sub{my ($self, $uri) = @_; return $reagents_response;});

  my $reagents = $epp->_get_reagents;
  my $reagent_uris = $epp->_get_reagent_uris($reagents);

  isa_ok($reagent_uris, 'ARRAY', 'Gets the artifacts URI of the reagents');
  cmp_ok(scalar @{$reagent_uris}, '==', 4, 'There should be only 4 reagent (only get the analyte type, no ResultFile).');

  my @expected_result = ( 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34205',
                          'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34206',
                          'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34207',
                          'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34208',
                        );
  is_deeply($reagent_uris, \@expected_result, 'We get the expected 4 reagents.');
}

# tests to retrieve the reagent artifacts from a batch request
{
  my $reagents_response_file = $test_dir. '/GET/reagents/151-16105';
  my $reagents_response = get_fake_response($reagents_response_file);

  my $mocked_reagents_request = Test::MockObject::Extends->new( $epp->request );
  $mocked_reagents_request->mock(q(get), sub{my ($self, $uri) = @_; return $reagents_response;});

  my $reagents = $epp->_get_reagents;
  my $reagent_uris = $epp->_get_reagent_uris($reagents);

  my $reagent_artifacts_batch_response_file = $test_dir. '/POST/batch/artifacts';
  my $reagent_artifacts_response = get_fake_response($reagent_artifacts_batch_response_file);

  my $mocked_batch_artifact_request = Test::MockObject::Extends->new( $epp->request );
  $mocked_batch_artifact_request->mock(q(batch_retrieve), sub{my ($self, $uri, $content) = @_; return $reagent_artifacts_response;});

  my $reagent_artifacts = $epp->_get_reagent_artifacts($reagent_uris);

  isa_ok($reagent_artifacts, 'ARRAY', 'Gets the artifacts URI of the reagents');
  cmp_ok(scalar @{$reagent_artifacts}, '==', 4, 'There should be only 4 reagent artifacts (only get the analyte type, no ResultFile).');

  my @expected_artifact_names = ('1_LibPCR', '9_LibPCR', '17_LibPCR', '25_LibPCR');

  my $i = 0;
  foreach my $reagent_artifact (@{$reagent_artifacts}) {
    my $reagent_name = $reagent_artifact->getElementsByTagName('name')->[0]->textContent;
    is($reagent_name, $expected_artifact_names[$i], "The retrieved artifact name ($reagent_name) is correct.");
    $i++;
  }

  # tests if the proper reagent-label tags were added to the reagents
  {
    # gets the reagents
    my $reagents_response = get_fake_response($test_dir. '/GET/reagents/151-16105');
    my $mocked_reagents_request = Test::MockObject::Extends->new( $epp->request );
    $mocked_reagents_request->mock(q(get), sub{my ($self, $uri) = @_; return $reagents_response;});

    my $reagents = $epp->_get_reagents;

    # gets the artifacts
    my $reagent_uris = $epp->_get_reagent_uris($reagents);

    my $reagent_artifacts_response = get_fake_response($test_dir. '/POST/batch/artifacts');
    my $mocked_batch_artifact_request = Test::MockObject::Extends->new( $epp->request );
    $mocked_batch_artifact_request->mock(q(batch_retrieve), sub{my ($self, $uri, $content) = @_; return $reagent_artifacts_response;});

    my $reagent_artifacts = $epp->_get_reagent_artifacts($reagent_uris);

    # gets the tag layout
    my $tag_plate_response = get_fake_response($test_dir. '/responses/valid_tag_plate_response.json');
    my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
    $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

    my $tag_plate = $epp->_tag_plate;
    my $lot_uuid = $tag_plate->{'lot_uuid'};

    my $lot_response = get_fake_response($test_dir. '/responses/valid_lot_response.json');
    my $mocked_lot_request = Test::MockObject::Extends->new( $epp->ss_request );
    $mocked_lot_request->mock(q(get), sub{my ($self, $uri) = @_; return $lot_response;});

    my $lot = $epp->_lot($lot_uuid);
    my $template_uuid = $lot->{'template_uuid'};

    my $tag_plate_layout_response = get_fake_response($test_dir. '/responses/valid_tag_plate_layout_response.json');
    my $mocked_tag_plate_layout_request = Test::MockObject::Extends->new( $epp->ss_request );
    $mocked_tag_plate_layout_request->mock(q(get), sub{my ($self, $uri, $content) = @_; return $tag_plate_layout_response;});

    $epp->_set_template_uuid($template_uuid);
    my $tag_plate_layout = $epp->tag_plate_layout($template_uuid);

    # say Dumper $tag_plate_layout;

    
    $epp->add_tags_to_reagents($reagent_artifacts, $tag_plate_layout, $reagents);

    my %expected_result = ( 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34205' => 'Sanger_168tags (ATCACGTT)',
                            'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34206' => 'Sanger_168tags (CGATGTTT)',
                            'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34207' => 'Sanger_168tags (TTAGGCAT)',
                            'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-34208' => 'Sanger_168tags (TGACCACT)',
                          );

    my $output_path_with_new_reagent_labels = q[/stp:reagents/output-reagents/output/reagent-label[starts-with(@name, 'Sanger_168tags')]/..];
    my @output_nodes = $reagents->findnodes($output_path_with_new_reagent_labels)->get_nodelist;

    foreach my $output_node (@output_nodes) {
      my $uri = $output_node->getAttribute('uri');
      my @new_reagent_label = 
        # $output_node->findnodes(q[/output/reagent-label[]/@name [starts-with(., 'Sanger_168tags')]/..]);
        $output_node->findnodes(q[./reagent-label[starts-with(@name, 'Sanger_168tags')]])->get_nodelist;
      is($new_reagent_label[0]->getAttribute('name'), $expected_result{$uri}, "The following artifact: $uri contains the correct reagent-label: $expected_result{$uri}");
    }
  }
}