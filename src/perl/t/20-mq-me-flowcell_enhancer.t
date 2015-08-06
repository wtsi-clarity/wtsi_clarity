use warnings;
use strict;

use Test::More tests => 15;
use Test::Exception;

use_ok('wtsi_clarity::mq::me::flowcell_enhancer');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

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

1;