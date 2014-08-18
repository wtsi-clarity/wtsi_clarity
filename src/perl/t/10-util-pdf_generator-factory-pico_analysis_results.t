use strict;
use warnings;
use Test::More tests => 10;

use_ok('wtsi_clarity::util::pdf::factory::pico_analysis_results');

{
  my $CELL = {
    'plateA_fluorescence' => '591995.5',
    'cv' => '0.343403505409531',
    'concentration' => '5.67197315826223',
    'status' => 'Passed',
    'plateB_fluorescence' => '594877.5'
  };

  my $OUTPUT = "5.67\n0.34\nPassed";

  is(wtsi_clarity::util::pdf::factory::pico_analysis_results::format_table_cell($CELL), $OUTPUT, 'Formats a table cell correctly');
}

{
  my $HEADER_ROW = [0,1,2,3,4,5,6,7,8,9,10,11,12];
  is_deeply(wtsi_clarity::util::pdf::factory::pico_analysis_results::table_header_row(), $HEADER_ROW, 'Creates a header row');
}

{
  my $FOOTER_ROW = ['*',1,2,3,4,5,6,7,8,9,10,11,12];
  is_deeply(wtsi_clarity::util::pdf::factory::pico_analysis_results::table_footer_row(), $FOOTER_ROW, 'Creates a footer row');
}

{
  my $HEADER_STYLE = ['HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE','HEADER_STYLE'];
  is_deeply(wtsi_clarity::util::pdf::factory::pico_analysis_results::headers_row(), $HEADER_STYLE, 'Creates a header style row');
}

{
  my $INPUT = { 'status' => 'Passed' };
  my $RESULT = 'PASSED';
  is(wtsi_clarity::util::pdf::factory::pico_analysis_results::format_style_table_cell($INPUT), 'PASSED', 'Formats a style cell correctly');
}

{
  my $INPUT = 'A';
  is(wtsi_clarity::util::pdf::factory::pico_analysis_results::table_row_first_column($INPUT), 'A', 'Creates the first column correctly');
}

