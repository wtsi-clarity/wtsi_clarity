use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

use_ok('wtsi_clarity::epp::mapper');

{
  my $m = wtsi_clarity::epp::mapper->new_with_options(action => ['volume_check']);
  isa_ok( $m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::sm::volume_check', 'correct package name');
  throws_ok { wtsi_clarity::epp::mapper->new_with_options(action => ['unknown'])->package_names }
    qr /No callback for action unknown/, 'error when action is not registered';
}

{
  my $m = wtsi_clarity::epp::mapper->new_with_options(action => ['create_label']);
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::sm::create_label', 'correct package name');
  $m = wtsi_clarity::epp::mapper->new_with_options(action => ['stamp']);
  @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::stamp', 'correct package name');
}

{
  my $m = wtsi_clarity::epp::mapper->new_with_options(action => ['bed_verification']);
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::sm::bed_verification', 'correct package name');
}

1;
