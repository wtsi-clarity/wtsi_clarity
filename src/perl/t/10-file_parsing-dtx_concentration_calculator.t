use strict;
use warnings;
use Test::More tests => 613;
use Test::Exception;
use Test::Warn;
use Carp;
use Data::Dumper;
use Readonly;

# Temporary!!!!!!
use wtsi_clarity::file_parsing::dtx_parser;

use_ok('wtsi_clarity::file_parsing::dtx_concentration_calculator', 'can use dtx_concentration_calculator');

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $testdata_path   => q(./t/data/file_parsing/dtx_concentration_calculator/);
Readonly::Scalar my $standard_name   => q(1220344030849_ Pico-green assay run_AllRawData_06-06-2014_10.01.02.52.xml);
Readonly::Scalar my $plateA_name     => q(1220344030849-4330332423663_ Pico-green assay run_AllRawData_06-06-2014_10.32.21.68.xml);
Readonly::Scalar my $plateB_name     => q(1220344030849-4340332423730_ Pico-green assay run_AllRawData_06-06-2014_10.36.14.34.xml);
Readonly::Scalar my $standard_name_2 => q(1220380948795_ Pico-green assay run_AllRawData_12-12-2014_10.35.04.66.xml);
Readonly::Scalar my $plateA_name_2   => q(1220380948795-5260272617817_ Pico-green assay run_AllRawData_12-12-2014_10.49.50.63.xml);
Readonly::Scalar my $plateB_name_2   => q(1220380948795-5260272618821_ Pico-green assay run_AllRawData_12-12-2014_10.46.26.93.xml);

## use critic

