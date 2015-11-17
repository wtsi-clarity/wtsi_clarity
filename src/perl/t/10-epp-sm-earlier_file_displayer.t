use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Carp;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/earlier_file_displayer';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::sm::earlier_file_displayer', 'can use wtsi_clarity::epp::sm::earlier_file_displayer');

{
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/bla-bla',
    process_type  => 'process_type',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );
  isa_ok($earlier_file_displayer, 'wtsi_clarity::epp::sm::earlier_file_displayer');
  can_ok($earlier_file_displayer, qw/ run /);
}

{
  # Tests for determine the Lims ID of the Output Artifact
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'process_type',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  my @expected_output_artifact_uris = [
    'http://testserver.com:1234/here/artifacts/2-258083?state=128433',
    'http://testserver.com:1234/here/artifacts/2-258084?state=128434',
    'http://testserver.com:1234/here/artifacts/2-258087?state=128437',
    'http://testserver.com:1234/here/artifacts/2-258088?state=128438',
    'http://testserver.com:1234/here/artifacts/2-258085?state=128435',
    'http://testserver.com:1234/here/artifacts/2-258086?state=128436',
    'http://testserver.com:1234/here/artifacts/2-258091?state=128441',
    'http://testserver.com:1234/here/artifacts/2-258092?state=128442',
    'http://testserver.com:1234/here/artifacts/2-258089?state=128439',
    'http://testserver.com:1234/here/artifacts/2-258090?state=128440',
    'http://testserver.com:1234/here/artifacts/2-258095?state=128445',
    'http://testserver.com:1234/here/artifacts/2-258096?state=128446',
    'http://testserver.com:1234/here/artifacts/2-258093?state=128443',
    'http://testserver.com:1234/here/artifacts/2-258094?state=128444',
    'http://testserver.com:1234/here/artifacts/2-258098?state=128448',
    'http://testserver.com:1234/here/artifacts/2-258097?state=128447',
    'http://testserver.com:1234/here/artifacts/2-258100?state=128450',
    'http://testserver.com:1234/here/artifacts/2-258099?state=128449',
    'http://testserver.com:1234/here/artifacts/2-258152?state=128452',
    'http://testserver.com:1234/here/artifacts/2-258151?state=128451',
    'http://testserver.com:1234/here/artifacts/2-258154?state=128454',
    'http://testserver.com:1234/here/artifacts/2-258153?state=128453',
    'http://testserver.com:1234/here/artifacts/2-258156?state=128456',
    'http://testserver.com:1234/here/artifacts/2-258155?state=128455',
    'http://testserver.com:1234/here/artifacts/2-258158?state=128458',
    'http://testserver.com:1234/here/artifacts/2-258157?state=128457',
    'http://testserver.com:1234/here/artifacts/2-258160?state=128460',
    'http://testserver.com:1234/here/artifacts/2-258159?state=128459',
    'http://testserver.com:1234/here/artifacts/2-258162?state=128462',
    'http://testserver.com:1234/here/artifacts/2-258161?state=128461',
    'http://testserver.com:1234/here/artifacts/2-258163?state=128463',
    'http://testserver.com:1234/here/artifacts/2-258164?state=128464',
    'http://testserver.com:1234/here/artifacts/2-258165?state=128465'
  ];

  my @actual_output_limsids = $earlier_file_displayer->process_doc->output_analyte_uris;

  is_deeply(\@actual_output_limsids, \@expected_output_artifact_uris,
  'Returns the correct output lims ids.');
}

{
  # Tests for getting the sample limsid
  my @expected_output_artifact_uris = [
    'http://testserver.com:1234/here/artifacts/2-258083?state=128433',
    'http://testserver.com:1234/here/artifacts/2-258084?state=128434',
  ];
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url           => $base_uri . '/processes/24-31273',
    process_type          => 'process_type',
    file_name             => 'Tecan File',
    udf_name              => 'Tecan File',
    output_artifact_uris => @expected_output_artifact_uris,
  );

  my $expected_sample_limsid = 'DEA103A476';
  my $artifact_uri = $earlier_file_displayer->process_doc->output_artifact_uris->[0];
  is($earlier_file_displayer->process_doc->sample_limsid_by_artifact_uri($artifact_uri), $expected_sample_limsid,
  'Returns the correct limsid of the sample');
}

{
  # Test for getting the ResultFile limsid by the sample limsid and process type
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  my $expected_result_file_limsid = '92-24760';
  is($earlier_file_displayer->_result_file_limsid, $expected_result_file_limsid,
  'Returns the correct limsid of the result file.');
}

{
  # Tests for getting the associated file's limsid
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  my $expected_file_limsid = '40-4552';
  is($earlier_file_displayer->_file_limsid, $expected_file_limsid,
  'Returns the correct limsid of the associated file.');
}

{
  # Tests for exception, when file limsid could not be found
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'Not existing process',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  throws_ok {
    $earlier_file_displayer->_get_and_validate_file_id
  }
    qr/The 'Tecan File' could not be found in the given process\: 'Not existing process'./,
    'Throws an error when the limsid of the file is not valid.';
}

{
  # Tests for get the Tecan file id
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  my $expected_file_id = '4552';

  is($earlier_file_displayer->_get_and_validate_file_id, $expected_file_id, 'Returns the correct Tecan file id.');
}

{
  # Tests for getting the Tecan file URI
  my $earlier_file_displayer = wtsi_clarity::epp::sm::earlier_file_displayer->new(
    process_url   => $base_uri . '/processes/24-31273',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

  my $expected_tecan_file_uri = 'http://testserver.com:1234/clarity/api/files/4552';

  is($earlier_file_displayer->_get_tecan_file_uri, $expected_tecan_file_uri, 'Returns the correct Tecan file URI.');

}

1;