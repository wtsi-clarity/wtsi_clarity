use strict;
use warnings;
use Test::More tests => 205;
use Test::Exception;
use Moose::Meta::Class;

use_ok('wtsi_clarity::util::well_mapper');

my $num_rows = 8;
my $num_cols = 12;
my $obj = Moose::Meta::Class->create_anon_class(
  roles => [qw/wtsi_clarity::util::well_mapper/])->new_object();

{ # test well_location_index method
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

{ # test position_to_well method
  my %expected_data = (
      1  => 'A:1',
      2  => 'B:1',
      3  => 'C:1',
      4  => 'D:1',
      5  => 'E:1',
      6  => 'F:1',
      7  => 'G:1',
      8  => 'H:1',
      9  => 'A:2',
     10  => 'B:2',
     11  => 'C:2',
     12  => 'D:2',
     13  => 'E:2',
     14  => 'F:2',
     15  => 'G:2',
     16  => 'H:2',
     17  => 'A:3',
     18  => 'B:3',
     19  => 'C:3',
     20  => 'D:3',
     21  => 'E:3',
     22  => 'F:3',
     23  => 'G:3',
     24  => 'H:3',
     25  => 'A:4',
     26  => 'B:4',
     27  => 'C:4',
     28  => 'D:4',
     29  => 'E:4',
     30  => 'F:4',
     31  => 'G:4',
     32  => 'H:4',
     33  => 'A:5',
     34  => 'B:5',
     35  => 'C:5',
     36  => 'D:5',
     37  => 'E:5',
     38  => 'F:5',
     39  => 'G:5',
     40  => 'H:5',
     41  => 'A:6',
     42  => 'B:6',
     43  => 'C:6',
     44  => 'D:6',
     45  => 'E:6',
     46  => 'F:6',
     47  => 'G:6',
     48  => 'H:6',
     49  => 'A:7',
     50  => 'B:7',
     51  => 'C:7',
     52  => 'D:7',
     53  => 'E:7',
     54  => 'F:7',
     55  => 'G:7',
     56  => 'H:7',
     57  => 'A:8',
     58  => 'B:8',
     59  => 'C:8',
     60  => 'D:8',
     61  => 'E:8',
     62  => 'F:8',
     63  => 'G:8',
     64  => 'H:8',
     65  => 'A:9',
     66  => 'B:9',
     67  => 'C:9',
     68  => 'D:9',
     69  => 'E:9',
     70  => 'F:9',
     71  => 'G:9',
     72  => 'H:9',
     73  => 'A:10',
     74  => 'B:10',
     75  => 'C:10',
     76  => 'D:10',
     77  => 'E:10',
     78  => 'F:10',
     79  => 'G:10',
     80  => 'H:10',
     81  => 'A:11',
     82  => 'B:11',
     83  => 'C:11',
     84  => 'D:11',
     85  => 'E:11',
     86  => 'F:11',
     87  => 'G:11',
     88  => 'H:11',
     89  => 'A:12',
     90  => 'B:12',
     91  => 'C:12',
     92  => 'D:12',
     93  => 'E:12',
     94  => 'F:12',
     95  => 'G:12',
     96  => 'H:12',
  );
  throws_ok {$obj->position_to_well()} qr/Position should be given/,
    'Error not giving position data';
  throws_ok {$obj->position_to_well(3)} qr/Number of rows has to be given/,
    'Error not giving number of rows';
  throws_ok {$obj->position_to_well(4, $num_rows)} qr/Number of columns has to be given/,
    'Error not giving number of columns';
  throws_ok {$obj->position_to_well(-1, $num_rows, $num_cols)}
    qr/Position should be bigger than zero/,
    'Invalid position error: position should be a positive number.';

  is($obj->position_to_well( 5, $num_rows, $num_cols ), 'E:1', 'mapping for 5 should be E:1');

  foreach my $pos (keys %expected_data ) {
    cmp_ok($obj->position_to_well( $pos, $num_rows, $num_cols ), 'eq', $expected_data{$pos},
      "mapping for $pos should be $expected_data{$pos}");
  }

}

1;
