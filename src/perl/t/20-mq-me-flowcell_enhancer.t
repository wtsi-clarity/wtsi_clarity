use warnings;
use strict;

use Test::More tests => 20;
use Test::Exception;
use Cwd;
use Carp;

use_ok('wtsi_clarity::mq::me::flowcell_enhancer');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

sub _load_sample {
  my ($testdata_dir, $sample_file_name) = @_;

  return XML::LibXML->load_xml(location => cwd . $testdata_dir . $sample_file_name) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $sample_file_name;
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/flowcell_enhancer';

  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://testserver.com:1234/here/processes/24-41132',
    step_url    => 'http://testserver.com:1234/here/steps/24-41132',
    timestamp   => '123456789',
  );

  is($me->_flowcell_barcode, 'HFC2HADXX', 'Extracts the Flowcell barcode correctly');
  is($me->_spiked_hyb_barcode, '3980622307787', 'Extracts the Spiked Hyb barcode correctly');
  is($me->_flowcell_id, '27-7093', 'Extracts the flowcell id correctly');

  lives_ok { $me->prepare_messages } 'Prepares those messages just fine';
}

{
  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://testserver.com:1234/here/processes/24-41132',
    step_url    => 'http://testserver.com:1234/here/steps/24-41132',
    timestamp   => '123456789',
  );

  is($me->_extract_lane_position('1:1'), '1', 'Extracts lane position correctly');
  is($me->_extract_lane_position('2:1'), '2', 'Extracts lane position correctly');

  my ($tag_set_name, $tag_index, $tag_sequence) = $me->_extract_tag_info('Sanger_168tags - 10 mer tags: tag 52 (TCGTTAGC)');
  is($tag_set_name, 'Sanger_168tags - 10 mer tags', 'Extracts the tag set name');
  is($tag_index, '52', 'Extracts the tag index');
  is($tag_sequence, 'TCGTTAGC', 'Extracts the tag sequence');

  my ($tag_set_name2, $tag_index2, $tag_sequence2) = $me->_extract_tag_info('Sanger_168tags - 10 mer tags: tag 51 (TTACTCGC)');
  is($tag_set_name2, 'Sanger_168tags - 10 mer tags', 'Extracts the tag set name');
  is($tag_index2, '51', 'Extracts the tag index');
  is($tag_sequence2, 'TTACTCGC', 'Extracts the tag sequence');
}

# Fix for Bug #483
# id_pool_lims column in the new warehouse should contain the barcode
# of the last container of the pool before it went to the flowcell
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/flowcell_enhancer';

  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://testserver.com:1234/here/processes/24-37122',
    step_url    => 'http://testserver.com:1234/here/steps/24-37122',
    timestamp   => '123456789',
  );

  my $lanes = $me->prepare_messages->[0]->{'flowcell'}->{'lanes'};

  is($lanes->[0]->{'id_pool_lims'}, '2460272533664', 'Finds the barcode of the first pool');
  is($lanes->[1]->{'id_pool_lims'}, '2460272533664', 'Finds the barcode of the second pool');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/flowcell_enhancer';
  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://testserver.com:1234/here/processes/24-37122',
    step_url    => 'http://testserver.com:1234/here/steps/24-37122',
    timestamp   => '123456789',
  );

  my $sample_file_name = q{samples.SH2155A67};
  my $testdata_dir  = qq{/$ENV{'WTSICLARITY_WEBCACHE_DIR'}/GET/};
  my $sample_xml = _load_sample($testdata_dir, $sample_file_name);

  my $expected_project_info = {
    'cost_code'                   => 'TBC',
    'study_id'                    => 'SH2155',
    'requested_insert_size_from'  => 100,
    'requested_insert_size_to'    => 200,
    'read_length'                 => 123,
  };

  is_deeply($me->_get_project_info($sample_xml), $expected_project_info, 'Returns the correct project information.');

  $sample_file_name = q{samples.SH2155A68};
  my $sample_xml2 = _load_sample($testdata_dir, $sample_file_name);

  is_deeply($me->_get_project_info($sample_xml2), $expected_project_info, 'Returns the correct project information.');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/flowcell_enhancer';
  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://testserver.com:1234/here/processes/24-37122',
    step_url    => 'http://testserver.com:1234/here/steps/24-37122',
    timestamp   => '123456789',
  );

  my $expected_sample_data = {
    'study_id' => 'SH2155',
    'bait_name' => '14M_0731661',
    'cost_code' => 'TBC',
    'pipeline_id_lims' => 'GCLP-CLARITY-ISC',
    'tag_index' => '65',
    'entity_type' => 'library_indexed',
    'sample_uuid' => 'bf1d9d38-0a04-11e5-b228-cef7c1d4f35d',
    'tag_set_name' => 'Sanger_168tags - 10 mer tags',
    'tag_sequence' => 'TTGTTCCA',
    'id_library_lims' => '2460271392675:A9',
    'is_r_and_d' => 'false',
    'requested_insert_size_from' => '100',
    'requested_insert_size_to' => '200'
  };
  my $expected_forward_length = 123;
  my $expected_reverse_length = 123;

  is_deeply($me->_build_sample('SH2155A67'), $expected_sample_data, 'Returns the correct sample data.');
  is($me->_forward_read_length, $expected_forward_length, 'Returns the correct forward length value.');
  is($me->_reverse_read_length, $expected_forward_length, 'Returns the correct reverse length value.');
}

1;