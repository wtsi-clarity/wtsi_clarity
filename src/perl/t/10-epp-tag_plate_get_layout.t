use strict;
use warnings;
use Test::MockObject::Extends;
use wtsi_clarity::util::request;
use Test::More tests => 18;

use Data::Dumper;

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
    process_url       => 'http://some.com/processes/151-12090',
    tag_plate_action  => 'get_layout',
  );

# tests whether the attributtes are correct
{
  isa_ok( $epp, 'wtsi_clarity::epp::sm::tag_plate');

  is($epp->_tag_plate_barcode, '1234567890123', 'Gets the tag plate barcode correctly');
  is($epp->_gatekeeper_url, 'http://dev.psd.sanger.ac.uk:6610/api/1', 'Gets the correct url for Gatekeeper.');
  is($epp->_find_qcable_by_barcode_uuid, '4ad4af50-c568-11e3-ad09-3c4a9275d6c6', 'Gets the _find_qcable_by_barcode_uuid correctly');
  is($epp->_valid_status, 'available', 'Gets the valid status correctly');
  is($epp->_valid_lot_type, 'IDT Tags', 'Gets the valid lot type correctly');
  is($epp->_ss_user_uuid, '00000000-0000-0000-0000-000000000001', 'Gets the valid user uuid.');
}

# tests to get the layout of the tag plate
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

  my $lot = $epp->_lot($lot_uuid);

  is($lot->{'lot_type'}, 'IDT Tags', 'Gets the correct lot type name.');

  my $template_uuid = $lot->{'template_uuid'};

  ok($template_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of a tag plate template.');

  my $tag_plate_layout_response_file = $test_dir. '/responses/valid_tag_plate_layout_response.json';
  my $tag_plate_layout_response = get_fake_response($tag_plate_layout_response_file);

  my $mocked_tag_plate_layout_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_layout_request->mock(q(get), sub{my ($self, $uri, $content) = @_; return $tag_plate_layout_response;});

  $epp->_set_template_uuid($template_uuid);

  my $tag_plate_layout = $epp->tag_plate_layout;

  isa_ok($tag_plate_layout, 'HASH', 'Gets the correct data structure of the tag plate layout.');

  (my $root_key) = sort keys %{$tag_plate_layout};

  is($root_key, 'tag_layout_template', 'Gets back the correct JSON request for tag plate layout');
}

# test to change the state of the tag plate with an invalid state transition
{
  my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
  my $tag_plate_response = get_fake_response($tag_plate_response_file);

  my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

  my $asset_uuid = $epp->_tag_plate->{'asset_uuid'};
  ok($asset_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of an asset.');
  is($asset_uuid, '11111111-2222-3333-4444-666666666666', 'Gets the correct UUID of the asset.');

  my $tag_plate_state_change_response_file = $test_dir. '/responses/error_state_change_response.json';
  my $tag_plate_state_change_response = get_fake_response($tag_plate_state_change_response_file);
  my $mocked_tag_plate_state_change_request = Test::MockObject::Extends->new( $epp->ss_request );
  $mocked_tag_plate_state_change_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_state_change_response;});

  my $state_change_response = $epp->set_tag_plate_to_exhausted($asset_uuid);

  isa_ok($state_change_response, 'HASH', 'Gets the correct data structure for the state change response.');

  (my $root_key) = sort keys %{$state_change_response};
  is($root_key, 'general', 'Gets back an error JSON request for invalid state change');
}

# test to change the state of the tag plate with a valid state transition
# TODO ke4 get valid response JSON for state change
# {
#   my $tag_plate_response_file = $test_dir. '/responses/valid_tag_plate_response.json';
#   my $tag_plate_response = get_fake_response($tag_plate_response_file);

#   my $mocked_tag_plate_request = Test::MockObject::Extends->new( $epp->ss_request );
#   $mocked_tag_plate_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_response;});

#   my $asset_uuid = $epp->tag_plate->{'asset_uuid'};
#   ok($asset_uuid =~ m/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/, 'Gets a correct UUID pattern of an asset.');
#   is($asset_uuid, '11111111-2222-3333-4444-666666666666', 'Gets the correct UUID of the asset.');

#   my $tag_plate_state_change_response_file = $test_dir. '/responses/valid_state_change_response.json';
#   my $tag_plate_state_change_response = get_fake_response($tag_plate_state_change_response_file);
#   my $mocked_tag_plate_state_change_request = Test::MockObject::Extends->new( $epp->ss_request );
#   $mocked_tag_plate_state_change_request->mock(q(post), sub{my ($self, $uri, $content) = @_; return $tag_plate_state_change_response;});

#   my $state_change_response = $epp->set_tag_plate_to_exhausted($asset_uuid);

#   isa_ok($state_change_response, 'HASH', 'Gets the correct data structure for the state change response.');

#   (my $root_key) = sort keys %{$state_change_response};
#   is($root_key, 'general', 'Gets back an error JSON request for invalid state change');
# }

1;