use strict;
use warnings;
use Test::More tests => 6;
use XML::LibXML;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::epp::generic::file_publisher');

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/file_publisher';
# local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

{
  my $pf = wtsi_clarity::epp::generic::file_publisher->new(
    process_url => 'http://claritytest.com/processes/24-2995',
  );

  isa_ok($pf, 'wtsi_clarity::epp::generic::file_publisher');
  can_ok($pf, qw/run/);
}

{
  my $pf = wtsi_clarity::epp::generic::file_publisher->new(
    process_url => 'http://claritytest.com/processes/24-2995',
  );

  my @output_uris = (
    'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/artifacts/92-7352?state=3552',
  );

  is_deeply($pf->_output_uris, \@output_uris, 'fetches the right output uris');
}

{
  my $pf = wtsi_clarity::epp::generic::file_publisher->new(
    process_url => 'http://claritytest.com/api/v2/processes/24-2995',
  );

  my $parser = XML::LibXML->new();
  my $artifacts_xml = $parser->parse_file('t/data/epp/generic/file_publisher/POST/batch/artifacts');

  my @expected_results = ('http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/files/92-7352-40-168');

  is_deeply($pf->_extract_files($artifacts_xml), \@expected_results, 'fetches the right files uris');
}

{
  my $pf = wtsi_clarity::epp::generic::file_publisher->new(
    process_url => 'http://claritytest.com/processes/24-2995',
  );

  my $parser = XML::LibXML->new();
  my $files_xml = $parser->parse_file('t/data/epp/generic/file_publisher/POST/batch/files');

  $pf->_set_is_published($files_xml);

  my $is_published = $files_xml->findvalue('/file:details/file:file/is-published');

  is($is_published, 'true');
}