use strict;
use warnings;
use Test::More tests => 5;
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

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981',
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
  my @map_keys = keys $pa->_container_to_artifact_map;

  is_deeply(\@map_keys, \@containers, 'Gets the containers');
  # is_deeply(values $pa->_container_to_artifact_map, @artifacts, 'Gets the artifacts');
}

{
  my $pa = wtsi_clarity::epp::sm::pico_analysis->new(
    process_url => 'http://claritytest.com/processes/24-11981_a',
  );

  $pa->_find_dtx_process();
}