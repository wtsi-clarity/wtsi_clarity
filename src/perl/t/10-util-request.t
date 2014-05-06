use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;

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
    $data = $r->make(q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-28177})
           } 'no error retrieving from cache';
  is($r->base_url, 'clarity-ap.internal.sanger.ac.uk:8080', 'base url correct');

  local $/=undef;
  open my $fh,  't/data/cached/processes/24-28177' or die "Couldn't open file";
  my $xml = <$fh>;
  close $fh;

  is ($data, $xml, 'content retrieved correctly');
}

1;
