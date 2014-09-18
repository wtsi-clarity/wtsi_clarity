use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Cwd;

use_ok('wtsi_clarity::file_parsing::volume_checker');

{
  my $vc = wtsi_clarity::file_parsing::volume_checker->new();
  isa_ok($vc, 'wtsi_clarity::file_parsing::volume_checker');

  $vc = wtsi_clarity::file_parsing::volume_checker->new(file_path => '/made/up/path');
  throws_ok { $vc->parse }
            qr/File can not be found at \/made\/up\/path/,
            'error when file can not be found';

}

{
  my $vc = wtsi_clarity::file_parsing::volume_checker->new(
    file_path => getcwd . '/t/data/file_parsing/volume_checker/test_2.CSV' # Must be better way
  );
  throws_ok { $vc->parse }
            qr/Volume already set for well A:1/,
            'error if volume for well is duplicated in file';  
}

{
  my %res = (
    'A:1' => '7.1518',
    'B:1' => '4.4186',
    'C:1' => '6.4629',
    'D:1' => '6.1717',
    'E:1' => '6.4726',
    'F:1' => '6.1302',
    'G:1' => '6.4288',
    'H:1' => '7.3359',
    'A:2' => '6.6158',
    'B:2' => '5.6286',
    'C:2' => '5.8675',
    'D:2' => '5.6229',
    'E:2' => '5.7624',
    'F:2' => '5.9958',
    'G:2' => '6.0746',
    'H:2' => '6.9296',
    'A:3' => '6.6714',
    'B:3' => '5.7707',
    'C:3' => '5.8374',
    'D:3' => '4.8693',
    'E:3' => '5.4081',
    'F:3' => '5.8455',
    'G:3' => '6.3478',
    'H:3' => '5.4774',
    'A:4' => '5.9747',
    'B:4' => '5.5731',
    'C:4' => '5.5731',
    'D:4' => '5.0421',
    'E:4' => '5.2061',
    'F:4' => '6.1041',
    'G:4' => '6.6072',
    'H:4' => '7.7828',
    'A:5' => '6.6590',
    'B:5' => '3.0544',
    'C:5' => '5.3082',
    'D:5' => '5.9937',
    'E:5' => '5.8872',
    'F:5' => '5.7256',
    'G:5' => '6.4799',
    'H:5' => '6.8934',
    'A:6' => '4.9650',
    'B:6' => '4.7598',
    'C:6' => '5.2487',
    'D:6' => '4.7619',
    'E:6' => '5.3702',
    'F:6' => '6.2409',
    'G:6' => '6.5338',
    'H:6' => '8.0221',
    'A:7' => '7.1890',
    'B:7' => '5.3836',
    'C:7' => '5.3791',
    'D:7' => '6.1421',
    'E:7' => '4.9510',
    'F:7' => '8.0302',
    'G:7' => '3.9723',
    'H:7' => '6.9410',
    'A:8' => '6.8618',
    'B:8' => '6.3382',
    'C:8' => '6.1765',
    'D:8' => '5.5663',
    'E:8' => '5.6059',
    'F:8' => '6.8668',
    'G:8' => '4.7076',
    'H:8' => '6.1337',
    'A:9' => '8.1745',
    'B:9' => '6.7048',
    'C:9' => '6.9599',
    'D:9' => '6.1019',
    'E:9' => '6.1729',
    'F:9' => '7.0219',
    'G:9' => '8.2457',
    'H:9' => '6.4252',
    'A:10' => '6.7981',
    'B:10' => '5.2027',
    'C:10' => '5.7233',
    'D:10' => '6.3333',
    'E:10' => '5.0486',
    'F:10' => '7.1736',
    'G:10' => '7.7402',
    'H:10' => '5.3237',
    'A:11' => '6.4617',
    'B:11' => '5.1540',
    'C:11' => '5.5980',
    'D:11' => '5.9889',
    'E:11' => '7.3217',
    'F:11' => '7.0612',
    'G:11' => '4.5282',
    'H:11' => '8.1308',
    'A:12' => '5.9572',
    'B:12' => '7.2379',
    'C:12' => '6.3888',
    'D:12' => '5.2708',
    'E:12' => '8.6797',
    'F:12' => '5.8536',
    'G:12' => '8.5784',
    'H:12' => '8.0913'
  );

  my $vc = wtsi_clarity::file_parsing::volume_checker->new(
    file_path => getcwd . '/t/data/file_parsing/volume_checker/test_1.CSV' # Must be better way
  );
  
  my $parsed_file = $vc->parse();

  is_deeply ($parsed_file, \%res, 'The file was parsed correctly');

}

1;