my $EXPECTED_DATA_1 = {
          'D:5' => {
                   'plateA_fluorescence' => '591995.5',
                   'cv' => '0.24282294735831',
                   'concentration' => '283.598657913112',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '594877.5'
                 },
          'E:4' => {
                   'plateA_fluorescence' => '1191967',
                   'cv' => '1.60460012219314',
                   'concentration' => '569.639456386243',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1154318.5'
                 },
          'B:10' => {
                    'plateA_fluorescence' => '774974',
                    'cv' => '0.0266047427431087',
                    'concentration' => '373.071854541975',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '774561.75'
                  },
          'E:11' => {
                    'plateA_fluorescence' => '859754',
                    'cv' => '0.209648715803683',
                    'concentration' => '415.897268700231',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '863366.5'
                  },
          'A:8' => {
                   'plateA_fluorescence' => '380846.5',
                   'cv' => '1.34232403975616',
                   'concentration' => '181.258513331412',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '391210'
                 },
          'H:10' => {
                    'plateA_fluorescence' => '1004900.75',
                    'cv' => '2.35742654828562',
                    'concentration' => '498.596189776023',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1053424.25'
                  },
          'C:2' => {
                   'plateA_fluorescence' => '827347',
                   'cv' => '1.43468833082134',
                   'concentration' => '404.957757046443',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '851432.25'
                 },
          'E:9' => {
                   'plateA_fluorescence' => '4723.5',
                   'cv' => '41.0428433238681',
                   'concentration' => '-5.26378394590473',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '11300'
                 },
          'C:7' => {
                   'plateA_fluorescence' => '553153',
                   'cv' => '1.48365891428688',
                   'concentration' => '267.832290664851',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '569814'
                 },
          'E:8' => {
                   'plateA_fluorescence' => '627138.5',
                   'cv' => '0.777781029958651',
                   'concentration' => '302.653694072262',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '636970.5'
                 },
          'H:4' => {
                   'plateA_fluorescence' => '973984.5',
                   'cv' => '2.0743919705756',
                   'concentration' => '481.550498248886',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1015249'
                 },
          'H:5' => {
                   'plateA_fluorescence' => '937039.75',
                   'cv' => '1.5181147877494',
                   'concentration' => '460.267962507651',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '965929'
                 },
          'B:2' => {
                   'plateA_fluorescence' => '1226834.25',
                   'cv' => '0.0600278158785399',
                   'concentration' => '595.768954737424',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1225362.25'
                 },
          'F:6' => {
                   'plateA_fluorescence' => '84574.75',
                   'cv' => '2.64889037248492',
                   'concentration' => '33.649705499801',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '89177.25'
                 },
          'A:12' => {
                    'plateA_fluorescence' => '6646.5',
                    'cv' => '31.8718208259126',
                    'concentration' => '-4.40319134812448',
                    'status' => 'Failed',
                    'plateB_fluorescence' => '12865.25'
                  },
          'C:4' => {
                   'plateA_fluorescence' => '5622',
                   'cv' => '38.2706560527038',
                   'concentration' => '-4.72311493478585',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '12593'
                 },
          'F:7' => {
                   'plateA_fluorescence' => '700706',
                   'cv' => '0.555000387622134',
                   'concentration' => '338.457565729515',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '708527.25'
                 },
          'B:8' => {
                   'plateA_fluorescence' => '726412.25',
                   'cv' => '1.16456896627964',
                   'concentration' => '353.435380239108',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '743530.75'
                 },
          'E:7' => {
                   'plateA_fluorescence' => '594708.75',
                   'cv' => '0.664972829213121',
                   'concentration' => '286.190797603996',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '602671'
                 },
          'F:1' => {
                   'plateA_fluorescence' => '1973774.75',
                   'cv' => '0.103430461605427',
                   'concentration' => '963.683978262201',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1969696'
                 },
          'G:6' => {
                   'plateA_fluorescence' => '1019997',
                   'cv' => '1.80970303484719',
                   'concentration' => '503.349648596228',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1057595.25'
                 },
          'E:12' => {
                    'plateA_fluorescence' => '883967',
                    'cv' => '2.66410526433146',
                    'concentration' => '438.891367875022',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '932355.75'
                  },
          'C:11' => {
                    'plateA_fluorescence' => '1011650.75',
                    'cv' => '1.10966235301693',
                    'concentration' => '495.556761507836',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1034354.5'
                  },
          'G:5' => {
                   'plateA_fluorescence' => '3021802.25',
                   'cv' => '0.414740516040764',
                   'concentration' => '1475.65349372722',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2996840.5'
                 },
          'B:12' => {
                    'plateA_fluorescence' => '987292.25',
                    'cv' => '0.528180565992849',
                    'concentration' => '480.523128443022',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '997777'
                  },
          'B:6' => {
                   'plateA_fluorescence' => '377708',
                   'cv' => '0.509154435085387',
                   'concentration' => '176.209000295673',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '373881.25'
                 },
          'F:11' => {
                    'plateA_fluorescence' => '1527421.25',
                    'cv' => '0.435288074628821',
                    'concentration' => '747.743822112622',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1540776.75'
                  },
          'D:9' => {
                   'plateA_fluorescence' => '693564.25',
                   'cv' => '1.62497019147489',
                   'concentration' => '338.656908901307',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '716477'
                 },
          'C:9' => {
                   'plateA_fluorescence' => '958029.5',
                   'cv' => '1.19954293304567',
                   'concentration' => '469.236739933367',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '981292.5'
                 },
          'A:2' => {
                   'plateA_fluorescence' => '1053724.5',
                   'cv' => '1.25248382955649',
                   'concentration' => '517.310331841578',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1080454.75'
                 },
          'D:12' => {
                    'plateA_fluorescence' => '1156120.75',
                    'cv' => '0.207957497863672',
                    'concentration' => '562.429179322837',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1160939.25'
                  },
          'H:3' => {
                   'plateA_fluorescence' => '493810.25',
                   'cv' => '0.288698408852274',
                   'concentration' => '235.146178286979',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '496669.75'
                 },
          'F:9' => {
                   'plateA_fluorescence' => '446213',
                   'cv' => '1.62042121526217',
                   'concentration' => '214.581574018413',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '460912.25'
                 },
          'B:4' => {
                   'plateA_fluorescence' => '751063.5',
                   'cv' => '2.12708980415996',
                   'concentration' => '369.42970923333',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '783709.5'
                 },
          'F:8' => {
                   'plateA_fluorescence' => '511565.25',
                   'cv' => '0.297644065732162',
                   'concentration' => '242.452364580626',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '508529'
                 },
          'H:9' => {
                   'plateA_fluorescence' => '1310471',
                   'cv' => '0.882959130806379',
                   'concentration' => '643.160696780483',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1333819'
                 },
          'A:3' => {
                   'plateA_fluorescence' => '507112.25',
                   'cv' => '0.475213976310199',
                   'concentration' => '242.198991514498',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '511955'
                 },
          'D:10' => {
                    'plateA_fluorescence' => '921855',
                    'cv' => '0.942816505984594',
                    'concentration' => '449.97748804346',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '939403.25'
                  },
          'D:7' => {
                   'plateA_fluorescence' => '866059.25',
                   'cv' => '0.0176260344468435',
                   'concentration' => '418.041873101966',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '865754'
                 },
          'C:10' => {
                    'plateA_fluorescence' => '753827',
                    'cv' => '1.22819933487345',
                    'concentration' => '367.36429933425',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '772574.25'
                  },
          'C:6' => {
                   'plateA_fluorescence' => '1643632.75',
                   'cv' => '0.269595754305342',
                   'concentration' => '799.609806843861',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1634794.25'
                 },
          'G:11' => {
                    'plateA_fluorescence' => '413720.75',
                    'cv' => '1.01584067866663',
                    'concentration' => '197.017664258169',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '422212.5'
                  },
          'B:1' => {
                   'plateA_fluorescence' => '850484.25',
                   'cv' => '1.77637340221241',
                   'concentration' => '418.021457696687',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '881246.25'
                 },
          'F:2' => {
                   'plateA_fluorescence' => '1562268.25',
                   'cv' => '1.11579629862905',
                   'concentration' => '753.136881394304',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1527789.5'
                 },
          'A:4' => {
                   'plateA_fluorescence' => '775045.5',
                   'cv' => '1.39393751446204',
                   'concentration' => '378.614976304156',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '796958.25'
                 },
          'B:9' => {
                   'plateA_fluorescence' => '868303.5',
                   'cv' => '1.91426258924744',
                   'concentration' => '427.586105909127',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '902195.5'
                 },
          'G:9' => {
                   'plateA_fluorescence' => '990488.5',
                   'cv' => '1.23311710480542',
                   'concentration' => '485.615384306129',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1015221.25'
                 },
          'C:8' => {
                   'plateA_fluorescence' => '1391602.75',
                   'cv' => '1.3353671729511',
                   'concentration' => '668.384330910091',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1354926.5'
                 },
          'A:7' => {
                   'plateA_fluorescence' => '134634.75',
                   'cv' => '2.10855801897339',
                   'concentration' => '58.645932985102',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '140434.75'
                 },
          'H:8' => {
                   'plateA_fluorescence' => '1048976',
                   'cv' => '1.27152293571937',
                   'concentration' => '515.038670839009',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1075995.5'
                 },
          'B:3' => {
                   'plateA_fluorescence' => '555555.25',
                   'cv' => '0.323087936615018',
                   'concentration' => '265.795684373824',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '559156.75'
                 },
          'F:3' => {
                   'plateA_fluorescence' => '2011137.25',
                   'cv' => '0.703915392451828',
                   'concentration' => '976.189370004316',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1983021.75'
                 },
          'E:5' => {
                   'plateA_fluorescence' => '1281415.75',
                   'cv' => '1.0065701890443',
                   'concentration' => '629.492983852589',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1307474.75'
                 },
          'G:10' => {
                    'plateA_fluorescence' => '930408.5',
                    'cv' => '1.47382856295692',
                    'concentration' => '456.735974038369',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '958244'
                  },
          'C:1' => {
                   'plateA_fluorescence' => '2356405.75',
                   'cv' => '3.35101166601794',
                   'concentration' => '1193.80278757332',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2519808.25'
                 },
          'A:9' => {
                   'plateA_fluorescence' => '524689.25',
                   'cv' => '1.4212206114095',
                   'concentration' => '253.409639487345',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '539818.25'
                 },
          'E:6' => {
                   'plateA_fluorescence' => '794015.25',
                   'cv' => '0.330947619207514',
                   'concentration' => '383.869876951922',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '799288.25'
                 },
          'F:5' => {
                   'plateA_fluorescence' => '2316367',
                   'cv' => '0.685107718658616',
                   'concentration' => '1125.95622803329',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2284843.75'
                 },
          'H:11' => {
                    'plateA_fluorescence' => '1281784.75',
                    'cv' => '5.59829844499548',
                    'concentration' => '589.715941266947',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1145877'
                  },
          'B:5' => {
                   'plateA_fluorescence' => '299512.5',
                   'cv' => '1.66659142860661',
                   'concentration' => '141.07433452145',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '309665'
                 },
          'H:1' => {
                   'plateA_fluorescence' => '685648',
                   'cv' => '0.41035980483883',
                   'concentration' => '327.715361874788',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '680043.75'
                 },
          'G:4' => {
                   'plateA_fluorescence' => '3459829.75',
                   'cv' => '0.489503812290311',
                   'concentration' => '1689.62908344488',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3426122.75'
                 },
          'D:8' => {
                   'plateA_fluorescence' => '953241.75',
                   'cv' => '0.735789770275235',
                   'concentration' => '457.699568831971',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '939316.5'
                 },
          'G:7' => {
                   'plateA_fluorescence' => '739345.5',
                   'cv' => '0.727929125472988',
                   'concentration' => '358.268650341585',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '750188.25'
                 },
          'F:4' => {
                   'plateA_fluorescence' => '388620.5',
                   'cv' => '1.3919469686157',
                   'concentration' => '185.244389919884',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '399592'
                 },
          'D:2' => {
                   'plateA_fluorescence' => '1182899',
                   'cv' => '0.874887330353949',
                   'concentration' => '579.604949670924',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1203779.75'
                 },
          'E:10' => {
                    'plateA_fluorescence' => '1110469.75',
                    'cv' => '0.0226766990333874',
                    'concentration' => '538.839394395207',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1110973.5'
                  },
          'C:12' => {
                    'plateA_fluorescence' => '898581',
                    'cv' => '1.18596395344777',
                    'concentration' => '439.485635034745',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '920150.5'
                  },
          'A:11' => {
                    'plateA_fluorescence' => '118578.75',
                    'cv' => '4.09731903566565',
                    'concentration' => '51.7923395734526',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '128711'
                  },
          'B:11' => {
                    'plateA_fluorescence' => '529920.25',
                    'cv' => '0.121050771586759',
                    'concentration' => '252.575136667309',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '531204.75'
                  },
          'G:8' => {
                   'plateA_fluorescence' => '703189.25',
                   'cv' => '2.76860333335811',
                   'concentration' => '347.633026004451',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '743235'
                 },
          'H:2' => {
                   'plateA_fluorescence' => '3393276.5',
                   'cv' => '1.12452221273476',
                   'concentration' => '1684.14831810185',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3470460.75'
                 },
          'H:7' => {
                   'plateA_fluorescence' => '863982.75',
                   'cv' => '2.19186851788855',
                   'concentration' => '426.646133774807',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '902706.25'
                 },
          'A:5' => {
                   'plateA_fluorescence' => '615407',
                   'cv' => '1.04296457691183',
                   'concentration' => '297.63983089831',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '628379.25'
                 },
          'E:2' => {
                   'plateA_fluorescence' => '835318.25',
                   'cv' => '0.432204933490517',
                   'concentration' => '401.175109341343',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '828128.75'
                 },
          'G:12' => {
                    'plateA_fluorescence' => '246032.25',
                    'cv' => '0.0282911294357266',
                    'concentration' => '112.215524692855',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '246171.5'
                  },
          'G:3' => {
                   'plateA_fluorescence' => '437462.5',
                   'cv' => '1.38378858478678',
                   'concentration' => '209.666272227049',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '449739.5'
                 },
          'E:3' => {
                   'plateA_fluorescence' => '951238.5',
                   'cv' => '0.747073070180386',
                   'concentration' => '456.666154585872',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '937131'
                 },
          'B:7' => {
                   'plateA_fluorescence' => '759975.75',
                   'cv' => '1.50493276768144',
                   'concentration' => '371.502643843722',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '783199.5'
                 },
          'G:1' => {
                   'plateA_fluorescence' => '1094538.5',
                   'cv' => '0.309432916562636',
                   'concentration' => '532.530602418102',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1101333.25'
                 },
          'H:6' => {
                   'plateA_fluorescence' => '583519.25',
                   'cv' => '1.90348865749224',
                   'concentration' => '284.292164913',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '606164.75'
                 },
          'H:12' => {
                    'plateA_fluorescence' => '1030577.25',
                    'cv' => '0.707902957319401',
                    'concentration' => '502.919691526127',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1045272.25'
                  },
          'G:2' => {
                   'plateA_fluorescence' => '284569.5',
                   'cv' => '3.76895988069589',
                   'concentration' => '136.695754351664',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '306860.25'
                 },
          'A:1' => {
                   'plateA_fluorescence' => '1499520.5',
                   'cv' => '2.13078822472278',
                   'concentration' => '746.790897606372',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1564815'
                 },
          'A:10' => {
                    'plateA_fluorescence' => '906611',
                    'cv' => '2.62831886331403',
                    'concentration' => '426.669879790011',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '860174.25'
                  },
          'A:6' => {
                   'plateA_fluorescence' => '360449.75',
                   'cv' => '2.27109047657619',
                   'concentration' => '172.770577294092',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '377202.5'
                 },
          'D:11' => {
                    'plateA_fluorescence' => '755367.25',
                    'cv' => '1.50186679351591',
                    'concentration' => '357.984253260787',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '733013.75'
                  },
          'E:1' => {
                   'plateA_fluorescence' => '754848.25',
                   'cv' => '0.61105178012399',
                   'concentration' => '360.980938701607',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '745679.25'
                 },
          'F:12' => {
                    'plateA_fluorescence' => '860013.75',
                    'cv' => '1.32845911363395',
                    'concentration' => '420.847418539882',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '883171.25'
                  },
          'D:1' => {
                   'plateA_fluorescence' => '735892.75',
                   'cv' => '0.355256171537158',
                   'concentration' => '355.18450555126',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '741140'
                 },
          'C:3' => {
                   'plateA_fluorescence' => '625157.25',
                   'cv' => '1.00106298113753',
                   'concentration' => '302.369605381273',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '637800.25'
                 },
          'D:6' => {
                   'plateA_fluorescence' => '1001214.5',
                   'cv' => '0.312564173728629',
                   'concentration' => '486.35496474331',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1007493'
                 },
          'C:5' => {
                   'plateA_fluorescence' => '5283.75',
                   'cv' => '34.6232368225687',
                   'concentration' => '-5.22912093150263',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '10880.25'
                 },
          'D:4' => {
                   'plateA_fluorescence' => '5352.5',
                   'cv' => '39.6722974400879',
                   'concentration' => '-4.83913118049822',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '12392.25'
                 },
          'F:10' => {
                    'plateA_fluorescence' => '706868.75',
                    'cv' => '0.531383461503282',
                    'concentration' => '341.43210878213',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '714421.25'
                  },
          'D:3' => {
                   'plateA_fluorescence' => '848881.75',
                   'cv' => '2.07059934699985',
                   'concentration' => '401.144455394443',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '814441'
                 }
        };

