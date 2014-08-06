use strict;
use warnings;
use Test::MockObject::Extends;
use wtsi_clarity::util::request;
use Test::More tests => 10;

my $test_dir = 't/data/sm/validate_tag_plate';
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;

use_ok('wtsi_clarity::epp::sm::validate_tag_plate');

{
  my $epp = wtsi_clarity::epp::sm::validate_tag_plate->new(
    process_url => 'http://some.com/processes/151-12090'
  );

  isa_ok( $epp, 'wtsi_clarity::epp::sm::validate_tag_plate');

  is($epp->_tag_plate_barcode, '1234567890123', 'Gets the tag plate barcode correctly');
  is($epp->_gatekeeper_url, 'http://dev.psd.sanger.ac.uk:6610/api/1', 'Gets the correct url for Gatekeeper.');
  is($epp->_find_qcable_by_barcode_uuid, '4ad4af50-c568-11e3-ad09-3c4a9275d6c6', 'Gets the _find_qcable_by_barcode_uuid correctly');
  is($epp->_valid_status, 'available', 'Gets the valid status correctly');
  is($epp->_valid_lot_type, 'IDT Tags', 'Gets the valid lot type correctly');

  my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
  my $tag_plate_response = do {
    local $/ = undef;
    open my $fh, "<", $tag_plate_response_file
        or die "could not open $tag_plate_response_file: $!";
    <$fh>;
  };

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  is($epp->tag_plate->{'state'}, 'available', 'Gets the correct status of a valid tag plate.');

  my $lot_uuid = $epp->tag_plate->{'lot_uuid'};
  ok($lot_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of a lot.');

  my $lot_response_file = $test_dir. '/responses/valid_lot_response.json';
  my $lot_response = do {
    local $/ = undef;
    open my $fh, "<", $lot_response_file
        or die "could not open $lot_response_file: $!";
    <$fh>;
  };
  my $mocked_lot_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_lot_request->mock(q(get), sub{my ($self, $uri) = @_; return $lot_response;});
  is($epp->lot_type($lot_uuid), 'IDT Tags', 'Gets the correct lot type name.');
}

1;