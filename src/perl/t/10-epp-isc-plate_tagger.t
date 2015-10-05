use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use XML::LibXML;


local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/plate_tagger/valid';

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};
my $prefix = q[http://testserver.com:1234/here/artifacts/];
my $test_data_dir = q[t/data/epp/isc/plate_tagger];

local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok ('wtsi_clarity::epp::isc::plate_tagger');

my $epp = wtsi_clarity::epp::isc::plate_tagger->new(
  process_url => $base_uri . '/processes/151-12090',
);
isa_ok( $epp, 'wtsi_clarity::epp::isc::plate_tagger');
is($epp->barcode, 'ABCD1234', 'Gets the tag plate barcode correctly');
lives_ok { $epp->run } 'runs validation';
lives_ok { $epp->run } 'runs marking as used';


my $i = wtsi_clarity::epp::isc::plate_tagger->new(
    process_url => $base_uri . '/processes/24-17451',
);
{
  lives_ok { $i->_index } 'indexing runs ok';
}

{
  my $tag_sequence = "CTTGATGC";
  my $location_index = 11;
  my $expected_reagent_label = qq[Sanger_168tags - 10 mer tags: tag $location_index ($tag_sequence)];
  my $artifact_doc = XML::LibXML->load_xml(
      location => join q[/], $test_data_dir, q[valid/POST/artifacts/2-41782]
  );
  my $analyte_xml = $artifact_doc->findnodes(q[/art:artifact])->[0];

  my $updated_analyte_xml = $i->_add_tags_to_analyte($analyte_xml, $location_index, $tag_sequence);
  my $added_reagent_label_value =
    $updated_analyte_xml->findnodes(q[/art:artifact/reagent-label])->[0]->getAttribute('name');

  is($added_reagent_label_value, $expected_reagent_label, q[Added the correct reagent-label]);
}

{
  my %tags = (
    $prefix .'2-41782' => 'Sanger_168tags - 10 mer tags: tag 5 (ACAGTGGT)',
    $prefix .'2-41783' => 'Sanger_168tags - 10 mer tags: tag 6 (GCCAATGT)',
    $prefix .'2-41784' => 'Sanger_168tags - 10 mer tags: tag 19 (TCTGCTGT)',
    $prefix .'2-41785' => 'Sanger_168tags - 10 mer tags: tag 20 (TTGGAGGT)',
    $prefix .'2-41786' => 'Sanger_168tags - 10 mer tags: tag 17 (TGTACCTT)',
    $prefix .'2-41787' => 'Sanger_168tags - 10 mer tags: tag 18 (TTCTGTGT)',
    $prefix .'2-41788' => 'Sanger_168tags - 10 mer tags: tag 15 (TAAGCGTT)',
    $prefix .'2-41789' => 'Sanger_168tags - 10 mer tags: tag 16 (TCCGTCTT)',
    $prefix .'2-41794' => 'Sanger_168tags - 10 mer tags: tag 39 (TCAGGAGG)',
    $prefix .'2-41795' => 'Sanger_168tags - 10 mer tags: tag 40 (TAAGTTCG)',
    $prefix .'2-41796' => 'Sanger_168tags - 10 mer tags: tag 41 (TCCAGTCG)',
  );

  my $i = wtsi_clarity::epp::isc::plate_tagger->new(
    process_url => $base_uri . '/processes/24-17451',
  );

  $i->_index;

  my $artifacts_xml = $i->_batch_artifacts_doc;
  my @analytes = $artifacts_xml->findnodes(q[art:details/art:artifact[type='Analyte']]);
  my @reagen_label_nodes = $artifacts_xml->findnodes(q[art:details/art:artifact[type='Analyte']/reagent-label]);

  ok(scalar @reagen_label_nodes > 0, 'Reagent-label has been added to the analytes');
  ok(scalar @reagen_label_nodes == scalar @analytes, 'Every analytes has a reagent-label.');

  foreach my $analyte_uri (keys %tags) {
    my $reagent_label =
      $artifacts_xml->findnodes(qq[art:details/art:artifact[contains(\@uri, '$analyte_uri') and type='Analyte']/reagent-label])->[0];

    is($reagent_label->getAttribute('name'), $tags{$analyte_uri}, 'The correct reagent label has been set.')
  }
}

