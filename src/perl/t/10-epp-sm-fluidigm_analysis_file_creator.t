use strict;
use warnings;

use Test::More tests => 9;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/fluidigm_analysis_file_creator';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::sm::fluidigm_analysis_file_creator');

{
  my $file_creator = wtsi_clarity::epp::sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-26663',
    filename    => '123456789.csv',
  );

  isa_ok($file_creator, 'wtsi_clarity::epp::sm::fluidigm_analysis_file_creator', 'Module is initialized correctly');
  can_ok($file_creator, qw/run process_url filename/);
}

{
  my $file_creator = wtsi_clarity::epp::sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-26663',
    filename    => '123456789.csv',
  );

  isa_ok($file_creator->_sta_plate_creation_process, 'wtsi_clarity::clarity::process', 'Finds the STA Plate Creation process');
  is($file_creator->_sta_plate_creation_process->findvalue('/prc:process/type'), 'Fluidigm STA Plate Creation (SM)', 'Finds the STA Plate Creation process');
}

{
  my $file_creator = wtsi_clarity::epp::sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-26663',
    filename    => '123456789.csv',
  );

  is($file_creator->_sample_plate, '5260273787793', 'Extracts the input plate limsid');
  is($file_creator->_barcode, '123456789', 'Extracts the input plate barcode');
}

{
  my $file_creator = wtsi_clarity::epp::sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-26663',
    filename    => '123456789.csv',
  );

  my %container_size = (
    'x_dimension' => '12',
    'y_dimension' => '8',
  );

  is_deeply($file_creator->_container_size, \%container_size, 'Finds the container size');
}

