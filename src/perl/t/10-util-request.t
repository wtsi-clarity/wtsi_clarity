use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use XML::LibXML;

use_ok('wtsi_clarity::util::request');

{
  my $r = wtsi_clarity::util::request->new();
  isa_ok( $r, 'wtsi_clarity::util::request');
  is ($r->cache_dir_var_name, q[WTSICLARITY_WEBCACHE_DIR], 'cache dir var name');
  is ($r->save2cache_dir_var_name, q[SAVE2WTSICLARITY_WEBCACHE], 'save2cache dir var name');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/cached/';
  local $ENV{'http_proxy'} = 'http://wibble';
  my $r = wtsi_clarity::util::request->new();
  my $data;
  lives_ok {
    $data = $r->get(q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-28177})
           } 'no error retrieving from cache';
  is($r->base_url, 'clarity-ap.internal.sanger.ac.uk:8080', 'base url correct');

  local $/=undef;
  open my $fh,  't/data/cached/processes/24-28177' or die "Couldn't open file";
  my $xml = <$fh>;
  close $fh;

  is ($data, $xml, 'content retrieved correctly');
}

{
  diag 'live test';
  my $r = wtsi_clarity::util::request->new();
  my $data = $r->get(q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/samples/GOU51A7});
  ok($data, 'data received');
  my $dom = XML::LibXML->load_xml(string => $data);
  lives_ok {$data = $r->put(q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/samples/GOU51A7}, $data)}
     'put request succeeds';
  #diag $data;
}

1;
