use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use Text::CSV;

use_ok('wtsi_clarity::util::report');

{
  my $w = wtsi_clarity::util::report->new();
  my $some_content = [
    {
      "Status", => 'a',
      "Study", => 'a',
      "Supplier", => 'a',
      "Sanger Sample Name", => 'a',
      "Supplier Sample Name", => 'a',
      "Plate", => 'a',
      "Well", => 'a',
      "Supplier Volume", => 'a',
      "Supplier Gender", => 'a',
      "Concentration", => 'a',
      "Measured Volume", => 'a',
      "Total micrograms", => 'a',
      "Fluidigm Count", => 'a',
      "Fluidigm Gender", => 'a',
      "Genotyping Status", => 'a',
      "Genotyping Chip", => 'a',
      "Genotyping Infinium Barcode", => 'a',
      "Genotyping Barcode", => 'a',
      "Genotyping Well Cohort", => 'a',
      "Proceed", => 'a',
    },
    {
      "Status", => 'b',
      "Study", => 'b',
      "Supplier", => 'b',
      "Sanger Sample Name", => 'b',
      "Supplier Sample Name", => 'b',
      "Plate", => 'b',
      "Well", => 'b',
      "Supplier Volume", => 'b',
      "Supplier Gender", => 'b',
      "Concentration", => 'b',
      "Measured Volume", => 'b',
      "Total micrograms", => 'b',
      "Fluidigm Count", => 'b',
      "Fluidigm Gender", => 'b',
      "Genotyping Status", => 'b',
      "Genotyping Chip", => 'b',
      "Genotyping Infinium Barcode", => 'b',
      "Genotyping Barcode", => 'b',
      "Genotyping Well Cohort", => 'b',
      "Proceed", => 'b',
    },
  ];
  my $expected_result = [
    "Status,Study,Supplier,Sanger Sample Name,Supplier Sample Name,Plate,Well,Supplier Volume,Supplier Gender,Concentration,Measured Volume,Total micrograms,Fluidigm Count,Fluidigm Gender,Genotyping Status,Genotyping Chip,Genotyping Infinium Barcode,Genotyping Barcode,Genotyping Well Cohort,Proceed",
    'a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a',
    'b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b'
  ];
  my $file = $w->get_file($some_content);
  is_deeply($file->content, $expected_result, 'get_file returns a file object with the correct content');
}

1;