my $TEST_DATA_2 = {
  'standard' => {
    'A:1' => 17382,
    'A:2' => 20659.25,
    'A:3' => 17912,
    'A:4' => 17633.25,
    'A:5' => 20045.75,
    'A:6' => 17239.75,
    'A:7' => 18291,
    'A:8' => 122006.25,
    'A:9' => 1052447.5,
    'A:10' => 1108190.75,
    'A:11' => 1123593.25,
    'A:12' => 1075696.5,
    'B:1' => 16198,
    'B:2' => 17604,
    'B:3' => 14984,
    'B:4' => 21127.25,
    'B:5' => 17301.75,
    'B:6' => 18078.25,
    'B:7' => 19107.75,
    'B:8' => 124728,
    'B:9' => 515333.75,
    'B:10' => 538822.75,
    'B:11' => 551347.25,
    'B:12' => 541453.25,
    'C:1' => 16525.25,
    'C:2' => 18522.75,
    'C:3' => 18398.25,
    'C:4' => 16082.75,
    'C:5' => 15316,
    'C:6' => 17830.5,
    'C:7' => 15915,
    'C:8' => 117062.5,
    'C:9' => 272018.75,
    'C:10' => 272230.25,
    'C:11' => 270256.25,
    'C:12' => 272066.25,
    'D:1' => 15015.25,
    'D:2' => 16907,
    'D:3' => 17772,
    'D:4' => 16977.5,
    'D:5' => 16546.25,
    'D:6' => 17406,
    'D:7' => 17550.5,
    'D:8' => 119886.75,
    'D:9' => 136556.5,
    'D:10' => 134623,
    'D:11' => 141901,
    'D:12' => 141372.5,
    'E:1' => 16922.75,
    'E:2' => 13880,
    'E:3' => 17141.75,
    'E:4' => 19930,
    'E:5' => 19317.25,
    'E:6' => 14789.75,
    'E:7' => 19275.75,
    'E:8' => 118374.5,
    'E:9' => 82088.25,
    'E:10' => 80449,
    'E:11' => 76432.25,
    'E:12' => 80660.5,
    'F:1'=> 14333.25,
    'F:2'=> 17262.25,
    'F:3'=> 18261.75,
    'F:4'=> 13847.5,
    'F:5'=> 19000.5,
    'F:6'=> 16460.25,
    'F:7'=> 15476,
    'F:8'=> 119449.25,
    'F:9'=> 51110.5,
    'F:10' => 50230.75,
    'F:11' => 47440.5,
    'F:12' => 48227.5,
    'G:1' => 17465.75,
    'G:2' => 14540.75,
    'G:3' => 16238.25,
    'G:4' => 16240.5,
    'G:5' => 16129.5,
    'G:6' => 16730.75,
    'G:7' => 13030.25,
    'G:8' => 121803,
    'G:9' => 34738.5,
    'G:10' => 33814,
    'G:11' => 35460.75,
    'G:12' => 35908.25,
    'H:1' => 18703.75,
    'H:2' => 16756,
    'H:3' => 14930.25,
    'H:4' => 17115,
    'H:5' => 17878,
    'H:6' => 16665,
    'H:7' => 13873.75,
    'H:8' => 117552.5,
    'H:9' => 28100.5,
    'H:10' => 26997,
    'H:11' => 25164,
    'H:12' => 28076.5,
  },
};

