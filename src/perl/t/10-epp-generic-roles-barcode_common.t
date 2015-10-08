use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use Moose::Meta::Class;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/barcode_common';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $barcode_service = Moose::Meta::Class->create(
    'New::Class',
    superclasses => [qw/wtsi_clarity::epp/],
    roles => [qw/wtsi_clarity::epp::generic::roles::barcode_common/],
  )->new_object(process_url => $base_uri . '/processes/24-64190');

  my $barcode;
  lives_ok{
    $barcode = $barcode_service->generate_barcode("27-61234")
  } 'Doesn\'t crash';

  like($barcode, qr/61234/, "Barcode has correct ID");
  like($barcode, qr/SM/, "Barcode has 'SM'");
}

{
  my $barcode_service = Moose::Meta::Class->create(
    'New::Class',
    superclasses => [qw/wtsi_clarity::epp/],
    roles => [qw/wtsi_clarity::epp::generic::roles::barcode_common/],
  )->new_object(process_url => $base_uri . '/processes/24-64190');

  my $barcode;
  lives_ok{
    $barcode = $barcode_service->get_barcode_from_id("27-6064")
  } 'Doesn\'t crash';

  like($barcode, qr/6064/, "Barcode has correct ID");
  like($barcode, qr/SM/, "Barcode has 'SM'");
}