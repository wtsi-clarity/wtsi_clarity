use strict;
use warnings;
use Test::More tests => 7;
use XML::LibXML;

use_ok('wtsi_clarity::epp::sm::pico_analysis');

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/pico_analysis';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981',
  );

  isa_ok($pa, 'wtsi_clarity::epp::sm::pico_analysis');
  can_ok($pa, qw/run/);
}

# Input URIs
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981_b',
  );

  my @output_uris = (
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-18794?state=7394',
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-18796?state=7396',
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-18798?state=7398',
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-18800?state=7400',
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/2-18786?state=7386',
  );

  is_deeply($pa->_input_uris, \@output_uris, 'Finds the lims uris correctly');
}

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981_a',
  );

  my @containers = ('27-382', '27-345');

  # Can't test at the moment as uses batch request which is a POST,
  # which means it isn't cached
  
  # my @map_keys = keys $pa->_container_to_artifact_map;

  # is_deeply(\@map_keys, \@containers, 'Gets the containers');
  # is_deeply(values $pa->_container_to_artifact_map, @artifacts, 'Gets the artifacts');
}

# Extract file url / file name
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981',
  );

  my $parser = XML::LibXML->new();
  my $output_analyte = $parser->parse_file('t/data/sm/pico_analysis/artifacts/92-10870?state=5320');

  is ($pa->_extract_file_url($output_analyte), 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/files/92-10870-40-178', 'Extracts the file url');
  is ($pa->_extract_file_name($output_analyte), 'PicoAssay', 'Extracts the file name');
}

# Extract file location
{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981',
  );

  my $parser = XML::LibXML->new();
  my $file = $parser->parse_file('t/data/sm/pico_analysis/files/92-10870-40-178');

  is ($pa->_extract_file_location($file), 'sftp://web-claritytest-01.internal.sanger.ac.uk/opt/gls/clarity/users/glsftp/Process/2014/7/24-4158/92-10870-40-177', 'Extracts the file location');
}