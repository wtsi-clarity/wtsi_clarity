use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use_ok('wtsi_clarity::mq::mapper');

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  isa_ok($mq_mapper, 'wtsi_clarity::mq::mapper');
}

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  is($mq_mapper->package_name('sample'), 'wtsi_clarity::mq::me::sample_enhancer', 'Creates the correct package name');
}

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  is($mq_mapper->package_name('flowcell'), 'wtsi_clarity::mq::me::flowcell_enhancer',
    'Creates the correct package for flowcell purpose');
}

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  is($mq_mapper->package_name('sample_manifest'), 'wtsi_clarity::epp::reports::manifest',
    'Creates the correct package name for a sample manifest report');
}

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  is($mq_mapper->package_name('charging_fluidigm'), 'wtsi_clarity::mq::me::charging::fluidigm',
    'Creates the correct package name for a fluidigm charging report');
}

{
  my $mq_mapper = wtsi_clarity::mq::mapper->new();
  throws_ok { $mq_mapper->package_name('jibberish') }
    qr/Purpose jibberish could not be found/,
    'Throws an error when purpose can not be found';
}