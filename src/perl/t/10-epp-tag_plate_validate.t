use strict;
use warnings;
use Test::MockObject::Extends;
use wtsi_clarity::util::request;
use Test::More tests => 15;

sub get_fake_response {
  my $response_file = shift;
  my $response = do {
    local $/ = undef;
    open my $fh, "<", $response_file
        or die "could not open $response_file: $!";
    <$fh>;
  };

  return $response;
}

my $chome_name = 'WTSI_CLARITY_HOME';
my $test_dir = 't/data/sm/tag_plate';

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
local $ENV{$chome_name}= q[t/data/config];

use_ok('wtsi_clarity::epp::sm::tag_plate');

my $epp = wtsi_clarity::epp::sm::tag_plate->new(
    process_url           => 'http://some.com/processes/151-12090',
    step_url              => 'http://some.com/steps/151-16106',
    tag_layout_file_name  => 'test_layout_file_name',
  );

# tests whether the attributtes are correct
{
  isa_ok( $epp, 'wtsi_clarity::epp::sm::tag_plate');

  is($epp->_tag_plate_barcode, '1234567890123', 'Gets the tag plate barcode correctly');
  is($epp->_gatekeeper_url, 'http://dev.psd.sanger.ac.uk:6610/api/1', 'Gets the correct url for Gatekeeper.');
  is($epp->_find_qcable_by_barcode_uuid, '11111111-2222-3333-4444-555555555555', 'Gets the _find_qcable_by_barcode_uuid correctly');
  is($epp->_valid_status, 'available', 'Gets the valid status correctly');
  is($epp->_valid_lot_type, 'IDT Tags', 'Gets the valid lot type correctly');
}


# tests the invalid tag plate
{
  my $tag_plate_response_file = $test_dir. '/responses/invalid_tag_plate_response.json';
  my $tag_plate_response = get_fake_response($tag_plate_response_file);

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  is($epp->_tag_plate->{'state'}, 'created', 'Gets the correct status of an invalid tag plate.');
}

# tests the valid tag plate and invalid lot type name
{
  my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
  my $tag_plate_response = get_fake_response($tag_plate_response_file);

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  my $tag_plate = $epp->_tag_plate;

  is($tag_plate->{'state'}, 'available', 'Gets the correct status of a valid tag plate.');

  my $lot_uuid = $tag_plate->{'lot_uuid'};
  ok($lot_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of a lot.');

  my $lot_response_file = $test_dir. '/responses/invalid_lot_response.json';
  my $lot_response = get_fake_response($lot_response_file);

  my $mocked_lot_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_lot_request->mock(q(get), sub{my ($self, $uri) = @_; return $lot_response;});

  is($epp->_lot($lot_uuid)->{'lot_type'}, 'NO IDT Tags', 'Gets the correct lot type name.');
}

# tests the valid tag plate and valid lot type name
{
  my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
  my $tag_plate_response = get_fake_response($tag_plate_response_file);

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  my $tag_plate = $epp->_tag_plate;

  is($tag_plate->{'state'}, 'available', 'Gets the correct status of a valid tag plate.');

  my $lot_uuid = $tag_plate->{'lot_uuid'};
  ok($lot_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of a lot.');

  my $lot_response_file = $test_dir. '/responses/valid_lot_response.json';
  my $lot_response = get_fake_response($lot_response_file);

  my $mocked_lot_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_lot_request->mock(q(get), sub{my ($self, $uri) = @_; return $lot_response;});
  is($epp->_lot($lot_uuid)->{'lot_type'}, 'IDT Tags', 'Gets the correct lot type name.');
}

# tests the validate_tag_plate method with valid responses
{
  my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
  my $tag_plate_response = get_fake_response($tag_plate_response_file);

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  my $lot_response_file = $test_dir. '/responses/valid_lot_response.json';
  my $lot_response = get_fake_response($lot_response_file);

  my $mocked_lot_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_lot_request->mock(q(get), sub{my ($self, $uri) = @_; return $lot_response;});

  is($epp->validate_tag_plate, 1, "The validation returns true for available tag plate with 'IDT Tags' lot type.");
}

1;