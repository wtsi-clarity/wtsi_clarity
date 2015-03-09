use strict;
use warnings;
use XML::LibXML;

use Test::More tests => 16;
use Test::MockObject::Extends;
use Test::Exception;

use wtsi_clarity::epp;

use_ok 'wtsi_clarity::clarity::process';


{
  my $test_dir = 't/data/clarity/process/';
  my $xml = XML::LibXML->load_xml(location => $test_dir . 'process1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $process = wtsi_clarity::clarity::process->new(
    xml => $xml,
    parent => $epp,
  );

  isa_ok($process, 'wtsi_clarity::clarity::process', 'Builds the object correctly');
  can_ok($process, qw/find_parent find_by_artifactlimsid_and_name/);
}

{

  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/roles/clarity_process_io/';

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . 'GET/processes.24-18168');

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $mapping = [
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:3',
              'source_well_sample_limsid' => 'TES155A119',
              'source_well' => 'H:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:3',
              'source_well_sample_limsid' => 'TES155A118',
              'source_well' => 'G:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:2',
              'source_well_sample_limsid' => 'TES155A104',
              'source_well' => 'A:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:2',
              'source_well_sample_limsid' => 'TES155A105',
              'source_well' => 'B:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:2',
              'source_well_sample_limsid' => 'TES155A106',
              'source_well' => 'C:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:2',
              'source_well_sample_limsid' => 'TES155A107',
              'source_well' => 'D:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:2',
              'source_well_sample_limsid' => 'TES155A108',
              'source_well' => 'E:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:8',
              'source_well_sample_limsid' => 'TES155A156',
              'source_well' => 'E:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:2',
              'source_well_sample_limsid' => 'TES155A111',
              'source_well' => 'H:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:2',
              'source_well_sample_limsid' => 'TES155A110',
              'source_well' => 'G:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:3',
              'source_well_sample_limsid' => 'TES155A112',
              'source_well' => 'A:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:3',
              'source_well_sample_limsid' => 'TES155A113',
              'source_well' => 'B:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:3',
              'source_well_sample_limsid' => 'TES155A115',
              'source_well' => 'D:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:3',
              'source_well_sample_limsid' => 'TES155A114',
              'source_well' => 'C:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:3',
              'source_well_sample_limsid' => 'TES155A116',
              'source_well' => 'E:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:3',
              'source_well_sample_limsid' => 'TES155A117',
              'source_well' => 'F:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:8',
              'source_well_sample_limsid' => 'TES155A159',
              'source_well' => 'H:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:9',
              'source_well_sample_limsid' => 'TES155A160',
              'source_well' => 'A:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:7',
              'source_well_sample_limsid' => 'TES155A145',
              'source_well' => 'B:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:7',
              'source_well_sample_limsid' => 'TES155A144',
              'source_well' => 'A:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:6',
              'source_well_sample_limsid' => 'TES155A141',
              'source_well' => 'F:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:7',
              'source_well_sample_limsid' => 'TES155A146',
              'source_well' => 'C:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:6',
              'source_well_sample_limsid' => 'TES155A143',
              'source_well' => 'H:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:6',
              'source_well_sample_limsid' => 'TES155A142',
              'source_well' => 'G:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:8',
              'source_well_sample_limsid' => 'TES155A153',
              'source_well' => 'B:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:8',
              'source_well_sample_limsid' => 'TES155A157',
              'source_well' => 'F:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:8',
              'source_well_sample_limsid' => 'TES155A155',
              'source_well' => 'D:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:8',
              'source_well_sample_limsid' => 'TES155A152',
              'source_well' => 'A:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:9',
              'source_well_sample_limsid' => 'TES155A161',
              'source_well' => 'B:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:8',
              'source_well_sample_limsid' => 'TES155A154',
              'source_well' => 'C:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:8',
              'source_well_sample_limsid' => 'TES155A158',
              'source_well' => 'G:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:9',
              'source_well_sample_limsid' => 'TES155A162',
              'source_well' => 'C:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:12',
              'source_well_sample_limsid' => 'TES155A187',
              'source_well' => 'D:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:11',
              'source_well_sample_limsid' => 'TES155A180',
              'source_well' => 'E:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:12',
              'source_well_sample_limsid' => 'TES155A185',
              'source_well' => 'B:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:12',
              'source_well_sample_limsid' => 'TES155A186',
              'source_well' => 'C:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:11',
              'source_well_sample_limsid' => 'TES155A182',
              'source_well' => 'G:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:11',
              'source_well_sample_limsid' => 'TES155A181',
              'source_well' => 'F:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:11',
              'source_well_sample_limsid' => 'TES155A178',
              'source_well' => 'C:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:11',
              'source_well_sample_limsid' => 'TES155A179',
              'source_well' => 'D:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:12',
              'source_well_sample_limsid' => '3C-97',
              'source_well' => 'H:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:12',
              'source_well_sample_limsid' => 'TES155A189',
              'source_well' => 'F:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:12',
              'source_well_sample_limsid' => 'TES155A184',
              'source_well' => 'A:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:11',
              'source_well_sample_limsid' => 'TES155A183',
              'source_well' => 'H:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:12',
              'source_well_sample_limsid' => 'TES155A188',
              'source_well' => 'E:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:12',
              'source_well_sample_limsid' => 'TES155A190',
              'source_well' => 'G:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:9',
              'source_well_sample_limsid' => 'TES155A164',
              'source_well' => 'E:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:9',
              'source_well_sample_limsid' => 'TES155A165',
              'source_well' => 'F:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:10',
              'source_well_sample_limsid' => 'TES155A171',
              'source_well' => 'D:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:10',
              'source_well_sample_limsid' => 'TES155A172',
              'source_well' => 'E:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:2',
              'source_well_sample_limsid' => 'TES155A109',
              'source_well' => 'F:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:9',
              'source_well_sample_limsid' => 'TES155A166',
              'source_well' => 'G:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:9',
              'source_well_sample_limsid' => 'TES155A167',
              'source_well' => 'H:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:9',
              'source_well_sample_limsid' => 'TES155A163',
              'source_well' => 'D:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:11',
              'source_well_sample_limsid' => 'TES155A177',
              'source_well' => 'B:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:10',
              'source_well_sample_limsid' => 'TES155A174',
              'source_well' => 'G:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:10',
              'source_well_sample_limsid' => 'TES155A173',
              'source_well' => 'F:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:10',
              'source_well_sample_limsid' => 'TES155A175',
              'source_well' => 'H:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:10',
              'source_well_sample_limsid' => 'TES155A168',
              'source_well' => 'A:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:10',
              'source_well_sample_limsid' => 'TES155A169',
              'source_well' => 'B:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:10',
              'source_well_sample_limsid' => 'TES155A170',
              'source_well' => 'C:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:11',
              'source_well_sample_limsid' => 'TES155A176',
              'source_well' => 'A:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:5',
              'source_well_sample_limsid' => 'TES155A133',
              'source_well' => 'F:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:5',
              'source_well_sample_limsid' => 'TES155A134',
              'source_well' => 'G:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:5',
              'source_well_sample_limsid' => 'TES155A135',
              'source_well' => 'H:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:7',
              'source_well_sample_limsid' => 'TES155A148',
              'source_well' => 'E:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:7',
              'source_well_sample_limsid' => 'TES155A147',
              'source_well' => 'D:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:7',
              'source_well_sample_limsid' => 'TES155A151',
              'source_well' => 'H:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:7',
              'source_well_sample_limsid' => 'TES155A150',
              'source_well' => 'G:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:7',
              'source_well_sample_limsid' => 'TES155A149',
              'source_well' => 'F:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:4',
              'source_well_sample_limsid' => 'TES155A124',
              'source_well' => 'E:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:6',
              'source_well_sample_limsid' => 'TES155A136',
              'source_well' => 'A:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:6',
              'source_well_sample_limsid' => 'TES155A137',
              'source_well' => 'B:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:6',
              'source_well_sample_limsid' => 'TES155A138',
              'source_well' => 'C:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:6',
              'source_well_sample_limsid' => 'TES155A139',
              'source_well' => 'D:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:6',
              'source_well_sample_limsid' => 'TES155A140',
              'source_well' => 'E:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:5',
              'source_well_sample_limsid' => 'TES155A131',
              'source_well' => 'D:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:5',
              'source_well_sample_limsid' => 'TES155A132',
              'source_well' => 'E:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:5',
              'source_well_sample_limsid' => 'TES155A128',
              'source_well' => 'A:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:4',
              'source_well_sample_limsid' => 'TES155A126',
              'source_well' => 'G:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:5',
              'source_well_sample_limsid' => 'TES155A129',
              'source_well' => 'B:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:5',
              'source_well_sample_limsid' => 'TES155A130',
              'source_well' => 'C:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:4',
              'source_well_sample_limsid' => 'TES155A121',
              'source_well' => 'B:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:4',
              'source_well_sample_limsid' => 'TES155A120',
              'source_well' => 'A:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:4',
              'source_well_sample_limsid' => 'TES155A122',
              'source_well' => 'C:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:4',
              'source_well_sample_limsid' => 'TES155A123',
              'source_well' => 'D:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:4',
              'source_well_sample_limsid' => 'TES155A127',
              'source_well' => 'H:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:4',
              'source_well_sample_limsid' => 'TES155A125',
              'source_well' => 'F:4'
            }
          ];

  my $plate_io_map = [
    {
      'source_plate' => '27-216',
      'dest_plate' => '27-1897'
    }
  ];

  is_deeply($process->io_map, $mapping, 'Creates the io map correctly');
  is_deeply($process->plate_io_map, $plate_io_map, 'Creates the plate io map');
}

