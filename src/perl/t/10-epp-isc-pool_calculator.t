use strict;
use warnings;
use Test::More tests => 6;
use XML::LibXML;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/pool_calculator';

use_ok('wtsi_clarity::epp::isc::pool_calculator');

{

  my $pool_calculator = wtsi_clarity::epp::isc::pool_calculator->new(
    process_url => 'http://testserver.com:1234/processes/24-22178',
  );

  is($pool_calculator->min_volume, 5, 'Fetches the min volume correctly');
  is($pool_calculator->max_volume, 50, 'Fetches the max volume correctly');
  is($pool_calculator->max_total_volume, 200, 'Fetches the max total volume correctly');
}

{
  my $_384_molarities = {
          'E:23' => '8.87027982756011',
          'B:19' => '0',
          'D:5' => '8.90397537667753',
          'E:11' => '10.0922511285386',
          'E:9' => '6.73636802423812',
          'C:7' => '2.54144132878456',
          'F:13' => '7.82639385722859',
          'C:13' => '5.26137383384613',
          'H:5' => '2.16761699205421',
          'A:13' => '10.4933811332512',
          'D:19' => '0.00115227745919105',
          'F:7' => '3.41354329696445',
          'F:1' => '1.86129570115488',
          'E:7' => '3.22354077478513',
          'C:21' => '0.0124031220019527',
          'C:11' => '6.71457756710711',
          'H:21' => '0.0117999400838692',
          'G:5' => '2.15106265427231',
          'D:17' => '0.0233022449089023',
          'F:11' => '10.3406951286429',
          'D:9' => '7.17409566181924',
          'C:9' => '7.11170103637566',
          'F:9' => '6.62208049130793',
          'H:3' => '3.1810511518989',
          'F:21' => '0.00801634771609444',
          'H:13' => '8.00989892114275',
          'H:9' => '3.74449165989441',
          'A:3' => '2.68630613828796',
          'D:21' => '0.0226993531085896',
          'G:19' => '0.0305894129317842',
          'D:7' => '2.56841697352717',
          'G:11' => '3.83936127073911',
          'B:1' => '2.23010180190948',
          'G:17' => '0.026890941472556',
          'D:13' => '5.06694282730619',
          'H:23' => '0.0334524340966265',
          'B:23' => '0.0154598862487031',
          'B:17' => '0',
          'B:9' => '6.87775602652126',
          'G:9' => '3.82441137334695',
          'A:7' => '2.15543793732021',
          'G:15' => '6.1226093378121',
          'F:17' => '0',
          'E:21' => '0.0311836899502632',
          'B:3' => '2.63109036833625',
          'F:3' => '3.92798410215347',
          'E:17' => '0.0275965361355408',
          'B:15' => '2.79582046955938',
          'E:5' => '5.74486613636694',
          'E:15' => '8.66505335777844',
          'C:1' => '2.53750708774114',
          'A:9' => '7.29111708510066',
          'F:5' => '5.20891670058844',
          'G:13' => '8.7363217924316',
          'H:11' => '3.9405669922414',
          'C:23' => '0.0200751211366011',
          'B:5' => '6.38428532926411',
          'H:1' => '7.43846491627343',
          'E:13' => '8.1866409872914',
          'G:7' => '2.2934355739298',
          'A:11' => '4.39541396195783',
          'B:11' => '4.38396098504144',
          'H:19' => '0.0233760426607249',
          'F:23' => '0.0246467141786154',
          'D:23' => '0',
          'A:23' => '0',
          'A:17' => '0.026157499230803',
          'H:7' => '2.35489516425007',
          'A:5' => '6.31046284299825',
          'B:13' => '10.3955547895858',
          'G:3' => '3.33732349959476',
          'E:3' => '3.78753038420437',
          'G:1' => '7.48832047000404',
          'B:7' => '2.14016376031209',
          'C:15' => '2.88870366132435',
          'A:1' => '2.20151284050569',
          'F:15' => '8.22097077713259',
          'H:15' => '6.25293902946725',
          'D:11' => '6.53149914902806',
          'E:1' => '1.82019232133282',
          'E:19' => '0.0158413612867155',
          'A:15' => '2.79303561474899',
          'D:1' => '2.5494791587686',
          'A:19' => '0.0376649928211036',
          'G:23' => '0.00967793134455713',
          'C:3' => '3.64608387263729',
          'H:17' => '0.0123503805389079',
          'C:5' => '8.37543824268201',
          'G:21' => '0',
          'C:19' => '0.0075333317065208',
          'A:21' => '0',
          'D:15' => '2.83492184314656',
          'C:17' => '0.00580325089169532',
          'B:21' => '0',
          'F:19' => '0',
          'D:3' => '3.72712979142387'
        };

  my $_96_plate_molarities = {
          'D:5' => '3.78445151662068',
          'E:4' => '0',
          'E:11' => '0',
          'B:10' => '0.00434280458285593',
          'H:10' => '0',
          'A:8' => '2.79442804215418',
          'E:9' => '0',
          'C:7' => '8.00651742225999',
          'C:2' => '3.85775724317892',
          'E:8' => '0',
          'H:5' => '0',
          'H:4' => '0',
          'B:2' => '3.68660683203058',
          'A:12' => '0.00772994312435155',
          'F:6' => '0',
          'C:4' => '3.31854203587479',
          'F:7' => '0',
          'B:8' => '2.86181275223545',
          'E:7' => '0',
          'G:6' => '0',
          'F:1' => '0',
          'E:12' => '0',
          'C:11' => '0.0196000188331788',
          'G:5' => '0',
          'B:12' => '0.0100375605683005',
          'F:11' => '0',
          'B:6' => '6.62303835806759',
          'D:9' => '0.019620661005732',
          'C:9' => '0.0137982680677704',
          'A:2' => '2.6586982533121',
          'D:12' => '0.0215651827205918',
          'F:9' => '0',
          'H:3' => '0',
          'B:4' => '2.55492915115587',
          'F:8' => '0',
          'H:9' => '0',
          'D:10' => '0.0269827277962546',
          'A:3' => '6.34737408613118',
          'D:7' => '8.37311035678717',
          'C:10' => '0.00792068064335775',
          'C:6' => '10.2164731285907',
          'G:11' => '0',
          'B:1' => '2.54349312325487',
          'F:2' => '0',
          'A:4' => '2.14780084881615',
          'B:9' => '0.0145527479002988',
          'G:9' => '0',
          'C:8' => '8.44301206745552',
          'A:7' => '10.4444679614185',
          'H:8' => '0',
          'B:3' => '8.63970680967977',
          'F:3' => '0',
          'E:5' => '0',
          'G:10' => '0',
          'C:1' => '1.84074401124385',
          'E:6' => '0',
          'A:9' => '0.0130787496154015',
          'F:5' => '0',
          'H:11' => '0',
          'B:5' => '7.14289834909745',
          'H:1' => '0',
          'G:4' => '0',
          'D:8' => '6.18777418363968',
          'G:7' => '0',
          'D:2' => '3.25918732574683',
          'F:4' => '0',
          'C:12' => '4.44746327086936',
          'A:11' => '0',
          'E:10' => '0',
          'B:11' => '0.0175512375552711',
          'G:8' => '0',
          'H:2' => '0',
          'H:7' => '0',
          'A:5' => '7.08443655581096',
          'G:12' => '0',
          'E:2' => '0',
          'G:3' => '0',
          'E:3' => '0',
          'G:1' => '0',
          'B:7' => '5.16415833057616',
          'H:12' => '0',
          'H:6' => '0',
          'G:2' => '0',
          'A:10' => '0.0188324964105518',
          'A:1' => '2.21580732120758',
          'A:6' => '4.38968747349963',
          'D:11' => '0.0058999700419346',
          'E:1' => '0',
          'F:12' => '0',
          'D:1' => '7.46339269313873',
          'C:3' => '5.47689141847769',
          'D:6' => '3.88996413149026',
          'C:5' => '6.67922425777302',
          'D:4' => '2.32416536908994',
          'F:10' => '0',
          'D:3' => '2.15933982316326'
        };

  my $forked_plate_process_xml = XML::LibXML->load_xml(location => 't/data/epp/isc/pool_calculator/GET/processes.24-21361');

  my $pool_calculator = wtsi_clarity::epp::isc::pool_calculator->new(
    process_url => 'http://testserver.com:1234/processes/24-22178',
    _forked_plate_process_xml => $forked_plate_process_xml,
  );

  is_deeply($pool_calculator->_384_plate_molarities, $_384_molarities, 'Finds the 384 molarities correctly');
  is_deeply($pool_calculator->_96_plate_molarities, $_96_plate_molarities, 'Calculates the 96 molarities correctly');
}