use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use_ok('wtsi_clarity::genotyping::fluidigm::file_wrapper');

{
  dies_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 'fake/file/path'
    );
  } 'falls over when file name is not provided';

  dies_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm'
    );
  } 'falls over when file name is actually a directory';
}

{
  my $file_wrapper;
  lives_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv'
    );
  } 'Does not die';
}

{
  throws_ok {
    wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
      file_name => 't/data/genotyping/fluidigm/missing_data/0123456789/test_data.csv'
    ),
  } qr/Parse error: expected 12 columns, but found 11 at line 20/,
  'falls over when data is missing';
}