{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/roles/clarity_process_io/';

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'http://testserver.com:1234/here/processes/24-22472'
    )
  );

  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . 'GET/processes.24-22472');

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $plate_io_map = [
    {
      'source_plate' => '27-390',
      'dest_plate' => '27-2319'
    },
    {
      'source_plate' => '27-390',
      'dest_plate' => '27-2320'
    }
  ];

  is_deeply($process->plate_io_map, $plate_io_map, 'Creates the plate io map correctly when multiple output plates');

  my $plate_io_map_barcodes = [
    {
      'source_plate' => '5260027390767',
      'dest_plate' => '27-2319'
    },
    {
      'source_plate' => '5260027390767',
      'dest_plate' => '27-2320'
    }
  ];

  is_deeply($process->plate_io_map_barcodes, $plate_io_map_barcodes, 'Creates the plate io map with barcodes correctly');
}

{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/process/';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'http://testserver.com:1234/here/processes/24-27770'
    )
  );

  my $xml = XML::LibXML->load_xml(location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . 'GET/processes.24-27770');

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $expected_result_file_location = "sftp://clarity.co/path/2015/02/24-27770/92-199558-40-1414.csv";
  is($process->get_result_file_location, $expected_result_file_location, 'Gets the correct location of a result file.');
}

# find_by_artifactlimsid_and_name
{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/process';

  my $test_dir = 't/data/clarity/process/';

  my $xml = XML::LibXML->load_xml(location => $test_dir . 'process1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $process_xml = $process->find_by_artifactlimsid_and_name('2-185639', 'Pico DTX (SM)');

  isa_ok($process_xml, 'XML::LibXML::Document', 'Fetches the process XML correctly for input artifact 2-185639');
  is($process_xml->findvalue('prc:process/type'), 'Pico DTX (SM)', 'The process is of the correct type');
  is($process_xml->findvalue('prc:process/@limsid'), '24-26697', 'Fetches the process with the higher limsid');

  is($process->find_by_artifactlimsid_and_name('123', 'Nothing'), 0, 'Returns 0 when no processes are found');
}

# _find_highest_limsid
{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/process';

  my $test_dir = 't/data/clarity/process/';

  my $xml = XML::LibXML->load_xml(location => $test_dir . 'process1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $limsids = ['24-1', '24-2', '24-3', '24-4'];
  is($process->_find_highest_limsid($limsids), '24-4', 'Finds the highest limsids');

  my $limsids2 = ['24-26692', '24-26697'];
  is($process->_find_highest_limsid($limsids2), '24-26697', 'Finds the highest limsids');
}

{
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/clarity/process';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $test_dir = 't/data/clarity/process/';

  my $xml = XML::LibXML->load_xml(location => $test_dir . 'process1.xml');

  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp->new(
      process_url => 'does not matter'
    )
  );

  my $process = wtsi_clarity::clarity::process->new(xml => $xml, parent => $epp);

  my $expected_container_name = '2460274212833';

  is($process->get_container_name_by_limsid('27-4212'), $expected_container_name, 'Returns the expected container name');
  throws_ok { $process->get_container_name_by_limsid('not-exists')}
    qr/Could not find the name of container with the given limsid: not-exists/,
    'error when the name of the container could not be found';
}

1;