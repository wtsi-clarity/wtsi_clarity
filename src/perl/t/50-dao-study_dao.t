use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;
use JSON;

use_ok('wtsi_clarity::dao::study_dao');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/study_dao';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $lims_id = '1234';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);
  isa_ok($study_dao, 'wtsi_clarity::dao::study_dao');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);

  my $artifact_xml;
  lives_ok { $artifact_xml = $study_dao->artifact_xml} 'got study artifacts';
  is(ref $artifact_xml, 'XML::LibXML::Document', 'Got back an XML Document');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);
  is($study_dao->id, q{SYY154}, 'Returns the correct id of the study');
  is($study_dao->name, q{SS_TEST}, 'Returns the correct name of the study');
  is($study_dao->reference_genome, q{test reference genome}, 'Returns the correct reference genome of the study');
  is($study_dao->state, q{active}, 'Returns the correct state of the study');
  is($study_dao->study_type, q{Exome Sequencing}, 'Returns the correct study type of the study');
  is($study_dao->abstract, q{test abstract}, 'Returns the correct abstract of the study');
  is($study_dao->abbreviation, q{tt}, 'Returns the correct abbreviation of the study');
  is($study_dao->accession_number, q{1111111}, 'Returns the correct accession number of the study');
  is($study_dao->description, q{test description}, 'Returns the correct description of the study');
  is($study_dao->contains_human_dna, q{true}, 'Returns correctly if the sample(s) of the study contains Human DNA');
  is($study_dao->contaminated_human_dna, q{false}, 'Returns correctly if the sample(s) of the study contaminated with Human DNA');
  is($study_dao->data_release_strategy, q{Managed}, 'Returns the correct data release strategy of the study');
  is($study_dao->data_release_timing, q{Standard}, 'Returns the correct data release timing of the study');
  is($study_dao->data_access_group, q{cancer}, 'Returns the correct data access group of the study');
  is($study_dao->study_title, q{Pseudogene RNAseq}, 'Returns the correct title of the study');
  is($study_dao->ega_dac_accession_number, q{1111111}, 'Returns the correct ega dac accession number of the study');
  is($study_dao->remove_x_and_autosomes, q{false}, 'Returns the correct remove_x_and_autosomes flag of the study');
  is($study_dao->separate_y_chromosome_data, q{false}, 'Returns the correct separate_y_chromosome_data flag of the study');

  my $expected_study_user_ids = [21];
  is_deeply($study_dao->study_user_ids, $expected_study_user_ids, 'Returns the correct id of the user of the study');

  my $study_user = [ {name => "John Smith", email => "js123\@test.com", login => "js123"} ];
  is_deeply($study_dao->manager, $study_user, 'Returns the correct user of the study');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);
  my $study_json;
  lives_ok { $study_json = $study_dao->to_message } 'can serialize study object';
}

1;