use strict;
use warnings;
use Test::More tests => 7;
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
  $m = wtsi_clarity::epp::mapper->new(action => 'stamp');
  is($m->package_name, 'wtsi_clarity::epp::stamp', 'correct package name');
}

{
  my $m = wtsi_clarity::epp::mapper->new(action => 'bed_verification');
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  is($m->package_name, 'wtsi_clarity::epp::sm::bed_verification', 'correct package name');
}

1;
