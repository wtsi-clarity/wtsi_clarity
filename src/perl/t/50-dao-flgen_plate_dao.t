use strict;
use warnings;

use Moose;
use Test::More tests => 13;
use Test::MockObject::Extends;
use Test::Exception;
use XML::LibXML;

use_ok('wtsi_clarity::dao::flgen_plate_dao');
local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

{
  my $lims_id = '27-3314';
  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);
  isa_ok($flgen_plate_dao, 'wtsi_clarity::dao::flgen_plate_dao');
}

{
  my $lims_id = '27-3314';
  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);

  is($flgen_plate_dao->flgen_well_position('A:1', 16, 6), q/S001/, 'Converts well A:1 to Fluidigm well position S001');
  is($flgen_plate_dao->flgen_well_position('B:1', 16, 6), q/S002/, 'Converts well B:1 to Fluidigm well position S002');
  is($flgen_plate_dao->flgen_well_position('A:2', 16, 6), q/S017/, 'Converts well A:2 to Fluidigm well position S017');
  is($flgen_plate_dao->flgen_well_position('P:6', 16, 6), q/S096/, 'Converts well F:6 to Fluidigm well position S096');
}

{
  my $lims_id = '27-3314';

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/flgen_plate_dao';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);

  my $_xml;
  lives_ok { $_xml = $flgen_plate_dao->_artifact_xml} 'got container xml';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($flgen_plate_dao->id_flgen_plate_lims, q{27-3314}, 'Extracts id_flgen_plate_lims');
  is($flgen_plate_dao->plate_barcode_lims, q{8754679423576}, 'Extracts plate_barcode_lims');
  is($flgen_plate_dao->plate_size, 96, 'Gets the plate size from container type');

  my $well = $flgen_plate_dao->_build_well('2-121338');

  my $fake_well = {
    'study_id' => 'SMI102',
    'well_label' => 'S001',
    'sample_uuid' => '9f4dce30-0bff-11e4-b42e-68b59977951e',
    'cost_code' => 4
  };

  is(defined $well->{'last_updated'}, 1, 'Has the last_updated attribute set');

  delete $well->{'last_updated'};

  is_deeply($well, $fake_well, 'Builds a well correctly');
}

1;