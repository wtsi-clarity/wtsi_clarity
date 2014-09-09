use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use wtsi_clarity::util::textfile;

use_ok('wtsi_clarity::util::csv::factories::calliper_csv_reader', 'can use calliper_csv_reader');


{
  my $EXPECTED_DATA_1 =
   {
     '1000' => {
          'B6' => {
                    'Molarity_2' => '6.53149914902806',
                    'Total_Conc' => '0.857390626451948',
                    'Peak_Count' => '10',
                    'Molarity_1' => '6.71457756710711',
                    'Sample_Name' => 'B6_ISC_1_5'
                  },
          'E8' => {
                    'Molarity_2' => '6.65146923177062',
                    'Total_Conc' => '0.833323398653794',
                    'Peak_Count' => '9',
                    'Molarity_1' => '6.72842747620383',
                    'Sample_Name' => 'E8_ISC_1_5'
                  },
          'C1' => {
                    'Molarity_2' => '1.86129570115488',
                    'Total_Conc' => '0.0817984766970191',
                    'Peak_Count' => '2',
                    'Molarity_1' => '1.82019232133282',
                    'Sample_Name' => 'C1_ISC_1_5'
                  },
          'E9' => {
                    'Molarity_2' => '0.0135495104370865',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0222650225737842',
                    'Sample_Name' => 'E9_ISC_1_5'
                  },
          'G7' => {
                    'Molarity_2' => '3.60184620253305',
                    'Total_Conc' => '0.382205085076838',
                    'Peak_Count' => '5',
                    'Molarity_1' => '3.88253499048343',
                    'Sample_Name' => 'G7_ISC_1_5'
                  },
          'H9' => {
                    'Molarity_2' => '4.51811549691128',
                    'Total_Conc' => '1.97516061911412',
                    'Peak_Count' => '16',
                    'Molarity_1' => '5.51233043565262',
                    'Sample_Name' => 'H9_ISC_1_5'
                  },
          'C8' => {
                    'Molarity_2' => '8.22097077713259',
                    'Total_Conc' => '1.23546811090114',
                    'Peak_Count' => '9',
                    'Molarity_1' => '8.66505335777844',
                    'Sample_Name' => 'C8_ISC_1_5'
                  },
          'H3' => {
                    'Molarity_2' => '1.54043367645241',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '1.46048672993928',
                    'Sample_Name' => 'H3_ISC_1_5'
                  },
          'C2' => {
                    'Molarity_2' => '3.92798410215347',
                    'Total_Conc' => '0.342020128066996',
                    'Peak_Count' => '6',
                    'Molarity_1' => '3.78753038420437',
                    'Sample_Name' => 'C2_ISC_1_5'
                  },
          'E7' => {
                    'Molarity_2' => '7.62648301864364',
                    'Total_Conc' => '1.09183391750179',
                    'Peak_Count' => '11',
                    'Molarity_1' => '7.76251007429803',
                    'Sample_Name' => 'E7_ISC_1_5'
                  },
          'F8' => {
                    'Molarity_2' => '0.014363491365782',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0217550416233856',
                    'Sample_Name' => 'F8_ISC_1_5'
                  },
          'B1' => {
                    'Molarity_2' => '2.5494791587686',
                    'Total_Conc' => '0.182153780398987',
                    'Peak_Count' => '4',
                    'Molarity_1' => '2.53750708774114',
                    'Sample_Name' => 'B1_ISC_1_5'
                  },
          'E6' => {
                    'Molarity_2' => '3.05141713078042',
                    'Total_Conc' => '0.196255510693418',
                    'Peak_Count' => '4',
                    'Molarity_1' => '3.03632847062985',
                    'Sample_Name' => 'E6_ISC_1_5'
                  },
          'E2' => {
                    'Molarity_2' => '4.20650788467139',
                    'Total_Conc' => '0.375016717950312',
                    'Peak_Count' => '8',
                    'Molarity_1' => '4.16674765401202',
                    'Sample_Name' => 'E2_ISC_1_5'
                  },
          'F3' => {
                    'Molarity_2' => '3.12693583119149',
                    'Total_Conc' => '0.322714815716146',
                    'Peak_Count' => '4',
                    'Molarity_1' => '3.17962552947262',
                    'Sample_Name' => 'F3_ISC_1_5'
                  },
          '10' => {
                    'Molarity_2' => '0.0441629271762334',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0376649928211036',
                    'Sample_Name' => 'A10_ISC_1_5'
                  },
          'G6' => {
                    'Molarity_2' => '6.53899457938174',
                    'Total_Conc' => '0.954121196175281',
                    'Peak_Count' => '9',
                    'Molarity_1' => '6.49337198140434',
                    'Sample_Name' => 'G6_ISC_1_5'
                  },
          '11' => {
                    'Molarity_2' => '0.0114559949816153',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0124031220019527',
                    'Sample_Name' => 'B11_ISC_1_5'
                  },
          'D6' => {
                    'Molarity_2' => '3.9405669922414',
                    'Total_Conc' => '0.429480171898142',
                    'Peak_Count' => '6',
                    'Molarity_1' => '3.83936127073911',
                    'Sample_Name' => 'D6_ISC_1_5'
                  },
          'F2' => {
                    'Molarity_2' => '9.0249922886638',
                    'Total_Conc' => '1.6120155965017',
                    'Peak_Count' => '12',
                    'Molarity_1' => '9.6413674493573',
                    'Sample_Name' => 'F2_ISC_1_5'
                  },
          'D8' => {
                    'Molarity_2' => '6.25293902946725',
                    'Total_Conc' => '0.918999663389033',
                    'Peak_Count' => '9',
                    'Molarity_1' => '6.1226093378121',
                    'Sample_Name' => 'D8_ISC_1_5'
                  },
          'E3' => {
                    'Molarity_2' => '6.96203117978386',
                    'Total_Conc' => '1.07972651518361',
                    'Peak_Count' => '7',
                    'Molarity_1' => '7.55597357362809',
                    'Sample_Name' => 'E3_ISC_1_5'
                  },
          '12' => {
                    'Molarity_2' => '0.007646011228164',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0154598862487031',
                    'Sample_Name' => 'A12_ISC_1_5'
                  },
          'B7' => {
                    'Molarity_2' => '5.06694282730619',
                    'Total_Conc' => '0.703912395567788',
                    'Peak_Count' => '7',
                    'Molarity_1' => '5.26137383384613',
                    'Sample_Name' => 'B7_ISC_1_5'
                  },
          'H4' => {
                    'Molarity_2' => '7.2901825375243',
                    'Total_Conc' => '1.09984495674688',
                    'Peak_Count' => '9',
                    'Molarity_1' => '7.39749913508623',
                    'Sample_Name' => 'H4_ISC_1_5'
                  },
          'D7' => {
                    'Molarity_2' => '8.00989892114275',
                    'Total_Conc' => '1.11052631106222',
                    'Peak_Count' => '7',
                    'Molarity_1' => '8.7363217924316',
                    'Sample_Name' => 'D7_ISC_1_5'
                  },
          'F6' => {
                    'Molarity_2' => '7.66459705293945',
                    'Total_Conc' => '0.956305396029537',
                    'Peak_Count' => '8',
                    'Molarity_1' => '8.20217121539422',
                    'Sample_Name' => 'F6_ISC_1_5'
                  },
          'B3' => {
                    'Molarity_2' => '8.90397537667753',
                    'Total_Conc' => '1.07289641960966',
                    'Peak_Count' => '9',
                    'Molarity_1' => '8.37543824268201',
                    'Sample_Name' => 'B3_ISC_1_5'
                  },
          'H6' => {
                    'Molarity_2' => '5.06616107716905',
                    'Total_Conc' => '0.571998226814326',
                    'Peak_Count' => '9',
                    'Molarity_1' => '4.89207589218291',
                    'Sample_Name' => 'H6_ISC_1_5'
                  },
          'G1' => {
                    'Molarity_2' => '6.2364357952379',
                    'Total_Conc' => '0.956721239047272',
                    'Peak_Count' => '13',
                    'Molarity_1' => '6.30000496189947',
                    'Sample_Name' => 'G1_ISC_1_5'
                  },
          'A1' => {
                    'Molarity_2' => '2.23010180190948',
                    'Total_Conc' => '0.173425862265629',
                    'Peak_Count' => '5',
                    'Molarity_1' => '2.20151284050569',
                    'Sample_Name' => 'A1_ISC_1_5'
                  },
          'B4' => {
                    'Molarity_2' => '2.56841697352717',
                    'Total_Conc' => '0.235617743598489',
                    'Peak_Count' => '6',
                    'Molarity_1' => '2.54144132878456',
                    'Sample_Name' => 'B4_ISC_1_5'
                  },
          'H5' => {
                    'Molarity_2' => '6.37639709237205',
                    'Total_Conc' => '0.844972889790915',
                    'Peak_Count' => '7',
                    'Molarity_1' => '6.61115245298778',
                    'Sample_Name' => 'H5_ISC_1_5'
                  },
          'A2' => {
                    'Molarity_2' => '2.63109036833625',
                    'Total_Conc' => '0.267208124797735',
                    'Peak_Count' => '7',
                    'Molarity_1' => '2.68630613828796',
                    'Sample_Name' => 'A2_ISC_1_5'
                  },
          'G3' => {
                    'Molarity_2' => '5.90195198726311',
                    'Total_Conc' => '0.799807402534009',
                    'Peak_Count' => '5',
                    'Molarity_1' => '6.03110688642299',
                    'Sample_Name' => 'G3_ISC_1_5'
                  },
          'G2' => {
                    'Molarity_2' => '14.7158808761572',
                    'Total_Conc' => '2.54314336125928',
                    'Peak_Count' => '11',
                    'Molarity_1' => '14.3098561311464',
                    'Sample_Name' => 'G2_ISC_1_5'
                  },
          'D5' => {
                    'Molarity_2' => '3.74449165989441',
                    'Total_Conc' => '0.396441973685163',
                    'Peak_Count' => '6',
                    'Molarity_1' => '3.82441137334695',
                    'Sample_Name' => 'D5_ISC_1_5'
                  },
          'A8' => {
                    'Molarity_2' => '2.79582046955938',
                    'Total_Conc' => '0.204321914723905',
                    'Peak_Count' => '5',
                    'Molarity_1' => '2.79303561474899',
                    'Sample_Name' => 'A8_ISC_1_5'
                  },
          'E4' => {
                    'Molarity_2' => '1.74113642274088',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '1.67679271658694',
                    'Sample_Name' => 'E4_ISC_1_5'
                  },
          'F7' => {
                    'Molarity_2' => '8.97364936747991',
                    'Total_Conc' => '1.59136223414995',
                    'Peak_Count' => '10',
                    'Molarity_1' => '9.47313619528953',
                    'Sample_Name' => 'F7_ISC_1_5'
                  },
          'C6' => {
                    'Molarity_2' => '10.3406951286429',
                    'Total_Conc' => '1.32611819799597',
                    'Peak_Count' => '11',
                    'Molarity_1' => '10.0922511285386',
                    'Sample_Name' => 'C6_ISC_1_5'
                  },
          'D9' => {
                    'Molarity_2' => '0.0123503805389079',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.026890941472556',
                    'Sample_Name' => 'D9_ISC_1_5'
                  },
          'H1' => {
                    'Molarity_2' => '4.45524998126511',
                    'Total_Conc' => '0.573472697596138',
                    'Peak_Count' => '7',
                    'Molarity_1' => '4.64125010084365',
                    'Sample_Name' => 'H1_ISC_1_5'
                  },
          'C5' => {
                    'Molarity_2' => '6.62208049130793',
                    'Total_Conc' => '0.957968374063566',
                    'Peak_Count' => '9',
                    'Molarity_1' => '6.73636802423812',
                    'Sample_Name' => 'C5_ISC_1_5'
                  },
          'H2' => {
                    'Molarity_2' => '7.13346254288441',
                    'Total_Conc' => '1.11034446794717',
                    'Peak_Count' => '9',
                    'Molarity_1' => '7.20463631691754',
                    'Sample_Name' => 'H2_ISC_1_5'
                  },
          'C4' => {
                    'Molarity_2' => '3.41354329696445',
                    'Total_Conc' => '0.447672444579881',
                    'Peak_Count' => '9',
                    'Molarity_1' => '3.22354077478513',
                    'Sample_Name' => 'C4_ISC_1_5'
                  },
          'F9' => {
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0105473487365369',
                    'Sample_Name' => 'F9_ISC_1_5'
                  },
          'A3' => {
                    'Molarity_2' => '6.38428532926411',
                    'Total_Conc' => '0.770144230280144',
                    'Peak_Count' => '8',
                    'Molarity_1' => '6.31046284299825',
                    'Sample_Name' => 'A3_ISC_1_5'
                  },
          'F1' => {
                    'Molarity_2' => '8.66863419873027',
                    'Total_Conc' => '1.12300638144443',
                    'Peak_Count' => '12',
                    'Molarity_1' => '8.54766949482669',
                    'Sample_Name' => 'F1_ISC_1_5'
                  },
          'C9' => {
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0275965361355408',
                    'Sample_Name' => 'C9_ISC_1_5'
                  },
          'F4' => {
                    'Molarity_2' => '4.49123140136068',
                    'Total_Conc' => '0.472067504628434',
                    'Peak_Count' => '8',
                    'Molarity_1' => '4.52770920347119',
                    'Sample_Name' => 'F4_ISC_1_5'
                  },
          'D2' => {
                    'Molarity_2' => '3.1810511518989',
                    'Total_Conc' => '0.398108953661869',
                    'Peak_Count' => '9',
                    'Molarity_1' => '3.33732349959476',
                    'Sample_Name' => 'D2_ISC_1_5'
                  },
          'G8' => {
                    'Molarity_2' => '0.00857821934303504',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0223280225386608',
                    'Sample_Name' => 'G8_ISC_1_5'
                  },
          'D3' => {
                    'Molarity_2' => '2.16761699205421',
                    'Total_Conc' => '0.116466112519526',
                    'Peak_Count' => '2',
                    'Molarity_1' => '2.15106265427231',
                    'Sample_Name' => 'D3_ISC_1_5'
                  },
          'G9' => {
                    'Molarity_2' => '0.0347888353834835',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.0330287009899267',
                    'Sample_Name' => 'G9_ISC_1_5'
                  },
          'E1' => {
                    'Molarity_2' => '1.7820131279908',
                    'Total_Conc' => '0.0206320726875401',
                    'Peak_Count' => '1',
                    'Molarity_1' => '1.75995673882798',
                    'Sample_Name' => 'E1_ISC_1_5'
                  },
          'H7' => {
                    'Molarity_2' => '4.31105455496975',
                    'Total_Conc' => '0.636956529583721',
                    'Peak_Count' => '8',
                    'Molarity_1' => '4.39958853213026',
                    'Sample_Name' => 'H7_ISC_1_5'
                  },
          'B2' => {
                    'Molarity_2' => '3.72712979142387',
                    'Total_Conc' => '0.298945056199793',
                    'Peak_Count' => '6',
                    'Molarity_1' => '3.64608387263729',
                    'Sample_Name' => 'B2_ISC_1_5'
                  },
          'B8' => {
                    'Molarity_2' => '2.83492184314656',
                    'Total_Conc' => '0.287652930800732',
                    'Peak_Count' => '5',
                    'Molarity_1' => '2.88870366132435',
                    'Sample_Name' => 'B8_ISC_1_5'
                  },
          'A7' => {
                    'Molarity_2' => '10.3955547895858',
                    'Total_Conc' => '1.60285699648942',
                    'Peak_Count' => '10',
                    'Molarity_1' => '10.4933811332512',
                    'Sample_Name' => 'A7_ISC_1_5'
                  },
          'B5' => {
                    'Molarity_2' => '7.17409566181924',
                    'Total_Conc' => '1.09211143332559',
                    'Peak_Count' => '11',
                    'Molarity_1' => '7.11170103637566',
                    'Sample_Name' => 'B5_ISC_1_5'
                  },
          'G5' => {
                    'Molarity_2' => '3.97239221718722',
                    'Total_Conc' => '0.568680111327817',
                    'Peak_Count' => '8',
                    'Molarity_1' => '4.28954715030615',
                    'Sample_Name' => 'G5_ISC_1_5'
                  },
          'A6' => {
                    'Molarity_2' => '4.38396098504144',
                    'Total_Conc' => '0.596398671053248',
                    'Peak_Count' => '6',
                    'Molarity_1' => '4.39541396195783',
                    'Sample_Name' => 'A6_ISC_1_5'
                  },
          'A5' => {
                    'Molarity_2' => '6.87775602652126',
                    'Total_Conc' => '0.981636838670232',
                    'Peak_Count' => '8',
                    'Molarity_1' => '7.29111708510066',
                    'Sample_Name' => 'A5_ISC_1_5'
                  },
          'C7' => {
                    'Molarity_2' => '7.82639385722859',
                    'Total_Conc' => '1.25161016414112',
                    'Peak_Count' => '10',
                    'Molarity_1' => '8.1866409872914',
                    'Sample_Name' => 'C7_ISC_1_5'
                  },
          'D4' => {
                    'Molarity_2' => '2.35489516425007',
                    'Total_Conc' => '0.131126267847089',
                    'Peak_Count' => '4',
                    'Molarity_1' => '2.2934355739298',
                    'Sample_Name' => 'D4_ISC_1_5'
                  },
          'A4' => {
                    'Molarity_2' => '2.14016376031209',
                    'Total_Conc' => '0.150755116617543',
                    'Peak_Count' => '3',
                    'Molarity_1' => '2.15543793732021',
                    'Sample_Name' => 'A4_ISC_1_5'
                  },
          'D1' => {
                    'Molarity_2' => '7.43846491627343',
                    'Total_Conc' => '1.07474959983061',
                    'Peak_Count' => '9',
                    'Molarity_1' => '7.48832047000404',
                    'Sample_Name' => 'D1_ISC_1_5'
                  },
          'G4' => {
                    'Molarity_2' => '5.91102490771418',
                    'Total_Conc' => '0.854489756121',
                    'Peak_Count' => '8',
                    'Molarity_1' => '5.8703633559652',
                    'Sample_Name' => 'G4_ISC_1_5'
                  },
          'B9' => {
                    'Molarity_2' => '0.0233022449089023',
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.00580325089169532',
                    'Sample_Name' => 'B9_ISC_1_5'
                  },
          'C3' => {
                    'Molarity_2' => '5.20891670058844',
                    'Total_Conc' => '0.6313597644271',
                    'Peak_Count' => '6',
                    'Molarity_1' => '5.74486613636694',
                    'Sample_Name' => 'C3_ISC_1_5'
                  },
          'F5' => {
                    'Molarity_2' => '10.608574575811',
                    'Total_Conc' => '1.41291121820126',
                    'Peak_Count' => '10',
                    'Molarity_1' => '10.7847537847405',
                    'Sample_Name' => 'F5_ISC_1_5'
                  },
          'E5' => {
                    'Molarity_2' => '5.22893371286243',
                    'Total_Conc' => '0.648145987881077',
                    'Peak_Count' => '9',
                    'Molarity_1' => '5.4280009916783',
                    'Sample_Name' => 'E5_ISC_1_5'
                  },
          'A9' => {
                    'Total_Conc' => '0',
                    'Peak_Count' => '0',
                    'Molarity_1' => '0.026157499230803',
                    'Sample_Name' => 'A9_ISC_1_5'
                  }
                }
        };

  Readonly::Scalar my $testdata_path => q(./t/data/file_parsing/ISC_pool_calculator/);
  Readonly::Scalar my $file1 => q(Caliper1_344745_ISC_1_5_2014-07-01_12-55-09_WellTable.csv);

  my $file = wtsi_clarity::util::textfile->new();
  $file->read_content($testdata_path."/".$file1);

  my $reader = wtsi_clarity::util::csv::factories::calliper_csv_reader->new();

  my $output = $reader->build(
    headers => ['Well_Label',
                        'Sample_Name',
                        'Peak_Count',
                        'Total_Conc',
                        'Molarity'],
    file_content => $file->content,
    barcode => '1000',
    );

  is_deeply( $output,  $EXPECTED_DATA_1,  "_filecontent_to_hash() should return the correct content.");
}

{ # _cleanup_key
  my $test_data = {
    'hello'    => 'hello',
    'hello '   => 'hello',
    ' hello'   => 'hello',
    ' hello '  => 'hello',
    'hel lo'   => 'hel lo',
    ' hel lo'  => 'hel lo',
    'hel lo '  => 'hel lo',
    ' hel lo ' => 'hel lo',
  };
  while (my ($input, $expected) = each %{$test_data} ) {
    my $output = wtsi_clarity::util::csv::factories::calliper_csv_reader::_cleanup_key($input);
    is_deeply( $output,  $expected,  "_cleanup_key() should return the correct content.");
  }
}

1;
