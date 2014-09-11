use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use_ok('wtsi_clarity::genotyping::fluidigm::file_wrapper');

# Instantiating incorrectly...
{
  dies_ok { wtsi_clarity::genotyping::fluidigm::file_wrapper->new( file_name => 'fake/file/path' ); }
    'falls over when file name is not provided';

  dies_ok { wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
    file_name => 't/data/genotyping/fluidigm' ); } 'falls over when file name is actually a directory';
}

# Happy path...
{
  my $file_wrapper;
  lives_ok { $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
    file_name => 't/data/genotyping/fluidigm/complete/0123456789/0123456789.csv'
  ); } 'Does not die';
}