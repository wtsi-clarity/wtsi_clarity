use strict;
use warnings;
use Test::More tests => 3;

use_ok('wtsi_clarity::isc::pooling::mapper', 'can use ISC Pooling mapper');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/isc/pooling/mapper';

{
  my $container_id = '27-1';
  my $mapper = wtsi_clarity::isc::pooling::mapper->new(
    container_id => $container_id
  );

  isa_ok( $mapper, 'wtsi_clarity::isc::pooling::mapper');

  my $expected_mapping = [
    { 'source_plate' => '27-1', 'source_well' =>  'A:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:1', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:2', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:3', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:4', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:5', 'dest_plate' => 'temp_1', 'dest_well' =>  'E:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:6', 'dest_plate' => 'temp_1', 'dest_well' =>  'F:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:7', 'dest_plate' => 'temp_1', 'dest_well' =>  'G:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:8', 'dest_plate' => 'temp_1', 'dest_well' =>  'H:1' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:9', 'dest_plate' => 'temp_1', 'dest_well' =>  'A:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:10', 'dest_plate' => 'temp_1', 'dest_well' =>  'B:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:11', 'dest_plate' => 'temp_1', 'dest_well' =>  'C:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'A:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'B:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'C:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'D:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'E:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'F:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'G:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
    { 'source_plate' => '27-1', 'source_well' =>  'H:12', 'dest_plate' => 'temp_1', 'dest_well' =>  'D:2' },
  ];

  is_deeply($mapper->mapping, $expected_mapping, qq/Should return the correct mapping for the source container./);
}

1;