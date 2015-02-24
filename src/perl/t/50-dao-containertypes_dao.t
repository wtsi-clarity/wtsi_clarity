use strict;
use warnings;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;
use XML::LibXML;

use_ok('wtsi_clarity::dao::containertypes_dao');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

{
  my $lims_id = '12';
  my $containertypes_dao = wtsi_clarity::dao::containertypes_dao->new(lims_id => $lims_id);
  isa_ok($containertypes_dao, 'wtsi_clarity::dao::containertypes_dao');
}

{
  my $lims_id = '12';

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/containertypes_dao';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $containertypes_dao = wtsi_clarity::dao::containertypes_dao->new(lims_id => $lims_id);

  my $_xml;
  lives_ok { $_xml = $containertypes_dao->_artifact_xml} 'got container xml';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($containertypes_dao->plate_size, 96, 'Returns the correct plate size');
}

1;