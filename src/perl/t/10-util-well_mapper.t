use strict;
use warnings;
use Test::More tests => 104;
use Test::Exception;
use Moose::Meta::Class;

use_ok('wtsi_clarity::util::well_mapper');


{ # _get_TECAN_file_content
  my %expected_data = (
    'A:1' =>  1,
    'B:1' =>  2,
    'C:1' =>  3,
    'D:1' =>  4,
    'E:1' =>  5,
    'F:1' =>  6,
    'G:1' =>  7,
    'H:1' =>  8,
    'A:2' =>  9,
    'B:2' => 10,
    'C:2' => 11,
    'D:2' => 12,
    'E:2' => 13,
    'F:2' => 14,
    'G:2' => 15,
    'H:2' => 16,
    'A:3' => 17,
    'B:3' => 18,
    'C:3' => 19,
    'D:3' => 20,
    'E:3' => 21,
    'F:3' => 22,
    'G:3' => 23,
    'H:3' => 24,
    'A:4' => 25,
    'B:4' => 26,
    'C:4' => 27,
    'D:4' => 28,
    'E:4' => 29,
    'F:4' => 30,
    'G:4' => 31,
    'H:4' => 32,
    'A:5' => 33,
    'B:5' => 34,
    'C:5' => 35,
    'D:5' => 36,
    'E:5' => 37,
    'F:5' => 38,
    'G:5' => 39,
    'H:5' => 40,
    'A:6' => 41,
    'B:6' => 42,
    'C:6' => 43,
    'D:6' => 44,
    'E:6' => 45,
    'F:6' => 46,
    'G:6' => 47,
    'H:6' => 48,
    'A:7' => 49,
    'B:7' => 50,
    'C:7' => 51,
    'D:7' => 52,
    'E:7' => 53,
    'F:7' => 54,
    'G:7' => 55,
    'H:7' => 56,
    'A:8' => 57,
    'B:8' => 58,
    'C:8' => 59,
    'D:8' => 60,
    'E:8' => 61,
    'F:8' => 62,
    'G:8' => 63,
    'H:8' => 64,
    'A:9' => 65,
    'B:9' => 66,
    'C:9' => 67,
    'D:9' => 68,
    'E:9' => 69,
    'F:9' => 70,
    'G:9' => 71,
    'H:9' => 72,
    'A:10' =>73,
    'B:10' =>74,
    'C:10' =>75,
    'D:10' =>76,
    'E:10' =>77,
    'F:10' =>78,
    'G:10' =>79,
    'H:10' =>80,
    'A:11' =>81,
    'B:11' =>82,
    'C:11' =>83,
    'D:11' =>84,
    'E:11' =>85,
    'F:11' =>86,
    'G:11' =>87,
    'H:11' =>88,
    'A:12' =>89,
    'B:12' =>90,
    'C:12' =>91,
    'D:12' =>92,
    'E:12' =>93,
    'F:12' =>94,
    'G:12' =>95,
    'H:12' =>96,
  );

  my $num_rows = 8;
  my $num_cols = 12;
  my $obj = Moose::Meta::Class->create_anon_class(
    roles => [qw/wtsi_clarity::util::well_mapper/])->new_object();

  throws_ok {$obj->well_location_index()} qr/Well address should be given/,
    'Error not giving well address';
  throws_ok {$obj->well_location_index('A:1')} qr/Number of rows has to be given/,
    'Error not giving number of rows';
  throws_ok {$obj->well_location_index('A:1', $num_rows)} qr/Number of columns has to be given/,
    'Error not giving number of rows';
  throws_ok {$obj->well_location_index('1:B', $num_rows, $num_cols)}
    qr/Well location format '1:B' is not recornised/,
    'Error on wrong well address format';
  throws_ok {$obj->well_location_index('B:14', $num_rows, $num_cols)}
    qr/Invalid column address '14' for 8:12 layout/,
    'Error on invalid column number';
  throws_ok {$obj->well_location_index('L:12', $num_rows, $num_cols)}
    qr/Invalid row address 'L' for 8:12 layout/,
    'Error on invalid row';

  is($obj->well_location_index( 'b:2', $num_rows, $num_cols ), 10, 'mapping for b:2');

  foreach my $loc (keys %expected_data ) {
    cmp_ok($obj->well_location_index( $loc, $num_rows, $num_cols ), 'eq', $expected_data{$loc},
      "mapping for $loc");
  }
}

1;
