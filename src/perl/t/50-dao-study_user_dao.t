use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use_ok('wtsi_clarity::dao::study_user_dao');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/study_user_dao';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $lims_id = '1234';
  my $study_user_dao = wtsi_clarity::dao::study_user_dao->new( lims_id => $lims_id);
  isa_ok($study_user_dao, 'wtsi_clarity::dao::study_user_dao');
}

{
  my $lims_id = '21';
  my $study_user_dao = wtsi_clarity::dao::study_user_dao->new( lims_id => $lims_id);

  my $artifact_xml;
  lives_ok { $artifact_xml = $study_user_dao->_artifact_xml} 'got study_user artifacts';
  is(ref $artifact_xml, 'XML::LibXML::Document', 'Got back an XML Document');
}

{
  my $lims_id = '21';
  my $study_user_dao = wtsi_clarity::dao::study_user_dao->new( lims_id => $lims_id);
  is($study_user_dao->id, q{21}, 'Returns the correct id of the user of the study');
  is($study_user_dao->login, q{js123}, 'Returns the correct user login id of the study');
  is($study_user_dao->email, q{js123@test.com}, 'Returns the correct email of the user of the study');
  is($study_user_dao->first_name, q{John}, 'Returns the correct first name of the user of the study');
  is($study_user_dao->last_name, q{Smith}, 'Returns the correct last name of the user of the study');
  is($study_user_dao->name, q{John Smith}, 'Returns the correct name of the user of the study');
}

{
  my $lims_id = '21';
  my $study_user_dao = wtsi_clarity::dao::study_user_dao->new( lims_id => $lims_id);
  my $study_user_json;
  lives_ok { $study_user_json = $study_user_dao->to_message } 'can serialize study_user object';

  like($study_user_json, qr/$lims_id/, 'Lims id serialised correctly');
  lives_ok { wtsi_clarity::dao::study_user_dao->thaw($study_user_json) }
    'can read json string back';
}

1;