use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Cwd;

use_ok('wtsi_clarity::file_parsing::volume_check');

{
  my $vc = wtsi_clarity::file_parsing::volume_check->new();
  isa_ok($vc, 'wtsi_clarity::file_parsing::volume_check');

  $vc = wtsi_clarity::file_parsing::volume_check->new(file_path => '/made/up/path');
  throws_ok { $vc->parse }
            qr/File can not be found at \/made\/up\/path/,
            'error when file can not be found';

}

{
  my $vc = wtsi_clarity::file_parsing::volume_check->new(
    file_path => getcwd . '/t/data/volume_check/test_2.CSV' # Must be better way
  );
  throws_ok { $vc->parse }
            qr/Volume already set for well A01/,
            'error if volume for well is duplicated in file';  
}

{
  my %res = (
    A01 => 7.1518,
    B01 => 4.4186,
    C01 => 6.4629,
    D01 => 6.1717,
    E01 => 6.4726,
    F01 => 6.1302,
    G01 => 6.4288,
    H01 => 7.3359,
    A02 => 6.6158,
    B02 => 5.6286,
    C02 => 5.8675,
    D02 => 5.6229,
    E02 => 5.7624,
    F02 => 5.9958,
    G02 => 6.0746,
    H02 => 6.9296,
    A03 => 6.6714,
    B03 => 5.7707,
    C03 => 5.8374,
    D03 => 4.8693,
    E03 => 5.4081,
    F03 => 5.8455,
    G03 => 6.3478,
    H03 => 5.4774,
    A04 => 5.9747,
    B04 => 5.5731,
    C04 => 5.5731,
    D04 => 5.0421,
    E04 => 5.2061,
    F04 => 6.1041,
    G04 => 6.6072,
    H04 => 7.7828,
    A05 => 6.6590,
    B05 => 3.0544,
    C05 => 5.3082,
    D05 => 5.9937,
    E05 => 5.8872,
    F05 => 5.7256,
    G05 => 6.4799,
    H05 => 6.8934,
    A06 => 4.9650,
    B06 => 4.7598,
    C06 => 5.2487,
    D06 => 4.7619,
    E06 => 5.3702,
    F06 => 6.2409,
    G06 => 6.5338,
    H06 => 8.0221,
    A07 => 7.1890,
    B07 => 5.3836,
    C07 => 5.3791,
    D07 => 6.1421,
    E07 => 4.9510,
    F07 => 8.0302,
    G07 => 3.9723,
    H07 => 6.9410,
    A08 => 6.8618,
    B08 => 6.3382,
    C08 => 6.1765,
    D08 => 5.5663,
    E08 => 5.6059,
    F08 => 6.8668,
    G08 => 4.7076,
    H08 => 6.1337,
    A09 => 8.1745,
    B09 => 6.7048,
    C09 => 6.9599,
    D09 => 6.1019,
    E09 => 6.1729,
    F09 => 7.0219,
    G09 => 8.2457,
    H09 => 6.4252,
    A10 => 6.7981,
    B10 => 5.2027,
    C10 => 5.7233,
    D10 => 6.3333,
    E10 => 5.0486,
    F10 => 7.1736,
    G10 => 7.7402,
    H10 => 5.3237,
    A11 => 6.4617,
    B11 => 5.1540,
    C11 => 5.5980,
    D11 => 5.9889,
    E11 => 7.3217,
    F11 => 7.0612,
    G11 => 4.5282,
    H11 => 8.1308,
    A12 => 5.9572,
    B12 => 7.2379,
    C12 => 6.3888,
    D12 => 5.2708,
    E12 => 8.6797,
    F12 => 5.8536,
    G12 => 8.5784,
    H12 => 8.0913
  );

  my $vc = wtsi_clarity::file_parsing::volume_check->new(
    file_path => getcwd . '/t/data/volume_check/test_1.CSV' # Must be better way
  );
  is (%res, $vc->parse, 'File gets parsed correctly');
}

1;