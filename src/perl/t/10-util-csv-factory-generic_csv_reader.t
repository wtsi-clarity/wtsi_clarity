use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;
use wtsi_clarity::util::textfile;

use_ok('wtsi_clarity::util::csv::factories::generic_csv_reader', 'can use generic_csv_reader');


{
  my $EXPECTED_DATA_1 = [
    {
      'Peak Count' => '5',
      'Sample Name' => 'A1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.20151284050569',
      'Total Conc. (ng/ul)' => '0.173425862265629',
      'Well Label' => 'A01'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'A1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.23010180190948',
      'Total Conc. (ng/ul)' => '0.147051987121658',
      'Well Label' => 'B01'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'B1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.53750708774114',
      'Total Conc. (ng/ul)' => '0.182153780398987',
      'Well Label' => 'C01'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'B1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.5494791587686',
      'Total Conc. (ng/ul)' => '0.183428711898222',
      'Well Label' => 'D01'
    },
    {
      'Peak Count' => '2',
      'Sample Name' => 'C1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.82019232133282',
      'Total Conc. (ng/ul)' => '0.0817984766970191',
      'Well Label' => 'E01'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'C1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.86129570115488',
      'Total Conc. (ng/ul)' => '0.155132318084824',
      'Well Label' => 'F01'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'D1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.48832047000404',
      'Total Conc. (ng/ul)' => '1.07474959983061',
      'Well Label' => 'G01'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'D1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.43846491627343',
      'Total Conc. (ng/ul)' => '1.0089883612801',
      'Well Label' => 'H01'
    },
    {
      'Peak Count' => '1',
      'Sample Name' => 'E1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.75995673882798',
      'Total Conc. (ng/ul)' => '0.0206320726875401',
      'Well Label' => 'I01'
    },
    {
      'Peak Count' => '2',
      'Sample Name' => 'E1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.7820131279908',
      'Total Conc. (ng/ul)' => '0.0725780211232417',
      'Well Label' => 'J01'
    },
    {
      'Peak Count' => '12',
      'Sample Name' => 'F1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.54766949482669',
      'Total Conc. (ng/ul)' => '1.12300638144443',
      'Well Label' => 'K01'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'F1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.66863419873027',
      'Total Conc. (ng/ul)' => '1.23530404906901',
      'Well Label' => 'L01'
    },
    {
      'Peak Count' => '13',
      'Sample Name' => 'G1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.30000496189947',
      'Total Conc. (ng/ul)' => '0.956721239047272',
      'Well Label' => 'M01'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'G1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.2364357952379',
      'Total Conc. (ng/ul)' => '0.825132740234965',
      'Well Label' => 'N01'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'H1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.64125010084365',
      'Total Conc. (ng/ul)' => '0.573472697596138',
      'Well Label' => 'O01'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'H1_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.45524998126511',
      'Total Conc. (ng/ul)' => '0.48919923826103',
      'Well Label' => 'P01'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'A2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.68630613828796',
      'Total Conc. (ng/ul)' => '0.267208124797735',
      'Well Label' => 'A03'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'A2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.63109036833625',
      'Total Conc. (ng/ul)' => '0.183416323234904',
      'Well Label' => 'B03'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'B2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.64608387263729',
      'Total Conc. (ng/ul)' => '0.298945056199793',
      'Well Label' => 'C03'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'B2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.72712979142387',
      'Total Conc. (ng/ul)' => '0.350303717429045',
      'Well Label' => 'D03'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'C2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.78753038420437',
      'Total Conc. (ng/ul)' => '0.342020128066996',
      'Well Label' => 'E03'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'C2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.92798410215347',
      'Total Conc. (ng/ul)' => '0.547259982535967',
      'Well Label' => 'F03'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'D2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.33732349959476',
      'Total Conc. (ng/ul)' => '0.398108953661869',
      'Well Label' => 'G03'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'D2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.1810511518989',
      'Total Conc. (ng/ul)' => '0.345475927132224',
      'Well Label' => 'H03'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'E2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.16674765401202',
      'Total Conc. (ng/ul)' => '0.375016717950312',
      'Well Label' => 'I03'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'E2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.20650788467139',
      'Total Conc. (ng/ul)' => '0.396103682227952',
      'Well Label' => 'J03'
    },
    {
      'Peak Count' => '12',
      'Sample Name' => 'F2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '9.6413674493573',
      'Total Conc. (ng/ul)' => '1.6120155965017',
      'Well Label' => 'K03'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'F2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '9.0249922886638',
      'Total Conc. (ng/ul)' => '1.08265774038166',
      'Well Label' => 'L03'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'G2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '14.3098561311464',
      'Total Conc. (ng/ul)' => '2.54314336125928',
      'Well Label' => 'M03'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'G2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '14.7158808761572',
      'Total Conc. (ng/ul)' => '2.17939796049493',
      'Well Label' => 'N03'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.20463631691754',
      'Total Conc. (ng/ul)' => '1.11034446794717',
      'Well Label' => 'O03'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H2_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.13346254288441',
      'Total Conc. (ng/ul)' => '1.00643515872466',
      'Well Label' => 'P03'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'A3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.31046284299825',
      'Total Conc. (ng/ul)' => '0.770144230280144',
      'Well Label' => 'A05'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'A3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.38428532926411',
      'Total Conc. (ng/ul)' => '0.797489365904055',
      'Well Label' => 'B05'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'B3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.37543824268201',
      'Total Conc. (ng/ul)' => '1.07289641960966',
      'Well Label' => 'C05'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'B3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.90397537667753',
      'Total Conc. (ng/ul)' => '1.39804927844231',
      'Well Label' => 'D05'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'C3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.74486613636694',
      'Total Conc. (ng/ul)' => '0.6313597644271',
      'Well Label' => 'E05'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'C3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.20891670058844',
      'Total Conc. (ng/ul)' => '0.507714788471549',
      'Well Label' => 'F05'
    },
    {
      'Peak Count' => '2',
      'Sample Name' => 'D3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.15106265427231',
      'Total Conc. (ng/ul)' => '0.116466112519526',
      'Well Label' => 'G05'
    },
    {
      'Peak Count' => '1',
      'Sample Name' => 'D3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.16761699205421',
      'Total Conc. (ng/ul)' => '0.081349753905237',
      'Well Label' => 'H05'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'E3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.55597357362809',
      'Total Conc. (ng/ul)' => '1.07972651518361',
      'Well Label' => 'I05'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'E3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.96203117978386',
      'Total Conc. (ng/ul)' => '1.05436612822847',
      'Well Label' => 'J05'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'F3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.17962552947262',
      'Total Conc. (ng/ul)' => '0.322714815716146',
      'Well Label' => 'K05'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'F3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.12693583119149',
      'Total Conc. (ng/ul)' => '0.300597882081614',
      'Well Label' => 'L05'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'G3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.03110688642299',
      'Total Conc. (ng/ul)' => '0.799807402534009',
      'Well Label' => 'M05'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'G3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.90195198726311',
      'Total Conc. (ng/ul)' => '0.919328472865019',
      'Well Label' => 'N05'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.46048672993928',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'O05'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H3_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.54043367645241',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'P05'
    },
    {
      'Peak Count' => '3',
      'Sample Name' => 'A4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.15543793732021',
      'Total Conc. (ng/ul)' => '0.150755116617543',
      'Well Label' => 'A07'
    },
    {
      'Peak Count' => '2',
      'Sample Name' => 'A4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.14016376031209',
      'Total Conc. (ng/ul)' => '0.0533986653427092',
      'Well Label' => 'B07'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'B4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.54144132878456',
      'Total Conc. (ng/ul)' => '0.235617743598489',
      'Well Label' => 'C07'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'B4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.56841697352717',
      'Total Conc. (ng/ul)' => '0.25647984105706',
      'Well Label' => 'D07'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'C4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.22354077478513',
      'Total Conc. (ng/ul)' => '0.447672444579881',
      'Well Label' => 'E07'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'C4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.41354329696445',
      'Total Conc. (ng/ul)' => '0.248104773985122',
      'Well Label' => 'F07'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'D4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.2934355739298',
      'Total Conc. (ng/ul)' => '0.131126267847089',
      'Well Label' => 'G07'
    },
    {
      'Peak Count' => '2',
      'Sample Name' => 'D4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.35489516425007',
      'Total Conc. (ng/ul)' => '0.0797895218524688',
      'Well Label' => 'H07'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.67679271658694',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'I07'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '1.74113642274088',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'J07'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'F4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.52770920347119',
      'Total Conc. (ng/ul)' => '0.472067504628434',
      'Well Label' => 'K07'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'F4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.49123140136068',
      'Total Conc. (ng/ul)' => '0.658029342117389',
      'Well Label' => 'L07'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'G4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.8703633559652',
      'Total Conc. (ng/ul)' => '0.854489756121',
      'Well Label' => 'M07'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'G4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.91102490771418',
      'Total Conc. (ng/ul)' => '0.860754664073777',
      'Well Label' => 'N07'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.39749913508623',
      'Total Conc. (ng/ul)' => '1.09984495674688',
      'Well Label' => 'O07'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'H4_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.2901825375243',
      'Total Conc. (ng/ul)' => '0.931019047842005',
      'Well Label' => 'P07'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'A5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.29111708510066',
      'Total Conc. (ng/ul)' => '0.981636838670232',
      'Well Label' => 'A09'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'A5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.87775602652126',
      'Total Conc. (ng/ul)' => '0.973021028781591',
      'Well Label' => 'B09'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'B5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.11170103637566',
      'Total Conc. (ng/ul)' => '1.09211143332559',
      'Well Label' => 'C09'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'B5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.17409566181924',
      'Total Conc. (ng/ul)' => '0.894738826029012',
      'Well Label' => 'D09'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'C5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.73636802423812',
      'Total Conc. (ng/ul)' => '0.957968374063566',
      'Well Label' => 'E09'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'C5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.62208049130793',
      'Total Conc. (ng/ul)' => '0.841440203000291',
      'Well Label' => 'F09'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'D5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.82441137334695',
      'Total Conc. (ng/ul)' => '0.396441973685163',
      'Well Label' => 'G09'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'D5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.74449165989441',
      'Total Conc. (ng/ul)' => '0.423468712698612',
      'Well Label' => 'H09'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'E5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.4280009916783',
      'Total Conc. (ng/ul)' => '0.648145987881077',
      'Well Label' => 'I09'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'E5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.22893371286243',
      'Total Conc. (ng/ul)' => '0.650386752181757',
      'Well Label' => 'J09'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'F5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.7847537847405',
      'Total Conc. (ng/ul)' => '1.41291121820126',
      'Well Label' => 'K09'
    },
    {
      'Peak Count' => '13',
      'Sample Name' => 'F5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.608574575811',
      'Total Conc. (ng/ul)' => '1.64801008318517',
      'Well Label' => 'L09'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'G5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.28954715030615',
      'Total Conc. (ng/ul)' => '0.568680111327817',
      'Well Label' => 'M09'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'G5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.97239221718722',
      'Total Conc. (ng/ul)' => '0.551205723449103',
      'Well Label' => 'N09'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'H5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.61115245298778',
      'Total Conc. (ng/ul)' => '0.844972889790915',
      'Well Label' => 'O09'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H5_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.37639709237205',
      'Total Conc. (ng/ul)' => '0.915037828184686',
      'Well Label' => 'P09'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'A6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.39541396195783',
      'Total Conc. (ng/ul)' => '0.596398671053248',
      'Well Label' => 'A11'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'A6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.38396098504144',
      'Total Conc. (ng/ul)' => '0.585058560504367',
      'Well Label' => 'B11'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'B6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.71457756710711',
      'Total Conc. (ng/ul)' => '0.857390626451948',
      'Well Label' => 'C11'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'B6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.53149914902806',
      'Total Conc. (ng/ul)' => '0.743100306305149',
      'Well Label' => 'D11'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'C6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.0922511285386',
      'Total Conc. (ng/ul)' => '1.32611819799597',
      'Well Label' => 'E11'
    },
    {
      'Peak Count' => '13',
      'Sample Name' => 'C6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.3406951286429',
      'Total Conc. (ng/ul)' => '1.54960117546736',
      'Well Label' => 'F11'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'D6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.83936127073911',
      'Total Conc. (ng/ul)' => '0.429480171898142',
      'Well Label' => 'G11'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'D6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.9405669922414',
      'Total Conc. (ng/ul)' => '0.485147398954517',
      'Well Label' => 'H11'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'E6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.03632847062985',
      'Total Conc. (ng/ul)' => '0.196255510693418',
      'Well Label' => 'I11'
    },
    {
      'Peak Count' => '6',
      'Sample Name' => 'E6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.05141713078042',
      'Total Conc. (ng/ul)' => '0.250843422776486',
      'Well Label' => 'J11'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'F6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.20217121539422',
      'Total Conc. (ng/ul)' => '0.956305396029537',
      'Well Label' => 'K11'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'F6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.66459705293945',
      'Total Conc. (ng/ul)' => '1.03861888116782',
      'Well Label' => 'L11'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'G6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.49337198140434',
      'Total Conc. (ng/ul)' => '0.954121196175281',
      'Well Label' => 'M11'
    },
    {
      'Peak Count' => '13',
      'Sample Name' => 'G6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.53899457938174',
      'Total Conc. (ng/ul)' => '1.08845767158118',
      'Well Label' => 'N11'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.89207589218291',
      'Total Conc. (ng/ul)' => '0.571998226814326',
      'Well Label' => 'O11'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'H6_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.06616107716905',
      'Total Conc. (ng/ul)' => '0.570106367834142',
      'Well Label' => 'P11'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'A7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.4933811332512',
      'Total Conc. (ng/ul)' => '1.60285699648942',
      'Well Label' => 'A13'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'A7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '10.3955547895858',
      'Total Conc. (ng/ul)' => '1.69930030788198',
      'Well Label' => 'B13'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'B7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.26137383384613',
      'Total Conc. (ng/ul)' => '0.703912395567788',
      'Well Label' => 'C13'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'B7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.06694282730619',
      'Total Conc. (ng/ul)' => '0.701368031530669',
      'Well Label' => 'D13'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'C7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.1866409872914',
      'Total Conc. (ng/ul)' => '1.25161016414112',
      'Well Label' => 'E13'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'C7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.82639385722859',
      'Total Conc. (ng/ul)' => '0.930430676492973',
      'Well Label' => 'F13'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'D7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.7363217924316',
      'Total Conc. (ng/ul)' => '1.11052631106222',
      'Well Label' => 'G13'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'D7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.00989892114275',
      'Total Conc. (ng/ul)' => '1.30660717731925',
      'Well Label' => 'H13'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'E7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.76251007429803',
      'Total Conc. (ng/ul)' => '1.09183391750179',
      'Well Label' => 'I13'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'E7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '7.62648301864364',
      'Total Conc. (ng/ul)' => '1.09979295590669',
      'Well Label' => 'J13'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'F7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '9.47313619528953',
      'Total Conc. (ng/ul)' => '1.59136223414995',
      'Well Label' => 'K13'
    },
    {
      'Peak Count' => '11',
      'Sample Name' => 'F7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.97364936747991',
      'Total Conc. (ng/ul)' => '1.28900825284637',
      'Well Label' => 'L13'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'G7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.88253499048343',
      'Total Conc. (ng/ul)' => '0.382205085076838',
      'Well Label' => 'M13'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'G7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '3.60184620253305',
      'Total Conc. (ng/ul)' => '0.273525235218802',
      'Well Label' => 'N13'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'H7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.39958853213026',
      'Total Conc. (ng/ul)' => '0.636956529583721',
      'Well Label' => 'O13'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'H7_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.31105455496975',
      'Total Conc. (ng/ul)' => '0.546985420316333',
      'Well Label' => 'P13'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'A8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.79303561474899',
      'Total Conc. (ng/ul)' => '0.204321914723905',
      'Well Label' => 'A15'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'A8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.79582046955938',
      'Total Conc. (ng/ul)' => '0.281252757468704',
      'Well Label' => 'B15'
    },
    {
      'Peak Count' => '5',
      'Sample Name' => 'B8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.88870366132435',
      'Total Conc. (ng/ul)' => '0.287652930800732',
      'Well Label' => 'C15'
    },
    {
      'Peak Count' => '4',
      'Sample Name' => 'B8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '2.83492184314656',
      'Total Conc. (ng/ul)' => '0.233834848444748',
      'Well Label' => 'D15'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'C8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.66505335777844',
      'Total Conc. (ng/ul)' => '1.23546811090114',
      'Well Label' => 'E15'
    },
    {
      'Peak Count' => '10',
      'Sample Name' => 'C8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '8.22097077713259',
      'Total Conc. (ng/ul)' => '1.29940281823072',
      'Well Label' => 'F15'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'D8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.1226093378121',
      'Total Conc. (ng/ul)' => '0.918999663389033',
      'Well Label' => 'G15'
    },
    {
      'Peak Count' => '7',
      'Sample Name' => 'D8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.25293902946725',
      'Total Conc. (ng/ul)' => '0.908899446081642',
      'Well Label' => 'H15'
    },
    {
      'Peak Count' => '9',
      'Sample Name' => 'E8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.72842747620383',
      'Total Conc. (ng/ul)' => '0.833323398653794',
      'Well Label' => 'I15'
    },
    {
      'Peak Count' => '8',
      'Sample Name' => 'E8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '6.65146923177062',
      'Total Conc. (ng/ul)' => '0.921486593086173',
      'Well Label' => 'J15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0217550416233856',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'K15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.014363491365782',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'L15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0223280225386608',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'M15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00857821934303504',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'N15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'O15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H8_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'P15'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.026157499230803',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'A17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'B17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00580325089169532',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'C17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0233022449089023',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'D17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0275965361355408',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'E17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'F17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.026890941472556',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'G17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0123503805389079',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'H17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0222650225737842',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'I17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0135495104370865',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'J17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'K17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0105473487365369',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'L17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0330287009899267',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'M17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0347888353834835',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'N17'
    },
    {
      'Peak Count' => '16',
      'Sample Name' => 'H9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '5.51233043565262',
      'Total Conc. (ng/ul)' => '1.97516061911412',
      'Well Label' => 'O17'
    },
    {
      'Peak Count' => '15',
      'Sample Name' => 'H9_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '4.51811549691128',
      'Total Conc. (ng/ul)' => '1.19390872557629',
      'Well Label' => 'P17'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0376649928211036',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'A19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'B19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0075333317065208',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'C19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00115227745919105',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'D19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0158413612867155',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'E19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'F19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0305894129317842',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'G19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0233760426607249',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'H19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'I19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0275067037196578',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'J19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'K19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'L19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0596084117468546',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'M19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00802815960156587',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'N19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0140024929261417',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'O19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H10_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0441629271762334',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'P19'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'A21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'B21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0124031220019527',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'C21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0226993531085896',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'D21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0311836899502632',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'E21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00801634771609444',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'F21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'G21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0117999400838692',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'H21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0388092463882278',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'I21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0336050267553794',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'J21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00235081964266171',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'K21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0149101575065979',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'L21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.033077389997561',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'M21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.015449182575608',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'N21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0244585073449068',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'O21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H11_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0114559949816153',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'P21'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'A23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'A12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0154598862487031',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'B23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0200751211366011',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'C23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'B12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'D23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.000887027982756011',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'E23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'C12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0246467141786154',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'F23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00967793134455713',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'G23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'D12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0334524340966265',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'H23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'I23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'E12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00635232104067217',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'J23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0288725567520975',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'K23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'F12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00741017327953466',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'L23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.0417860183721143',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'M23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'G12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.00120069617326804',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'N23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0.007646011228164',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'O23'
    },
    {
      'Peak Count' => '0',
      'Sample Name' => 'H12_ISC_1_5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '0',
      'Total Conc. (ng/ul)' => '0',
      'Well Label' => 'P23'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder1',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder01'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder2',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder02'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder3',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder03'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder4',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder04'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder5',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder05'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder6',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder06'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder7',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder07'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder8',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder08'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder9',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder09'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder10',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder10'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder11',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder11'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder12',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder12'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder13',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder13'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder14',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder14'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder15',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder15'
    },
    {
      'Peak Count' => '',
      'Sample Name' => 'Ladder16',
      'Plate Name' => 'Caliper1_344745_ISC_1_5_2014-07-01_12-55-09',
      'Region[200-1400] Molarity (nmol/l)' => '',
      'Total Conc. (ng/ul)' => '',
      'Well Label' => 'Ladder16'
    }
  ];

  Readonly::Scalar my $testdata_path => q(./t/data/file_parsing/ISC_pool_calculator/);
  Readonly::Scalar my $file1 => q(Caliper1_344745_ISC_1_5_2014-07-01_12-55-09_WellTable.csv);

  my $file = wtsi_clarity::util::textfile->new();
  $file->read_content($testdata_path."/".$file1);

  my $reader = wtsi_clarity::util::csv::factories::generic_csv_reader->new();

  my $output = $reader->build(
    file_content => $file->content,
  );

  is_deeply( $output, $EXPECTED_DATA_1, "build() should return the correct content.");
}

{
  my $reader = wtsi_clarity::util::csv::factories::generic_csv_reader->new();

  throws_ok{
    $reader->build()
  } qr/Requires a file content!/, "Requires a file content";
}

1;
