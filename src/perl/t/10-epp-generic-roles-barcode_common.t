use strict;
use warnings;
use Test::More tests => 285;
use Test::Exception;
use List::Util qw(sum max);

use Moose::Meta::Class;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

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

{
  my $barcode_service = Moose::Meta::Class->create(
    'New::Class',
    superclasses => [qw/wtsi_clarity::epp/],
    roles => [qw/wtsi_clarity::epp::generic::roles::barcode_common/],
  )->new_object(process_url => $base_uri . '/processes/24-64190');

  my @alphabet = split("", "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ:_-");

  for my $i (6000..6100) {
    my $barcode;
    lives_ok{
      ($barcode) = $barcode_service->generate_barcode("27-" . $i)
    } "Doesn't crash";

    if ($config->barcode_mint->{'internal_generation'}) {
      my @chars = split("", $barcode);

      my $sum = sum(map {
        if ($_ % 2 == 0) {
          $chars[$_]
        } else {
          $chars[$_] * 3
        }
      } 0..$#chars);

      is($sum % 10, 0, "Checksum correct")
    } else {
      my @chars = split("", $barcode);

      my $sum = sum(map {
        my $c = $chars[$_];
        my ($num) = grep {
          $alphabet[$_] eq $c
        } 0..$#alphabet;
        (1 + $#chars - $_) ^ $num
      } 0..$#chars);

      is($sum % 10, 0, "Checksum correct for: $barcode");
    }
  }
}

{
  # Checksum tests

  my $barcode_service = Moose::Meta::Class->create(
    'New::Class',
    superclasses => [qw/wtsi_clarity::epp/],
    roles => [qw/wtsi_clarity::epp::generic::roles::barcode_common/],
  )->new_object(process_url => $base_uri . '/processes/24-64190');

  my $barcode = "123456789ABCDEFGHIJKLMNOPQ";

  for my $i (0..length($barcode) - 1) {
    my @changes = ();

    for my $c ("0".."9", "A".."Z") {
      my $new_barcode = $barcode;
      substr($new_barcode, $i, 1) = $c;
      my $new_checksum = substr($barcode_service->_add_checksum($new_barcode), length($new_barcode), 1);

      $changes[$new_checksum]++;
    }

    cmp_ok((max @changes), '<', 10, "Checksum is well distributed when position $i is changed.");
  }

  for my $i (0..length($barcode) - 1) {
    my $changes = 0;
    my $old_checksum = substr($barcode_service->_add_checksum($barcode), length($barcode), 1);
    for my $c ("0".."9", "A".."Z") {
      my $new_barcode = $barcode;
      substr($new_barcode, $i, 1) = $c;
      my $new_checksum = substr($barcode_service->_add_checksum($new_barcode), length($new_barcode), 1);

      if ($old_checksum ne $new_checksum) {
        $changes++;
      }
      $old_checksum = $new_checksum;
    }

    cmp_ok($changes, '>', 30, "Sequential characters make different checksums at pos $i.");
  }

  for my $i (0..length($barcode) - 2) {
    my $new_barcode = $barcode;
    my $old_checksum = substr($barcode_service->_add_checksum($barcode), length($barcode), 1);

    # Swap two adjacent characters.
    my $temp = substr($new_barcode, $i, 1);
    substr($new_barcode, $i, 1) = substr($new_barcode, $i + 1, 1);
    substr($new_barcode, $i + 1, 1) = $temp;

    my $new_checksum = substr($barcode_service->_add_checksum($new_barcode), length($new_barcode), 1);

    isnt($old_checksum, $new_checksum, "Swapped characters make different checksums at pos $i.");
  }
}