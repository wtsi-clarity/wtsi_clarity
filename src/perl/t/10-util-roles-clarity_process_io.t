use strict;
use warnings;
use Test::More tests => 5;
use Moose::Meta::Class;

use_ok('wtsi_clarity::util::roles::clarity_process_io');

my $epp = Moose::Meta::Class->create_anon_class(
  superclasses => ['wtsi_clarity::epp'],
  roles => ['wtsi_clarity::util::roles::clarity_process_io']
);

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/roles/clarity_process_io/';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

{
  my $process = $epp->new_object(
    process_url => 'http://testserver.com:1234/here/processes/24-18168',
  );

  my $mapping = [
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:3',
              'source_well' => 'H:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:3',
              'source_well' => 'G:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:2',
              'source_well' => 'A:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:2',
              'source_well' => 'B:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:2',
              'source_well' => 'C:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:2',
              'source_well' => 'D:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:2',
              'source_well' => 'E:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:8',
              'source_well' => 'E:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:2',
              'source_well' => 'H:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:2',
              'source_well' => 'G:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:3',
              'source_well' => 'A:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:3',
              'source_well' => 'B:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:3',
              'source_well' => 'D:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:3',
              'source_well' => 'C:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:3',
              'source_well' => 'E:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:3',
              'source_well' => 'F:3'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:8',
              'source_well' => 'H:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:9',
              'source_well' => 'A:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:7',
              'source_well' => 'B:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:7',
              'source_well' => 'A:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:6',
              'source_well' => 'F:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:7',
              'source_well' => 'C:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:6',
              'source_well' => 'H:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:6',
              'source_well' => 'G:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:8',
              'source_well' => 'B:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:8',
              'source_well' => 'F:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:8',
              'source_well' => 'D:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:8',
              'source_well' => 'A:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:9',
              'source_well' => 'B:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:8',
              'source_well' => 'C:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:8',
              'source_well' => 'G:8'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:9',
              'source_well' => 'C:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:12',
              'source_well' => 'D:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:11',
              'source_well' => 'E:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:12',
              'source_well' => 'B:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:12',
              'source_well' => 'C:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:11',
              'source_well' => 'G:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:11',
              'source_well' => 'F:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:11',
              'source_well' => 'C:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:11',
              'source_well' => 'D:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:12',
              'source_well' => 'H:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:12',
              'source_well' => 'F:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:12',
              'source_well' => 'A:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:11',
              'source_well' => 'H:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:12',
              'source_well' => 'E:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:12',
              'source_well' => 'G:12'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:9',
              'source_well' => 'E:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:9',
              'source_well' => 'F:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:10',
              'source_well' => 'D:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:10',
              'source_well' => 'E:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:2',
              'source_well' => 'F:2'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:9',
              'source_well' => 'G:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:9',
              'source_well' => 'H:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:9',
              'source_well' => 'D:9'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:11',
              'source_well' => 'B:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:10',
              'source_well' => 'G:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:10',
              'source_well' => 'F:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:10',
              'source_well' => 'H:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:10',
              'source_well' => 'A:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:10',
              'source_well' => 'B:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:10',
              'source_well' => 'C:10'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:11',
              'source_well' => 'A:11'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:5',
              'source_well' => 'F:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:5',
              'source_well' => 'G:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:5',
              'source_well' => 'H:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:7',
              'source_well' => 'E:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:7',
              'source_well' => 'D:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:7',
              'source_well' => 'H:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:7',
              'source_well' => 'G:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:7',
              'source_well' => 'F:7'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:4',
              'source_well' => 'E:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:6',
              'source_well' => 'A:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:6',
              'source_well' => 'B:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:6',
              'source_well' => 'C:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:6',
              'source_well' => 'D:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:6',
              'source_well' => 'E:6'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:5',
              'source_well' => 'D:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'E:5',
              'source_well' => 'E:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:5',
              'source_well' => 'A:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'G:4',
              'source_well' => 'G:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:5',
              'source_well' => 'B:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:5',
              'source_well' => 'C:5'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'B:4',
              'source_well' => 'B:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'A:4',
              'source_well' => 'A:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'C:4',
              'source_well' => 'C:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'D:4',
              'source_well' => 'D:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'H:4',
              'source_well' => 'H:4'
            },
            {
              'source_plate' => '27-216',
              'dest_plate' => '27-1897',
              'dest_well' => 'F:4',
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
  my $process = $epp->new_object(
    process_url => 'http://testserver.com:1234/here/processes/24-22472',
  );

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