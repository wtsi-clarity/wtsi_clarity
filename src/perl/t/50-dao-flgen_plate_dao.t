use strict;
use warnings;

use Moose;
use Test::More tests => 25;
use Test::MockObject::Extends;
use Test::Exception;
use XML::LibXML;

use_ok('wtsi_clarity::dao::flgen_plate_dao');
local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

{
  my $lims_id = '27-3314';
  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);
  isa_ok($flgen_plate_dao, 'wtsi_clarity::dao::flgen_plate_dao');
}

{
  my $lims_id = '27-3314';
  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(
    lims_id    => $lims_id,
    plate_size => 96,
  );

  is($flgen_plate_dao->flgen_well_position('A:1', 16, 6), q/S01/, 'Converts well A:1 to Fluidigm well position S01 for a 96.96 plate');
  is($flgen_plate_dao->flgen_well_position('B:1', 16, 6), q/S07/, 'Converts well B:1 to Fluidigm well position S02 for a 96.96 plate');
  is($flgen_plate_dao->flgen_well_position('A:2', 16, 6), q/S02/, 'Converts well A:2 to Fluidigm well position S17 for a 96.96 plate');
  is($flgen_plate_dao->flgen_well_position('F:2', 16, 6), q/S32/, 'Converts well F:2 to Fluidigm well position S32 for a 96.96 plate');
  is($flgen_plate_dao->flgen_well_position('P:6', 16, 6), q/S96/, 'Converts well F:6 to Fluidigm well position S96 for a 96.96 plate');

  my $big_flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(
    lims_id    => $lims_id,
    plate_size => 192,
  );

  is($big_flgen_plate_dao->flgen_well_position('A:1', 16, 12), q/S001/, 'Converts well A:1 to Fluidigm well position S001 for a 192.24 plate');
  is($big_flgen_plate_dao->flgen_well_position('B:1', 16, 12), q/S013/, 'Converts well B:1 to Fluidigm well position S002 for a 192.24 plate');
  is($big_flgen_plate_dao->flgen_well_position('A:2', 16, 12), q/S002/, 'Converts well A:2 to Fluidigm well position S017 for a 192.24 plate');
  is($big_flgen_plate_dao->flgen_well_position('I:3', 16, 12), q/S099/, 'Converts well I:3 to Fluidigm well position S099 for a 192.24 plate');
  is($big_flgen_plate_dao->flgen_well_position('P:6', 16, 12), q/S186/, 'Converts well F:6 to Fluidigm well position S096 for a 192.24 plate');

  my $crazy_flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(
    lims_id    => $lims_id,
    plate_size => 3131313131,
  );

  throws_ok {
    $crazy_flgen_plate_dao->flgen_well_position('A:1', 16, 12);
  } qr/Unknown well format for 3131313131 size plate/,
  "Throws an error when it doesn't know how to format a plate that's not 96 or 192";
}

{
  my $lims_id = '27-3314';

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/flgen_plate_dao';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);

  my $_xml;
  lives_ok {
    $_xml = $flgen_plate_dao->_artifact_xml
  } 'got container xml';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($flgen_plate_dao->id_flgen_plate_lims, q{27-3314}, 'Extracts id_flgen_plate_lims');
  is($flgen_plate_dao->plate_barcode_lims, q{8754679423576}, 'Extracts plate_barcode_lims');
  is($flgen_plate_dao->plate_size, 96, 'Gets the plate size from container type');
  is($flgen_plate_dao->plate_size_occupied, 2, 'Gets the occupied plate size from the count of the wells correctly');

  my $well = $flgen_plate_dao->_build_well('2-121338');

  my $fake_well = {
    'study_id' => 'SMI102',
    'well_label' => 'S01',
    'sample_uuid' => '9f4dce30-0bff-11e4-b42e-68b59977951e',
    'cost_code' => 4
  };

  is(defined $well->{'last_updated'}, 1, 'Has the last_updated attribute set');

  delete $well->{'last_updated'};

  is_deeply($well, $fake_well, 'Builds a well correctly');
}

{
  my $lims_id = '27-3315';

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/flgen_plate_dao';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);

  throws_ok {
    $flgen_plate_dao->init
  } qr/Validation for value 132 failed. The barcode must have a length of 10./,
  'Throws an error when the plate barcode is not a valid Fluidigm one';
}

{
  my $lims_id = '27-3315';

  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => $lims_id);

  throws_ok {
    $flgen_plate_dao->flgen_well_position("A:G", 5, 5)
  } qr/Well location format .{5} is not recognised/, "Letter:letter fails";
  throws_ok {
    $flgen_plate_dao->flgen_well_position("1:2", 5, 5)
  } qr/Well location format .{5} is not recognised/, "Number:number fails";
  throws_ok {
    $flgen_plate_dao->flgen_well_position("4:G", 5, 5)
  } qr/Well location format .{5} is not recognised/, "Number:letter fails";
}

1;