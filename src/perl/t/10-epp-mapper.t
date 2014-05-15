use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use_ok('wtsi_clarity::epp::mapper');

{
  my $m = wtsi_clarity::epp::mapper->new(action => 'volume_check');
  isa_ok( $m, 'wtsi_clarity::epp::mapper');
  is($m->package_name, 'wtsi_clarity::epp::sm::volume_check', 'correct package name');
  throws_ok { wtsi_clarity::epp::mapper->new(action => 'unknown')->package_name }
    qr /No callback for action unknown/, 'error when action is not registered';
}

{
  my $m = wtsi_clarity::epp::mapper->new(action => 'create_label');
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  is($m->package_name, 'wtsi_clarity::epp::sm::create_label', 'correct package name');
}

1;