my $EXPECTED_DATA_2 = {
  'std1' => 27722.7,
  'std2' => 13211.3,
  'std3' => 804.4,
  'std4' => 3105.4,
  'std5' => 2103.2,
  'std6' => 1478.4,
  'std7' => 792.3,
  'std8' => 1195.0,
  'average1' => 1089982,
  'average2' => 536739.25,
  'average3' => 271642.875,
  'average4' => 138613.25,
  'average5' => 79907.5,
  'average6' => 49252.3125,
  'average7' => 34980.375,
  'average8' => 27084.5,
  'cv1' => 2.5,
  'cv2' => 2.5,
  'cv3' => 0.3,
  'cv4' => 2.2,
  'cv5' => 2.6,
  'cv6' => 3.0,
  'cv7' => 2.3,
  'cv8' => 4.4,
  'known_concentration1' => 10,
  'known_concentration2' => 5,
  'known_concentration3' => 2.5,
  'known_concentration4' => 1.25,
  'known_concentration5' => 0.625,
  'known_concentration6' => 0.3125,
  'known_concentration7' => 0.15625,
  'known_concentration8' => 0.078125,
};

my $EXPECTED_DATA_3 = {
  'slope' => 101332.7912,
  'intercept' => 18679.62839,
};

{
  my $parser = wtsi_clarity::file_parsing::dtx_parser->new();

  my $standard_doc = $parser->parse($testdata_path.$standard_name);
  my $plateA_doc = $parser->parse($testdata_path.$plateA_name);
  my $plateB_doc = $parser->parse($testdata_path.$plateB_name);

  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_doc => $standard_doc,
    plateA_doc   => $plateA_doc,
    plateB_doc   => $plateB_doc);

  isa_ok( $calculator, 'wtsi_clarity::file_parsing::dtx_concentration_calculator');

  my $standard_fluorescences = $calculator->cvs();
}