{
  my $table_info = {
          'D:5' => {
                   'plateA_fluorescence' => '591995.5',
                   'cv' => '0.343403505409531',
                   'concentration' => '5.67197315826223',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '594877.5'
                 },
          'E:4' => {
                   'plateA_fluorescence' => '1191967',
                   'cv' => '2.26924725499107',
                   'concentration' => '11.3927891277249',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1154318.5'
                 },
          'B:10' => {
                    'plateA_fluorescence' => '774974',
                    'cv' => '0.0376247880107515',
                    'concentration' => '7.4614370908395',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '774561.75'
                  },
          'E:11' => {
                    'plateA_fluorescence' => '859754',
                    'cv' => '0.296488057223671',
                    'concentration' => '8.31794537400462',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '863366.5'
                  },
          'A:8' => {
                   'plateA_fluorescence' => '380846.5',
                   'cv' => '1.8983328621226',
                   'concentration' => '3.62517026662824',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 391210
                 },
          'H:10' => {
                    'plateA_fluorescence' => '1004900.75',
                    'cv' => '3.33390459688392',
                    'concentration' => '9.97192379552046',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1053424.25'
                  },
          'C:2' => {
                   'plateA_fluorescence' => '827347',
                   'cv' => '2.02895569522596',
                   'concentration' => '8.09915514092887',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '851432.25'
                 },
          'E:9' => {
                   'plateA_fluorescence' => '4723.5',
                   'cv' => '58.0433456669683',
                   'concentration' => '-0.105275678918095',
                   'status' => 'Failed',
                   'plateB_fluorescence' => 11300
                 },
          'C:7' => {
                   'plateA_fluorescence' => 553153,
                   'cv' => '2.09821055852025',
                   'concentration' => '5.35664581329702',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 569814
                 },
          'E:8' => {
                   'plateA_fluorescence' => '627138.5',
                   'cv' => '1.09994848112404',
                   'concentration' => '6.05307388144524',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '636970.5'
                 },
          'H:4' => {
                   'plateA_fluorescence' => '973984.5',
                   'cv' => '2.93363325846587',
                   'concentration' => '9.63100996497772',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 1015249
                 },
          'H:5' => {
                   'plateA_fluorescence' => '937039.75',
                   'cv' => '2.14693852207436',
                   'concentration' => '9.20535925015302',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 965929
                 },
          'B:2' => {
                   'plateA_fluorescence' => '1226834.25',
                   'cv' => '0.0848921513350662',
                   'concentration' => '11.9153790947485',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1225362.25'
                 },
          'F:6' => {
                   'plateA_fluorescence' => '84574.75',
                   'cv' => '3.7460966900077',
                   'concentration' => '0.672994109996021',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '89177.25'
                 },
          'A:12' => {
                    'plateA_fluorescence' => '6646.5',
                    'cv' => '45.0735612695308',
                    'concentration' => '-0.0880638269624895',
                    'status' => 'Failed',
                    'plateB_fluorescence' => '12865.25'
                  },
          'C:4' => {
                   'plateA_fluorescence' => 5622,
                   'cv' => '54.1228808306497',
                   'concentration' => '-0.0944622986957171',
                   'status' => 'Failed',
                   'plateB_fluorescence' => 12593
                 },
          'F:7' => {
                   'plateA_fluorescence' => '700706',
                   'cv' => '0.784889075297547',
                   'concentration' => '6.76915131459029',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '708527.25'
                 },
          'B:8' => {
                   'plateA_fluorescence' => '726412.25',
                   'cv' => '1.64694922643149',
                   'concentration' => '7.06870760478216',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '743530.75'
                 },
          'E:7' => {
                   'plateA_fluorescence' => '594708.75',
                   'cv' => '0.940413593682804',
                   'concentration' => '5.72381595207992',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 602671
                 },
          'F:1' => {
                   'plateA_fluorescence' => '1973774.75',
                   'cv' => '0.146272761564905',
                   'concentration' => '19.273679565244',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 1969696
                 },
          'G:6' => {
                   'plateA_fluorescence' => '1019997',
                   'cv' => '2.55930657574865',
                   'concentration' => '10.0669929719246',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1057595.25'
                 },
          'E:12' => {
                    'plateA_fluorescence' => '883967',
                    'cv' => '3.76761379640711',
                    'concentration' => '8.77782735750044',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '932355.75'
                  },
          'C:11' => {
                    'plateA_fluorescence' => '1011650.75',
                    'cv' => '1.56929954929139',
                    'concentration' => '9.91113523015672',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1034354.5'
                  },
          'G:5' => {
                   'plateA_fluorescence' => '3021802.25',
                   'cv' => '0.586531662650464',
                   'concentration' => '29.5130698745444',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2996840.5'
                 },
          'B:12' => {
                    'plateA_fluorescence' => '987292.25',
                    'cv' => '0.746960119808984',
                    'concentration' => '9.61046256886044',
                    'status' => 'Passed',
                    'plateB_fluorescence' => 997777
                  },
          'B:6' => {
                   'plateA_fluorescence' => '377708',
                   'cv' => '0.720053107440166',
                   'concentration' => '3.52418000591345',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '373881.25'
                 },
          'F:11' => {
                    'plateA_fluorescence' => '1527421.25',
                    'cv' => '0.615590298679351',
                    'concentration' => '14.9548764422524',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1540776.75'
                  },
          'D:9' => {
                   'plateA_fluorescence' => '693564.25',
                   'cv' => '2.2980548832358',
                   'concentration' => '6.77313817802615',
                   'status' => 'Passed',
                   'plateB_fluorescence' => 716477
                 },
          'C:9' => {
                   'plateA_fluorescence' => '958029.5',
                   'cv' => '1.69640988456199',
                   'concentration' => '9.38473479866734',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '981292.5'
                 },
          'A:2' => {
                   'plateA_fluorescence' => '1053724.5',
                   'cv' => '1.77127961841178',
                   'concentration' => '10.3462066368316',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1080454.75'
                 },
          'D:12' => {
                    'plateA_fluorescence' => '1156120.75',
                    'cv' => '0.294096313875979',
                    'concentration' => '11.2485835864567',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1160939.25'
                  },
          'H:3' => {
                   'plateA_fluorescence' => '493810.25',
                   'cv' => '0.408281205234418',
                   'concentration' => '4.70292356573958',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '496669.75'
                 },
          'F:9' => {
                   'plateA_fluorescence' => '446213',
                   'cv' => '2.29162165938085',
                   'concentration' => '4.29163148036827',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '460912.25'
                 },
          'B:4' => {
                   'plateA_fluorescence' => '751063.5',
                   'cv' => '3.00815924942855',
                   'concentration' => '7.3885941846666',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '783709.5'
                 },
          'F:8' => {
                   'plateA_fluorescence' => '511565.25',
                   'cv' => '0.420932274518292',
                   'concentration' => '4.84904729161252',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '508529'
                 },
          'H:9' => {
                   'plateA_fluorescence' => '1310471',
                   'cv' => '1.24869277780754',
                   'concentration' => '12.8632139356097',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1333819'
                 },
          'A:3' => {
                   'plateA_fluorescence' => '507112.25',
                   'cv' => '0.672054050327131',
                   'concentration' => '4.84397983028996',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '511955'
                 },
          'D:10' => {
                    'plateA_fluorescence' => '921855',
                    'cv' => '1.33334388959263',
                    'concentration' => '8.9995497608692',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '939403.25'
                  },
          'D:7' => {
                   'plateA_fluorescence' => '866059.25',
                   'cv' => '0.0249269769655814',
                   'concentration' => '8.36083746203933',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '865754'
                 },
          'C:10' => {
                    'plateA_fluorescence' => '753827',
                    'cv' => '1.73693615667565',
                    'concentration' => '7.34728598668499',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '772574.25'
                  },
          'C:6' => {
                   'plateA_fluorescence' => '1643632.75',
                   'cv' => '0.38126597209682',
                   'concentration' => '15.9921961368772',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1634794.25'
                 },
          'G:11' => {
                    'plateA_fluorescence' => '413720.75',
                    'cv' => '1.43661566498063',
                    'concentration' => '3.94035328516338',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '422212.5'
                  },
          'B:1' => {
                   'plateA_fluorescence' => '850484.25',
                   'cv' => '2.51217135724763',
                   'concentration' => '8.36042915393374',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '881246.25'
                 },
          'F:2' => {
                   'plateA_fluorescence' => '1562268.25',
                   'cv' => '1.5779742583669',
                   'concentration' => '15.0627376278861',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1527789.5'
                 },
          'A:4' => {
                   'plateA_fluorescence' => '775045.5',
                   'cv' => '1.97132533805285',
                   'concentration' => '7.57229952608311',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '796958.25'
                 },
          'B:9' => {
                   'plateA_fluorescence' => '868303.5',
                   'cv' => '2.70717611565716',
                   'concentration' => '8.55172211818254',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '902195.5'
                 },
          'G:9' => {
                   'plateA_fluorescence' => '990488.5',
                   'cv' => '1.74389093361007',
                   'concentration' => '9.71230768612258',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1015221.25'
                 },
          'C:8' => {
                   'plateA_fluorescence' => '1391602.75',
                   'cv' => '1.88849436673526',
                   'concentration' => '13.3676866182018',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1354926.5'
                 },
          'A:7' => {
                   'plateA_fluorescence' => '134634.75',
                   'cv' => '2.98195134748271',
                   'concentration' => '1.17291865970204',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '140434.75'
                 },
          'H:8' => {
                   'plateA_fluorescence' => '1048976',
                   'cv' => '1.79820498056279',
                   'concentration' => '10.3007734167802',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1075995.5'
                 },
          'B:3' => {
                   'plateA_fluorescence' => '555555.25',
                   'cv' => '0.456915341800097',
                   'concentration' => '5.31591368747648',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '559156.75'
                 },
          'F:3' => {
                   'plateA_fluorescence' => '2011137.25',
                   'cv' => '0.995486694768555',
                   'concentration' => '19.5237874000863',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1983021.75'
                 },
          'E:5' => {
                   'plateA_fluorescence' => '1281415.75',
                   'cv' => '1.4235052128269',
                   'concentration' => '12.5898596770518',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1307474.75'
                 },
          'G:10' => {
                    'plateA_fluorescence' => '930408.5',
                    'cv' => '2.08430834234653',
                    'concentration' => '9.13471948076738',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '958244'
                  },
          'C:1' => {
                   'plateA_fluorescence' => '2356405.75',
                   'cv' => '4.73904614575303',
                   'concentration' => '23.8760557514663',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2519808.25'
                 },
          'A:9' => {
                   'plateA_fluorescence' => '524689.25',
                   'cv' => '2.0099094637795',
                   'concentration' => '5.06819278974691',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '539818.25'
                 },
          'E:6' => {
                   'plateA_fluorescence' => '794015.25',
                   'cv' => '0.468030611518354',
                   'concentration' => '7.67739753903843',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '799288.25'
                 },
          'F:5' => {
                   'plateA_fluorescence' => '2316367',
                   'cv' => '0.968888627413506',
                   'concentration' => '22.5191245606657',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2284843.75'
                 },
          'H:11' => {
                    'plateA_fluorescence' => '1281784.75',
                    'cv' => '7.91718958712481',
                    'concentration' => '11.7943188253389',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1145877'
                  },
          'B:5' => {
                   'plateA_fluorescence' => '299512.5',
                   'cv' => '2.35691620127021',
                   'concentration' => '2.821486690429',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '309665'
                 },
          'H:1' => {
                   'plateA_fluorescence' => '685648',
                   'cv' => '0.58033640145585',
                   'concentration' => '6.55430723749577',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '680043.75'
                 },
          'G:4' => {
                   'plateA_fluorescence' => '3459829.75',
                   'cv' => '0.692262930174292',
                   'concentration' => '33.7925816688977',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3426122.75'
                 },
          'D:8' => {
                   'plateA_fluorescence' => '953241.75',
                   'cv' => '1.04056387217862',
                   'concentration' => '9.15399137663941',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '939316.5'
                 },
          'G:7' => {
                   'plateA_fluorescence' => '739345.5',
                   'cv' => '1.02944724169029',
                   'concentration' => '7.16537300683169',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '750188.25'
                 },
          'F:4' => {
                   'plateA_fluorescence' => '388620.5',
                   'cv' => '1.96851028112044',
                   'concentration' => '3.70488779839768',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '399592'
                 },
          'D:2' => {
                   'plateA_fluorescence' => '1182899',
                   'cv' => '1.23727752813495',
                   'concentration' => '11.5920989934185',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1203779.75'
                 },
          'E:10' => {
                    'plateA_fluorescence' => '1110469.75',
                    'cv' => '0.0320696953228693',
                    'concentration' => '10.7767878879041',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1110973.5'
                  },
          'C:12' => {
                    'plateA_fluorescence' => '898581',
                    'cv' => '1.67720630745146',
                    'concentration' => '8.78971270069489',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '920150.5'
                  },
          'A:11' => {
                    'plateA_fluorescence' => '118578.75',
                    'cv' => '5.79448414960782',
                    'concentration' => '1.03584679146905',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '128711'
                  },
          'B:11' => {
                    'plateA_fluorescence' => '529920.25',
                    'cv' => '0.171191642913723',
                    'concentration' => '5.05150273334618',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '531204.75'
                  },
          'G:8' => {
                   'plateA_fluorescence' => '703189.25',
                   'cv' => '3.91539638286639',
                   'concentration' => '6.95266052008901',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '743235'
                 },
          'H:2' => {
                   'plateA_fluorescence' => '3393276.5',
                   'cv' => '1.5903145644393',
                   'concentration' => '33.682966362037',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3470460.75'
                 },
          'H:7' => {
                   'plateA_fluorescence' => '863982.75',
                   'cv' => '3.0997701849366',
                   'concentration' => '8.53292267549613',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '902706.25'
                 },
          'A:5' => {
                   'plateA_fluorescence' => '615407',
                   'cv' => '1.47497464974343',
                   'concentration' => '5.9527966179662',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '628379.25'
                 },
          'E:2' => {
                   'plateA_fluorescence' => '835318.25',
                   'cv' => '0.611230078666851',
                   'concentration' => '8.02350218682686',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '828128.75'
                 },
          'G:12' => {
                    'plateA_fluorescence' => '246032.25',
                    'cv' => '0.0400096989428572',
                    'concentration' => '2.24431049385709',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '246171.5'
                  },
          'G:3' => {
                   'plateA_fluorescence' => '437462.5',
                   'cv' => '1.95697258406253',
                   'concentration' => '4.19332544454099',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '449739.5'
                 },
          'E:3' => {
                   'plateA_fluorescence' => '951238.5',
                   'cv' => '1.05652086793281',
                   'concentration' => '9.13332309171745',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '937131'
                 },
          'B:7' => {
                   'plateA_fluorescence' => '759975.75',
                   'cv' => '2.12829633051477',
                   'concentration' => '7.43005287687444',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '783199.5'
                 },
          'G:1' => {
                   'plateA_fluorescence' => '1094538.5',
                   'cv' => '0.437604227247542',
                   'concentration' => '10.650612048362',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1101333.25'
                 },
          'H:6' => {
                   'plateA_fluorescence' => '583519.25',
                   'cv' => '2.69193947524888',
                   'concentration' => '5.68584329826',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '606164.75'
                 },
          'H:12' => {
                    'plateA_fluorescence' => '1030577.25',
                    'cv' => '1.00112596308512',
                    'concentration' => '10.0583938305225',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1045272.25'
                  },
          'G:2' => {
                   'plateA_fluorescence' => '284569.5',
                   'cv' => '5.33011417932021',
                   'concentration' => '2.73391508703329',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '306860.25'
                 },
          'A:1' => {
                   'plateA_fluorescence' => '1499520.5',
                   'cv' => '3.01338960594785',
                   'concentration' => '14.9358179521274',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1564815'
                 },
          'A:10' => {
                    'plateA_fluorescence' => '906611',
                    'cv' => '3.71700418273974',
                    'concentration' => '8.53339759580022',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '860174.25'
                  },
          'A:6' => {
                   'plateA_fluorescence' => '360449.75',
                   'cv' => '3.21180695335043',
                   'concentration' => '3.45541154588184',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '377202.5'
                 },
          'D:11' => {
                    'plateA_fluorescence' => '755367.25',
                    'cv' => '2.12396038826799',
                    'concentration' => '7.15968506521575',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '733013.75'
                  },
          'E:1' => {
                   'plateA_fluorescence' => '754848.25',
                   'cv' => '0.864157714763569',
                   'concentration' => '7.21961877403213',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '745679.25'
                 },
          'F:12' => {
                    'plateA_fluorescence' => '860013.75',
                    'cv' => '1.87872489555928',
                    'concentration' => '8.41694837079763',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '883171.25'
                  },
          'D:1' => {
                   'plateA_fluorescence' => '735892.75',
                   'cv' => '0.502408095904591',
                   'concentration' => '7.10369011102519',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '741140'
                 },
          'C:3' => {
                   'plateA_fluorescence' => '625157.25',
                   'cv' => '1.41571684471433',
                   'concentration' => '6.04739210762545',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '637800.25'
                 },
          'D:6' => {
                   'plateA_fluorescence' => '1001214.5',
                   'cv' => '0.442032493598967',
                   'concentration' => '9.72709929486619',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1007493'
                 },
          'C:5' => {
                   'plateA_fluorescence' => '5283.75',
                   'cv' => '48.9646510877322',
                   'concentration' => '-0.104582418630053',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '10880.25'
                 },
          'D:4' => {
                   'plateA_fluorescence' => '5352.5',
                   'cv' => '56.1051010902717',
                   'concentration' => '-0.0967826236099644',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '12392.25'
                 },
          'F:10' => {
                    'plateA_fluorescence' => '706868.75',
                    'cv' => '0.751489698078703',
                    'concentration' => '6.82864217564261',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '714421.25'
                  },
          'D:3' => {
                   'plateA_fluorescence' => '848881.75',
                   'cv' => '2.92826967876807',
                   'concentration' => '8.02288910788886',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '814441'
                 }
        };

  my $table_data = [
          [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12
          ],
          [
            'A',
            '14.94
3.01
Passed',
            '10.35
1.77
Passed',
            '4.84
0.67
Passed',
            '7.57
1.97
Passed',
            '5.95
1.47
Passed',
            '3.46
3.21
Passed',
            '1.17
2.98
Passed',
            '3.63
1.90
Passed',
            '5.07
2.01
Passed',
            '8.53
3.72
Passed',
            '1.04
5.79
Passed',
            '-0.09
45.07
Failed'
          ],
          [
            'B',
            '8.36
2.51
Passed',
            '11.92
0.08
Passed',
            '5.32
0.46
Passed',
            '7.39
3.01
Passed',
            '2.82
2.36
Passed',
            '3.52
0.72
Passed',
            '7.43
2.13
Passed',
            '7.07
1.65
Passed',
            '8.55
2.71
Passed',
            '7.46
0.04
Passed',
            '5.05
0.17
Passed',
            '9.61
0.75
Passed'
          ],
          [
            'C',
            '23.88
4.74
Passed',
            '8.10
2.03
Passed',
            '6.05
1.42
Passed',
            '-0.09
54.12
Failed',
            '-0.10
48.96
Failed',
            '15.99
0.38
Passed',
            '5.36
2.10
Passed',
            '13.37
1.89
Passed',
            '9.38
1.70
Passed',
            '7.35
1.74
Passed',
            '9.91
1.57
Passed',
            '8.79
1.68
Passed'
          ],
          [
            'D',
            '7.10
0.50
Passed',
            '11.59
1.24
Passed',
            '8.02
2.93
Passed',
            '-0.10
56.11
Failed',
            '5.67
0.34
Passed',
            '9.73
0.44
Passed',
            '8.36
0.02
Passed',
            '9.15
1.04
Passed',
            '6.77
2.30
Passed',
            '9.00
1.33
Passed',
            '7.16
2.12
Passed',
            '11.25
0.29
Passed'
          ],
          [
            'E',
            '7.22
0.86
Passed',
            '8.02
0.61
Passed',
            '9.13
1.06
Passed',
            '11.39
2.27
Passed',
            '12.59
1.42
Passed',
            '7.68
0.47
Passed',
            '5.72
0.94
Passed',
            '6.05
1.10
Passed',
            '-0.11
58.04
Failed',
            '10.78
0.03
Passed',
            '8.32
0.30
Passed',
            '8.78
3.77
Passed'
          ],
          [
            'F',
            '19.27
0.15
Passed',
            '15.06
1.58
Passed',
            '19.52
1.00
Passed',
            '3.70
1.97
Passed',
            '22.52
0.97
Passed',
            '0.67
3.75
Passed',
            '6.77
0.78
Passed',
            '4.85
0.42
Passed',
            '4.29
2.29
Passed',
            '6.83
0.75
Passed',
            '14.95
0.62
Passed',
            '8.42
1.88
Passed'
          ],
          [
            'G',
            '10.65
0.44
Passed',
            '2.73
5.33
Passed',
            '4.19
1.96
Passed',
            '33.79
0.69
Passed',
            '29.51
0.59
Passed',
            '10.07
2.56
Passed',
            '7.17
1.03
Passed',
            '6.95
3.92
Passed',
            '9.71
1.74
Passed',
            '9.13
2.08
Passed',
            '3.94
1.44
Passed',
            '2.24
0.04
Passed'
          ],
          [
            'H',
            '6.55
0.58
Passed',
            '33.68
1.59
Passed',
            '4.70
0.41
Passed',
            '9.63
2.93
Passed',
            '9.21
2.15
Passed',
            '5.69
2.69
Passed',
            '8.53
3.10
Passed',
            '10.30
1.80
Passed',
            '12.86
1.25
Passed',
            '9.97
3.33
Passed',
            '11.79
7.92
Passed',
            '10.06
1.00
Passed'
          ],
          [
            '*',
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            10,
            11,
            12
          ]
        ];

  my $table_style = [
            [
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'FAILED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'FAILED',
              'FAILED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'FAILED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'FAILED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED',
              'PASSED'
            ],
            [
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE',
              'HEADER_STYLE'
            ]
          ];

  # my $table_data = 
  my $factory = wtsi_clarity::util::pdf::factory::pico_analysis_results->new();
  my $file = $factory->build($table_info);

  is_deeply($factory->_format($factory->plate_table, $table_info), $table_data);
  is_deeply($factory->_format($factory->plate_style_table, $table_info), $table_style);

  ok($file, 'does create a file object');
  # $file->saveas('./pico_a.pdf');
}

1;