{
  my $file_creator = wtsi_clarity::epp::sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://testserver.com:1234/here/processes/24-26663',
    filename    => '123456789.csv',
  );

  my $samples = [
          {
            'sample_name' => 'DEA103A624',
            'well_location' => 'A01'
          },
          {
            'sample_name' => 'DEA103A570',
            'well_location' => 'B01'
          },
          {
            'sample_name' => 'DEA103A605',
            'well_location' => 'C01'
          },
          {
            'sample_name' => 'DEA103A538',
            'well_location' => 'D01'
          },
          {
            'sample_name' => 'DEA103A568',
            'well_location' => 'E01'
          },
          {
            'sample_name' => 'DEA103A602',
            'well_location' => 'F01'
          },
          {
            'sample_name' => 'DEA103A608',
            'well_location' => 'G01'
          },
          {
            'sample_name' => 'DEA103A603',
            'well_location' => 'H01'
          },
          {
            'sample_name' => 'DEA103A618',
            'well_location' => 'A02'
          },
          {
            'sample_name' => 'DEA103A597',
            'well_location' => 'B02'
          },
          {
            'sample_name' => 'DEA103A534',
            'well_location' => 'C02'
          },
          {
            'sample_name' => 'DEA103A607',
            'well_location' => 'D02'
          },
          {
            'sample_name' => 'DEA103A537',
            'well_location' => 'E02'
          },
          {
            'sample_name' => 'DEA103A579',
            'well_location' => 'F02'
          },
          {
            'sample_name' => 'DEA103A574',
            'well_location' => 'G02'
          },
          {
            'sample_name' => 'DEA103A561',
            'well_location' => 'H02'
          },
          {
            'sample_name' => 'DEA103A621',
            'well_location' => 'A03'
          },
          {
            'sample_name' => 'DEA103A578',
            'well_location' => 'B03'
          },
          {
            'sample_name' => 'DEA103A550',
            'well_location' => 'C03'
          },
          {
            'sample_name' => 'DEA103A559',
            'well_location' => 'D03'
          },
          {
            'sample_name' => 'DEA103A593',
            'well_location' => 'E03'
          },
          {
            'sample_name' => 'DEA103A536',
            'well_location' => 'F03'
          },
          {
            'sample_name' => 'DEA103A617',
            'well_location' => 'G03'
          },
          {
            'sample_name' => 'DEA103A611',
            'well_location' => 'H03'
          },
          {
            'sample_name' => 'DEA103A616',
            'well_location' => 'A04'
          },
          {
            'sample_name' => 'DEA103A555',
            'well_location' => 'B04'
          },
          {
            'sample_name' => 'DEA103A581',
            'well_location' => 'C04'
          },
          {
            'sample_name' => 'DEA103A576',
            'well_location' => 'D04'
          },
          {
            'sample_name' => 'DEA103A592',
            'well_location' => 'E04'
          },
          {
            'sample_name' => 'DEA103A594',
            'well_location' => 'F04'
          },
          {
            'sample_name' => 'DEA103A551',
            'well_location' => 'G04'
          },
          {
            'sample_name' => 'DEA103A544',
            'well_location' => 'H04'
          },
          {
            'sample_name' => 'DEA103A623',
            'well_location' => 'A05'
          },
          {
            'sample_name' => 'DEA103A595',
            'well_location' => 'B05'
          },
          {
            'sample_name' => 'DEA103A610',
            'well_location' => 'C05'
          },
          {
            'sample_name' => 'DEA103A556',
            'well_location' => 'D05'
          },
          {
            'sample_name' => 'DEA103A571',
            'well_location' => 'E05'
          },
          {
            'sample_name' => 'DEA103A566',
            'well_location' => 'F05'
          },
          {
            'sample_name' => 'DEA103A547',
            'well_location' => 'G05'
          },
          {
            'sample_name' => 'DEA103A620',
            'well_location' => 'H05'
          },
          {
            'sample_name' => 'DEA103A590',
            'well_location' => 'A06'
          },
          {
            'sample_name' => 'DEA103A599',
            'well_location' => 'B06'
          },
          {
            'sample_name' => 'DEA103A539',
            'well_location' => 'C06'
          },
          {
            'sample_name' => 'DEA103A560',
            'well_location' => 'D06'
          },
          {
            'sample_name' => 'DEA103A535',
            'well_location' => 'E06'
          },
          {
            'sample_name' => 'DEA103A565',
            'well_location' => 'F06'
          },
          {
            'sample_name' => 'DEA103A545',
            'well_location' => 'G06'
          },
          {
            'sample_name' => 'DEA103A615',
            'well_location' => 'H06'
          },
          {
            'sample_name' => 'DEA103A613',
            'well_location' => 'A07'
          },
          {
            'sample_name' => 'DEA103A582',
            'well_location' => 'B07'
          },
          {
            'sample_name' => 'DEA103A604',
            'well_location' => 'C07'
          },
          {
            'sample_name' => 'DEA103A562',
            'well_location' => 'D07'
          },
          {
            'sample_name' => 'DEA103A612',
            'well_location' => 'E07'
          },
          {
            'sample_name' => 'DEA103A557',
            'well_location' => 'F07'
          },
          {
            'sample_name' => 'DEA103A596',
            'well_location' => 'G07'
          },
          {
            'sample_name' => 'DEA103A586',
            'well_location' => 'H07'
          },
          {
            'sample_name' => 'DEA103A548',
            'well_location' => 'A08'
          },
          {
            'sample_name' => 'DEA103A541',
            'well_location' => 'B08'
          },
          {
            'sample_name' => 'DEA103A573',
            'well_location' => 'C08'
          },
          {
            'sample_name' => 'DEA103A609',
            'well_location' => 'D08'
          },
          {
            'sample_name' => 'DEA103A575',
            'well_location' => 'E08'
          },
          {
            'sample_name' => 'DEA103A543',
            'well_location' => 'F08'
          },
          {
            'sample_name' => 'DEA103A540',
            'well_location' => 'G08'
          },
          {
            'sample_name' => 'DEA103A583',
            'well_location' => 'H08'
          },
          {
            'sample_name' => 'DEA103A542',
            'well_location' => 'A09'
          },
          {
            'sample_name' => 'DEA103A587',
            'well_location' => 'B09'
          },
          {
            'sample_name' => 'DEA103A564',
            'well_location' => 'C09'
          },
          {
            'sample_name' => 'DEA103A569',
            'well_location' => 'D09'
          },
          {
            'sample_name' => 'DEA103A588',
            'well_location' => 'E09'
          },
          {
            'sample_name' => 'DEA103A558',
            'well_location' => 'F09'
          },
          {
            'sample_name' => 'DEA103A546',
            'well_location' => 'G09'
          },
          {
            'sample_name' => 'DEA103A554',
            'well_location' => 'H09'
          },
          {
            'sample_name' => 'DEA103A563',
            'well_location' => 'A10'
          },
          {
            'sample_name' => 'DEA103A584',
            'well_location' => 'B10'
          },
          {
            'sample_name' => 'DEA103A601',
            'well_location' => 'C10'
          },
          {
            'sample_name' => 'DEA103A591',
            'well_location' => 'D10'
          },
          {
            'sample_name' => 'DEA103A600',
            'well_location' => 'E10'
          },
          {
            'sample_name' => 'DEA103A580',
            'well_location' => 'F10'
          },
          {
            'sample_name' => 'DEA103A552',
            'well_location' => 'G10'
          },
          {
            'sample_name' => 'DEA103A553',
            'well_location' => 'H10'
          },
          {
            'sample_name' => 'DEA103A572',
            'well_location' => 'A11'
          },
          {
            'sample_name' => 'DEA103A567',
            'well_location' => 'B11'
          },
          {
            'sample_name' => 'DEA103A614',
            'well_location' => 'C11'
          },
          {
            'sample_name' => 'DEA103A549',
            'well_location' => 'D11'
          },
          {
            'sample_name' => 'DEA103A619',
            'well_location' => 'E11'
          },
          {
            'sample_name' => 'DEA103A533',
            'well_location' => 'F11'
          },
          {
            'sample_name' => 'DEA103A585',
            'well_location' => 'G11'
          },
          {
            'sample_name' => 'DEA103A606',
            'well_location' => 'H11'
          },
          {
            'sample_name' => 'DEA103A577',
            'well_location' => 'A12'
          },
          {
            'sample_name' => 'DEA103A622',
            'well_location' => 'B12'
          },
          {
            'sample_name' => 'DEA103A598',
            'well_location' => 'C12'
          },
          {
            'sample_name' => 'DEA103A589',
            'well_location' => 'D12'
          },
          {
            'sample_name' => '[ Empty ]',
            'sample_type' => 'NTC',
            'well_location' => 'E12'
          },
          {
            'sample_name' => '[ Empty ]',
            'sample_type' => 'NTC',
            'well_location' => 'F12'
          },
          {
            'sample_name' => '[ Empty ]',
            'sample_type' => 'NTC',
            'well_location' => 'G12'
          },
          {
            'sample_name' => '[ Empty ]',
            'sample_type' => 'NTC',
            'well_location' => 'H12'
          }
        ];

  is_deeply($file_creator->_samples, $samples, 'Creates the samples data correctly');
}

1;