{ #_get_standard_intermediate_coefficients
  my $res = wtsi_clarity::file_parsing::dtx_concentration_calculator::_get_standard_intermediate_coefficients($TEST_DATA_2);

  while (my ($well, $exp) = each %{$EXPECTED_DATA_2} ) {
    my $expected = $EXPECTED_DATA_2->{$well};

    # print "$well ==> ".$res->{$well} ." -- $expected \n";
    cmp_ok(abs($res->{$well} - $expected), '<', 0.1 , "_get_standard_intermediate_coefficients( $well ) should give the correct intermediate coefficients.");
  }
}

{ #_get_standard_coefficients
  my $res = wtsi_clarity::file_parsing::dtx_concentration_calculator::_get_standard_coefficients($TEST_DATA_2);


  while (my ($well, $exp) = each %{$EXPECTED_DATA_3} ) {
    my $expected = $EXPECTED_DATA_3->{$well};
    cmp_ok(abs($res->{$well} - $expected), '<', 0.1 , "_get_standard_coefficients( $well ) should give the correct standard coefficients.");
  }
}

{ #get_analysis_results
  my $parser = wtsi_clarity::file_parsing::dtx_parser->new();

  my $standard_doc = $parser->parse($testdata_path.$standard_name);
  my $plateA_doc = $parser->parse($testdata_path.$plateA_name);
  my $plateB_doc = $parser->parse($testdata_path.$plateB_name);

  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_doc => $standard_doc,
    plateA_doc   => $plateA_doc,
    plateB_doc   => $plateB_doc);

  isa_ok( $calculator, 'wtsi_clarity::file_parsing::dtx_concentration_calculator');

  my $res = $calculator->get_analysis_results();

  compare_analysis_results($EXPECTED_DATA_1, $res);
}

sub compare_analysis_results {
  my ($expected_data, $result) = @_;

  foreach my $key (qw{concentration cv}) {
    while (my ($well, $exp) = each %{$expected_data} ) {
      my $expected  = $expected_data->{$well}->{$key};
      cmp_ok(abs($result->{$well}->{$key} - $expected), '<', 0.001 , "get_analysis_results( $well ) should give the correct $key.");
    }
  }

  while (my ($well, $exp) = each %{$expected_data} ) {
    my $expected  = $expected_data->{$well}->{'status'};
    cmp_ok($result->{$well}->{'status'}, 'eq', $expected , "get_analysis_results( $well ) should give the correct status.");
  }
}

