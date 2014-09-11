use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;

use_ok('wtsi_clarity::genotyping::fluidigm::result_set');

# Directory doesn't exist
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => '/fake/directory',
    );
  } qr/does not pass the type constraint/;
}

# Is not a directory
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv',
    );
  } qr/does not pass the type constraint/;
}

# Data directory doesn't exist
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => 't/data/genotyping/fluidigm/missing_data/0123456789',
    );
  } qr/does not pass the type constraint/;
}

# Data is not a directory
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => 't/data/genotyping/fluidigm/data_is_file/0123456789',
    );
  } qr/does not pass the type constraint/;
}

# Missing tif
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => 't/data/genotyping/fluidigm/missing_tif/0123456789',
    );
  } qr/Should have exactly 3 .tif files in t\/data\/genotyping\/fluidigm\/missing_tif\/0123456789\/Data/;
}

# Missing .csv file
{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::result_set->new(
      directory => 't/data/genotyping/fluidigm/missing_export/0123456789',
    );
  } qr/does not pass the type constraint/;
}

# Happy Path...
{
  my $result_set = wtsi_clarity::genotyping::fluidigm::result_set->new(
    directory => 't/data/genotyping/fluidigm/complete/0123456789'
  );

  is($result_set->directory, 't/data/genotyping/fluidigm/complete/0123456789', 'Sets the directory');
  is($result_set->data_directory, 't/data/genotyping/fluidigm/complete/0123456789/Data', 'Sets the Data directory');
  is($result_set->export_file, 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv', 'Sets the export file');

  my @tif_files = ('aramis.tif', 'athos.tif', 'porthos.tif');
  my @tif_filepaths = map { join q{/}, 't/data/genotyping/fluidigm/complete/0123456789/Data', $_ } @tif_files;
  is_deeply($result_set->tif_files, \@tif_filepaths, 'Sets the tif files');

  is($result_set->fluidigm_barcode, '0123456789', 'Sets the fluidigm barcode');
}