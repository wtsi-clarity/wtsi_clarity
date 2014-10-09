use strict;
use warnings;
use Test::More tests => 38;
use Test::Exception;

use_ok('wtsi_clarity::ics::agilent::file_validator');

# Path of eternal happiness...
{
  my $files = ['123_A1_F1', '123_G1_D2', '123_E2_B3', '123_C3_H3'];

  my $fv = wtsi_clarity::ics::agilent::file_validator->new(
    file_names => $files,
  );

  is (scalar keys $fv->_wells, 24, 'Returns 24 wells');

  my $wells = {
    'A1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [1, 2],
    },
    'B1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [3, 4],
    },
    'C1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [5, 6],
    },
    'D1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [7, 8],
    },
    'E1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [9, 10],
    },
    'F1' => {
      'file_path'  => '123_A1_F1',
      'wells' => [11, 12],
    },
    'G1' => {
      'file_path'  => '123_G1_D2',
      'wells' => [1, 2],
    },
    'H1' => {
      'file_path'  => '123_G1_D2',
      'wells' => [3, 4],
    },
    'A2' => {
      'file_path'  => '123_G1_D2',
      'wells' => [5, 6],
    },
    'B2' => {
      'file_path'  => '123_G1_D2',
      'wells' => [7, 8],
    },
    'C2' => {
      'file_path'  => '123_G1_D2',
      'wells' => [9, 10],
    },
    'D2' => {
      'file_path'  => '123_G1_D2',
      'wells' => [11, 12],
    },
    'E2' => {
      'file_path'  => '123_E2_B3',
      'wells' => [1, 2],
    },
    'F2' => {
      'file_path'  => '123_E2_B3',
      'wells' => [3, 4],
    },
    'G2' => {
      'file_path'  => '123_E2_B3',
      'wells' => [5, 6],
    },
    'H2' => {
      'file_path'  => '123_E2_B3',
      'wells' => [7, 8],
    },
    'A3' => {
      'file_path'  => '123_E2_B3',
      'wells' => [9, 10],
    },
    'B3' => {
      'file_path'  => '123_E2_B3',
      'wells' => [11, 12],
    },
    'C3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [1, 2],
    },
    'D3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [3, 4],
    },
    'E3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [5, 6],
    },
    'F3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [7, 8],
    },
    'G3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [9, 10],
    },
    'H3' => {
      'file_path'  => '123_C3_H3',
      'wells' => [11, 12],
    }
  };

  is_deeply($fv->files_by_well, $wells, 'Creates and returns the wells correctly');
}

#  Building helpful little file objects...
{
  my $file_names = ['12345_H1_I9', '12345_A1_G1'];

  my $file_val = wtsi_clarity::ics::agilent::file_validator->new(file_names => $file_names);
  isa_ok($file_val->files, 'Mojo::Collection', 'Builds us a collection of file objects');

  is($file_val->files->size(), 2, 'Builds a collection of 2 file objects');

  # This also showing that the files have been sorted correctly (because A1 is first)
  is($file_val->files->[0]->{'barcode'}, '12345', 'Extracts the barcode correctly');
  is($file_val->files->[0]->{'start_well'}, 'A1', 'Extracts the start well correctly');
  is($file_val->files->[0]->{'end_well'}, 'G1', 'Extracts the end well correctly');

  is($file_val->files->[1]->{'barcode'}, '12345', 'Extracts the barcode correctly');
  is($file_val->files->[1]->{'start_well'}, 'H1', 'Extracts the start well correctly');
  is($file_val->files->[1]->{'end_well'}, 'I9', 'Extracts the end well correctly');
}

# Let's do some validation...
# Fails when barcodes don't match
{
  my $files = ['123456_A1_B1', '123_C1_D1', '123_E1_F1', '123_G1_H1'];

    throws_ok { wtsi_clarity::ics::agilent::file_validator->new(file_names => $files); }
      qr/Barcodes on files do not match/, 'Croaks when barcodes do not match';
}

# Fails when there is a gap in the sequence of wells
{
  my $files = ['123_A1_B1', '123_D1_E1', '123_F1_G1', '123_H1_A2'];

  throws_ok { wtsi_clarity::ics::agilent::file_validator->new(file_names => $files); }
    qr/There is a problem with the sequence of wells given in the file names/,
    'Croaks when there is a gap between wells';
}

# Fails when there are overlaps in the sequence of wells
{
  my $files = ['123_A1_B1', '123_B1_E1', '123_F1_G1', '123_H1_A2'];

  throws_ok { wtsi_clarity::ics::agilent::file_validator->new(file_names => $files); }
    qr/There is a problem with the sequence of wells given in the file names/,
    'Croaks when there are overlapping wells';
}

# Mapping
{
  my $files = ['123_A1_B1'];

  my $fv = wtsi_clarity::ics::agilent::file_validator->new(file_names => $files);

  my $test_data = {
    A1 => [1, 2],
    B1 => [3, 4],
    C1 => [5, 6],
    D1 => [7, 8],
    E1 => [9, 10],
    F1 => [11, 12],
    G1 => [1, 2],
    H1 => [3, 4],
    A2 => [5, 6],
    B2 => [7, 8],
    C2 => [9, 10],
    D2 => [11, 12],
    E2 => [1, 2],
    F2 => [3, 4],
    G2 => [5, 6],
    H2 => [7, 8],
    A3 => [9, 10],
    B3 => [11, 12],
    C3 => [1, 2],
    D3 => [3, 4],
    E3 => [5, 6],
    F3 => [7, 8],
    G3 => [9, 10],
    H3 => [11, 12],
  };

  foreach my $well (keys %{$test_data}) {
    is_deeply($fv->_map_well($well), $test_data->{$well}, 'Maps the wells correctly');
  }
}