my $EXPECTED_DATA_4 = {
          'D:5' => {
                   'plateA_fluorescence' => '1204089.5',
                   'cv' => '0.980047964054111',
                   'concentration' => '386.739842239998',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1180717.25'
                 },
          'E:4' => {
                   'plateA_fluorescence' => '347188',
                   'cv' => '0.403227396943934',
                   'concentration' => '109.854329103131',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '349999.25'
                 },
          'B:10' => {
                    'plateA_fluorescence' => '250808',
                    'cv' => '0.47030052903229',
                    'concentration' => '78.1560949789364',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '253178.25'
                  },
          'E:11' => {
                    'plateA_fluorescence' => '207969.5',
                    'cv' => '2.51153115784778',
                    'concentration' => '62.0383564613611',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '197779'
                  },
          'A:8' => {
                   'plateA_fluorescence' => '742433.75',
                   'cv' => '5.36957329320653',
                   'concentration' => '226.673243082843',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '666765.75'
                 },
          'H:10' => {
                    'plateA_fluorescence' => '596207.5',
                    'cv' => '0.1984664620973',
                    'concentration' => '191.494742982795',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '598578.75'
                  },
          'C:2' => {
                   'plateA_fluorescence' => '516932.5',
                   'cv' => '0.692744148607644',
                   'concentration' => '166.275868372652',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '524144.5'
                 },
          'E:9' => {
                   'plateA_fluorescence' => '34151.25',
                   'cv' => '7.8274665814182',
                   'concentration' => '5.86054122428066',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '29193'
                 },
          'C:7' => {
                   'plateA_fluorescence' => '383878.75',
                   'cv' => '1.19938720761291',
                   'concentration' => '119.939795274881',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '374779.5'
                 },
          'E:8' => {
                   'plateA_fluorescence' => '92863.5',
                   'cv' => '1.77631048347112',
                   'concentration' => '26.4907838530837',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '96222.25'
                 },
          'H:4' => {
                   'plateA_fluorescence' => '777147.5',
                   'cv' => '0.135007392879545',
                   'concentration' => '250.823620378098',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '779248.75'
                 },
          'H:5' => {
                   'plateA_fluorescence' => '360187.5',
                   'cv' => '1.41616542240855',
                   'concentration' => '115.356536542994',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '370535.75'
                 },
          'B:2' => {
                   'plateA_fluorescence' => '259900.75',
                   'cv' => '3.29089996599935',
                   'concentration' => '83.6529701865179',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '277589'
                 },
          'F:6' => {
                   'plateA_fluorescence' => '84327',
                   'cv' => '2.90557196202377',
                   'concentration' => '22.3572784055632',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '79565'
                 },
          'A:12' => {
                    'plateA_fluorescence' => '102189.5',
                    'cv' => '0.36453071088973',
                    'concentration' => '29.1226096385932',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '102937.25'
                  },
          'C:4' => {
                   'plateA_fluorescence' => '46968.5',
                   'cv' => '9.67126174430042',
                   'concentration' => '9.52074953105264',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '38684.75'
                 },
          'F:7' => {
                   'plateA_fluorescence' => '276623.5',
                   'cv' => '2.48035274717817',
                   'concentration' => '88.5469339917366',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '290695'
                 },
          'B:8' => {
                   'plateA_fluorescence' => '292492.75',
                   'cv' => '0.719883542385387',
                   'concentration' => '92.1414738071022',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '296734.5'
                 },
          'E:7' => {
                   'plateA_fluorescence' => '39379',
                   'cv' => '5.86819907920825',
                   'concentration' => '7.67321307982298',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '35013.5'
                 },
          'F:1' => {
                   'plateA_fluorescence' => '127731',
                   'cv' => '2.80884971778697',
                   'concentration' => '36.2359305537543',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '120751.5'
                 },
          'G:6' => {
                   'plateA_fluorescence' => '306719.5',
                   'cv' => '0.511372759774413',
                   'concentration' => '95.6018054376572',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '303598.5'
                 },
          'E:12' => {
                    'plateA_fluorescence' => '92384.25',
                    'cv' => '11.1814136527335',
                    'concentration' => '22.7337340046437',
                    'status' => 'Failed',
                    'plateB_fluorescence' => '73802.25'
                  },
          'C:11' => {
                    'plateA_fluorescence' => '138707.75',
                    'cv' => '0.517961055995594',
                    'concentration' => '40.7483936478106',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '137278.25'
                  },
          'G:5' => {
                   'plateA_fluorescence' => '131126.75',
                   'cv' => '57.9309860821197',
                   'concentration' => '97.7463062098002',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '492262'
                 },
          'B:12' => {
                    'plateA_fluorescence' => '520756',
                    'cv' => '0.120424706268486',
                    'concentration' => '166.553267502809',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '522011.75'
                  },
          'B:6' => {
                   'plateA_fluorescence' => '3564537.5',
                   'cv' => '7.54234388101588',
                   'concentration' => '1083.09324208822',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3064549'
                 },
          'F:11' => {
                    'plateA_fluorescence' => '160815.75',
                    'cv' => '1.14277627968773',
                    'concentration' => '47.6411652323707',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '157181.75'
                  },
          'D:9' => {
                   'plateA_fluorescence' => '22954',
                   'cv' => '11.4697973132933',
                   'concentration' => '2.22477915166123',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '18230.25'
                 },
          'C:9' => {
                   'plateA_fluorescence' => '25491.75',
                   'cv' => '6.1509392713815',
                   'concentration' => '3.3478293045078',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '22537.5'
                 },
          'A:2' => {
                   'plateA_fluorescence' => '145591.75',
                   'cv' => '0.316833784648881',
                   'concentration' => '43.3936730655382',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '146517.25'
                 },
          'D:12' => {
                    'plateA_fluorescence' => '1031241.25',
                    'cv' => '1.1702864884771',
                    'concentration' => '329.942216525939',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1007383.5'
                  },
          'H:3' => {
                   'plateA_fluorescence' => '177292.25',
                   'cv' => '0.654881449993258',
                   'concentration' => '53.2654397743108',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '174985.25'
                 },
          'F:9' => {
                   'plateA_fluorescence' => '17478.25',
                   'cv' => '3.81834815686113',
                   'concentration' => '1.43068671341764',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '18866'
                 },
          'B:4' => {
                   'plateA_fluorescence' => '174974.5',
                   'cv' => '0.517455690058184',
                   'concentration' => '53.182051864861',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '176794.75'
                 },
          'F:8' => {
                   'plateA_fluorescence' => '112724',
                   'cv' => '3.35701236214931',
                   'concentration' => '31.2552974653739',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '105401.5'
                 },
          'H:9' => {
                   'plateA_fluorescence' => '756005',
                   'cv' => '1.51809504434505',
                   'concentration' => '239.831551666962',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '733394.5'
                 },
          'A:3' => {
                   'plateA_fluorescence' => '212705.5',
                   'cv' => '0.185182904045692',
                   'concentration' => '65.3938482018256',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '213494.75'
                 },
          'D:10' => {
                    'plateA_fluorescence' => '1507943.5',
                    'cv' => '0.307048276451376',
                    'concentration' => '491.804342360992',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1517232.25'
                  },
          'D:7' => {
                   'plateA_fluorescence' => '90140.75',
                   'cv' => '0.998039215686274',
                   'concentration' => '24.7539937646257',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '88359.25'
                 },
          'C:10' => {
                    'plateA_fluorescence' => '69679',
                    'cv' => '3.64291172637165',
                    'concentration' => '17.5283678341799',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '64780.75'
                  },
          'C:6' => {
                   'plateA_fluorescence' => '64759.5',
                   'cv' => '1.07596949436262',
                   'concentration' => '16.4915357756096',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '63380.75'
                 },
          'G:11' => {
                    'plateA_fluorescence' => '158730.75',
                    'cv' => '3.57074513163051',
                    'concentration' => '49.4819338503198',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '170486.25'
                  },
          'B:1' => {
                   'plateA_fluorescence' => '74645.25',
                   'cv' => '7.31908072087356',
                   'concentration' => '18.2911641706477',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '64463.75'
                 },
          'F:2' => {
                   'plateA_fluorescence' => '142115',
                   'cv' => '0.92865228215623',
                   'concentration' => '42.5380958873707',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '144779.25'
                 },
          'A:4' => {
                   'plateA_fluorescence' => '505415',
                   'cv' => '0.230290801010404',
                   'concentration' => '160.932233317409',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '503092.5'
                 },
          'B:9' => {
                   'plateA_fluorescence' => '67699.75',
                   'cv' => '4.50858976560736',
                   'concentration' => '16.7241851717727',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '61858.5'
                 },
          'G:9' => {
                   'plateA_fluorescence' => '32969',
                   'cv' => '15.2989005704793',
                   'concentration' => '4.85061643014669',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '24219.75'
                 },
          'C:8' => {
                   'plateA_fluorescence' => '205231',
                   'cv' => '2.59568620810106',
                   'concentration' => '61.1078819282229',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '194846.25'
                 },
          'A:7' => {
                   'plateA_fluorescence' => '859624.5',
                   'cv' => '0.194882583826028',
                   'concentration' => '276.994011330306',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '856280.5'
                 },
          'H:8' => {
                   'plateA_fluorescence' => '17120.25',
                   'cv' => '11.0091668760486',
                   'concentration' => '0.528390977029073',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '13724.5'
                 },
          'B:3' => {
                   'plateA_fluorescence' => '47983',
                   'cv' => '1.54729309683478',
                   'concentration' => '10.972839432845',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '46520.75'
                 },
          'F:3' => {
                   'plateA_fluorescence' => '3400577.5',
                   'cv' => '6.67284950432801',
                   'concentration' => '1041.52262599769',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '2975135.75'
                 },
          'E:5' => {
                   'plateA_fluorescence' => '39325.25',
                   'cv' => '8.7647363872083',
                   'concentration' => '7.33195021380094',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '32987.25'
                 },
          'G:10' => {
                    'plateA_fluorescence' => '222526',
                    'cv' => '1.85613986303666',
                    'concentration' => '67.156191988064',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '214415.75'
                  },
          'C:1' => {
                   'plateA_fluorescence' => '297292',
                   'cv' => '0.0780608639463842',
                   'concentration' => '93.0965586430785',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '297756.5'
                 },
          'A:9' => {
                   'plateA_fluorescence' => '289291.5',
                   'cv' => '0.998890218958097',
                   'concentration' => '89.4562436644341',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '283569.25'
                 },
          'E:6' => {
                   'plateA_fluorescence' => '307942.75',
                   'cv' => '1.50524290228135',
                   'concentration' => '98.0595133305868',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '317355'
                 },
          'F:5' => {
                   'plateA_fluorescence' => '357778.25',
                   'cv' => '0.776076479552029',
                   'concentration' => '111.964047313929',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '352267.75'
                 },
          'H:11' => {
                    'plateA_fluorescence' => '115248.75',
                    'cv' => '2.52250348880524',
                    'concentration' => '32.3546807103245',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '109577.5'
                  },
          'B:5' => {
                   'plateA_fluorescence' => '64701',
                   'cv' => '6.23004112861517',
                   'concentration' => '15.4534321847259',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '57112'
                 },
          'H:1' => {
                   'plateA_fluorescence' => '209175.25',
                   'cv' => '1.45897544309254',
                   'concentration' => '65.1221914756641',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '215369.25'
                 },
          'G:4' => {
                   'plateA_fluorescence' => '188986.75',
                   'cv' => '1.329235198829',
                   'concentration' => '56.6678551588534',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '184028.5'
                 },
          'D:8' => {
                   'plateA_fluorescence' => '135465.25',
                   'cv' => '0.751060285386424',
                   'concentration' => '40.2553262304487',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '137515.5'
                 },
          'G:7' => {
                   'plateA_fluorescence' => '419896.5',
                   'cv' => '0.79815155577094',
                   'concentration' => '134.360038154197',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '426653.25'
                 },
          'F:4' => {
                   'plateA_fluorescence' => '255105',
                   'cv' => '1.14991855490291',
                   'concentration' => '80.1510061269951',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '261040.25'
                 },
          'D:2' => {
                   'plateA_fluorescence' => '63807.75',
                   'cv' => '4.07337946171858',
                   'concentration' => '17.2945289400463',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '69226.75'
                 },
          'E:10' => {
                    'plateA_fluorescence' => '270503.5',
                    'cv' => '2.51326910584561',
                    'concentration' => '86.5183887631325',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '284451'
                  },
          'C:12' => {
                    'plateA_fluorescence' => '361548.75',
                    'cv' => '0.88468706983432',
                    'concentration' => '115.164330077828',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '368003'
                  },
          'A:11' => {
                    'plateA_fluorescence' => '1707305',
                    'cv' => '4.0168493033426',
                    'concentration' => '534.063718793626',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '1575442'
                  },
          'B:11' => {
                    'plateA_fluorescence' => '229526.75',
                    'cv' => '1.42766553540496',
                    'concentration' => '69.7239079346801',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '223065.25'
                  },
          'G:8' => {
                   'plateA_fluorescence' => '464408.75',
                   'cv' => '0.126371952899633',
                   'concentration' => '148.050421485676',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '465584'
                 },
          'H:2' => {
                   'plateA_fluorescence' => '1853187.75',
                   'cv' => '1.49199476052055',
                   'concentration' => '594.628443563117',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '1798701.75'
                 },
          'H:7' => {
                   'plateA_fluorescence' => '621305.25',
                   'cv' => '0.412779370408275',
                   'concentration' => '200.186240584622',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '626455.75'
                 },
          'A:5' => {
                   'plateA_fluorescence' => '64903',
                   'cv' => '4.10715001804547',
                   'concentration' => '15.9246374497333',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '59782'
                 },
          'E:2' => {
                   'plateA_fluorescence' => '74147',
                   'cv' => '10.3412868338471',
                   'concentration' => '17.5178674383023',
                   'status' => 'Failed',
                   'plateB_fluorescence' => '60248.75'
                 },
          'G:12' => {
                    'plateA_fluorescence' => '453545.25',
                    'cv' => '0.0219155152751141',
                    'concentration' => '144.260270779919',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '453346.5'
                  },
          'G:3' => {
                   'plateA_fluorescence' => '552589',
                   'cv' => '2.50568551723651',
                   'concentration' => '181.453042132925',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '580993'
                 },
          'E:3' => {
                   'plateA_fluorescence' => '105363.25',
                   'cv' => '1.02694527811829',
                   'concentration' => '30.400089441749',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '107549.75'
                 },
          'B:7' => {
                   'plateA_fluorescence' => '117362.75',
                   'cv' => '3.53032244405581',
                   'concentration' => '32.6656318866842',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '109358.75'
                 },
          'G:1' => {
                   'plateA_fluorescence' => '453678',
                   'cv' => '2.28662385916814',
                   'concentration' => '141.008470448746',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '433394'
                 },
          'H:6' => {
                   'plateA_fluorescence' => '225660',
                   'cv' => '2.1816502295759',
                   'concentration' => '67.9342467122914',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '216024'
                 },
          'H:12' => {
                    'plateA_fluorescence' => '98455',
                    'cv' => '2.04586648424757',
                    'concentration' => '27.1267961127638',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '94507.25'
                  },
          'G:2' => {
                   'plateA_fluorescence' => '251245',
                   'cv' => '3.13408437237348',
                   'concentration' => '80.578035898408',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '267503'
                 },
          'A:1' => {
                   'plateA_fluorescence' => '19366.25',
                   'cv' => '0.947379394823946',
                   'concentration' => '1.76288478456097',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '19002.75'
                 },
          'A:10' => {
                    'plateA_fluorescence' => '245737.75',
                    'cv' => '1.46685233720881',
                    'concentration' => '74.9377646596231',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '238632.75'
                  },
          'A:6' => {
                   'plateA_fluorescence' => '28927.75',
                   'cv' => '0.57868530603302',
                   'concentration' => '5.01525935613376',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '29264.5'
                 },
          'D:11' => {
                    'plateA_fluorescence' => '30596.25',
                    'cv' => '3.94071935114018',
                    'concentration' => '5.12686707950467',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '28276.25'
                  },
          'E:1' => {
                   'plateA_fluorescence' => '160316.25',
                   'cv' => '0.228477277129635',
                   'concentration' => '48.1939536512864',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '161050.5'
                 },
          'F:12' => {
                    'plateA_fluorescence' => '198411.75',
                    'cv' => '0.0241232945995942',
                    'concentration' => '60.5897530191375',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '198507.5'
                  },
          'D:1' => {
                   'plateA_fluorescence' => '195754.75',
                   'cv' => '1.79475529225631',
                   'concentration' => '58.5696573278411',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '188852'
                 },
          'C:3' => {
                   'plateA_fluorescence' => '497369.25',
                   'cv' => '0.419175299065021',
                   'concentration' => '159.360168189281',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '501556.5'
                 },
          'D:6' => {
                   'plateA_fluorescence' => '3252503',
                   'cv' => '2.77428701885326',
                   'concentration' => '1033.92571263176',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3076907'
                 },
          'C:5' => {
                   'plateA_fluorescence' => '3587098.25',
                   'cv' => '3.60211839878604',
                   'concentration' => '1131.60375849326',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '3337660.25'
                 },
          'D:4' => {
                   'plateA_fluorescence' => '104783.25',
                   'cv' => '0.701267256268168',
                   'concentration' => '30.0938552400999',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '106263.25'
                 },
          'F:10' => {
                    'plateA_fluorescence' => '386125.75',
                    'cv' => '0.722069579263584',
                    'concentration' => '123.091554725017',
                    'status' => 'Passed',
                    'plateB_fluorescence' => '391742.5'
                  },
          'D:3' => {
                   'plateA_fluorescence' => '266569.5',
                   'cv' => '1.0531473320546',
                   'concentration' => '83.8701561090644',
                   'status' => 'Passed',
                   'plateB_fluorescence' => '272244'
                 }
        };

{
  my $parser = wtsi_clarity::file_parsing::dtx_parser->new();

  my $standard_doc = $parser->parse($testdata_path.$standard_name_2);
  my $plateA_doc   = $parser->parse($testdata_path.$plateA_name_2);
  my $plateB_doc   = $parser->parse($testdata_path.$plateB_name_2);

  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_doc => $standard_doc,
    plateA_doc   => $plateA_doc,
    plateB_doc   => $plateB_doc
  );

  my $results = $calculator->get_analysis_results();

  compare_analysis_results($EXPECTED_DATA_4, $results);
}

1;
