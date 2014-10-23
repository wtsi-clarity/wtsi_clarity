use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use Text::CSV;

use_ok('wtsi_clarity::util::calliper', 'can use calliper');

{
  my $calliper = wtsi_clarity::util::calliper->new();
  my $expected_result = [
          {
            'Molarity' => '1',
            'Well_Label' => 'F88',
            'FORGETME' => 'xxx',
            'Total_Conc' => '1',
            'Peak_Count' => '1',
            'Sample_Name' => 'A1_xxx'
          },
          {
            'Molarity' => '3',
            'Well_Label' => 'B1',
            'FORGETME' => 'xxx',
            'Total_Conc' => '2',
            'Peak_Count' => '1',
            'Sample_Name' => 'B1_xxx'
          },
          {
            'Molarity' => '5',
            'Well_Label' => 'G55',
            'FORGETME' => 'xxx',
            'Total_Conc' => '2',
            'Peak_Count' => '1',
            'Sample_Name' => 'B1_xxx'
          }
        ];

  my $some_content = [
          'FORGETME,Well_Label,Sample_Name,Peak_Count,Total_Conc,Molarity',
          'xxx,F88,A1_xxx,1,1,1',
          'xxx, B1,B1_xxx,1,2,3',
          'xxx,G55,B1_xxx,1,2,5',
        ];
  my $hashed_data = $calliper->interpret($some_content, '27');

  is_deeply($hashed_data, $expected_result, 'interpret returns the correct hashed data for a given content');
}

1;
