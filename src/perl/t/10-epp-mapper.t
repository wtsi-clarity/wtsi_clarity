use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;

use_ok('wtsi_clarity::epp::mapper');

{
  my $m = wtsi_clarity::epp::mapper->new(action => ['check_volume']);
  isa_ok( $m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::sm::volume_checker', 'correct package name');
  throws_ok { wtsi_clarity::epp::mapper->new(action => ['unknown'])->package_names }
    qr /No callback for action unknown/, 'error when action is not registered';
}

{
  my $m = wtsi_clarity::epp::mapper->new(action => ['create_label']);
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::generic::label_creator', 'correct package name');
  $m = wtsi_clarity::epp::mapper->new(action => ['stamp']);
  @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::generic::stamper', 'correct package name');
}

{
  my $m = wtsi_clarity::epp::mapper->new(action => ['verify_bed']);
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is($package_names[0], 'wtsi_clarity::epp::generic::bed_verifier', 'correct package name');
}

{
  my $m = wtsi_clarity::epp::mapper->new(action => ['verify_bed', 'create_label']);
  isa_ok($m, 'wtsi_clarity::epp::mapper');
  my @package_names = $m->package_names;
  is(@package_names, 2, 'correct array size');
  is($package_names[0], 'wtsi_clarity::epp::generic::bed_verifier',  'correct package name');
  is($package_names[1], 'wtsi_clarity::epp::generic::label_creator', 'correct package name');
}

1;
