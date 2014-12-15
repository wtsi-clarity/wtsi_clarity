use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

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
  lives_ok { $artifact_xml = $study_dao->_artifact_xml} 'got study artifacts';
  is(ref $artifact_xml, 'XML::LibXML::Document', 'Got back an XML Document');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);
  is($study_dao->id, q{SYY154}, 'Returns the correct id of the study');
  is($study_dao->name, q{SS_TEST}, 'Returns the correct name of the study');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $lims_id);
  my $study_json;
  lives_ok { $study_json = $study_dao->to_message } 'can serialize study object';

  like($study_json, qr/$lims_id/, 'Lims id serialised correctly');
  lives_ok { wtsi_clarity::dao::study_dao->thaw($study_json) }
    'can read json string back';
}

1;