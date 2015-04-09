use warnings;
use strict;

use Test::More tests => 13;
use Test::Exception;

use_ok('wtsi_clarity::mq::me::flowcell_enhancer');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/mq/me/flowcell_enhancer';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/processes/24-30038',
    step_url    => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/steps/24-30038',
    timestamp   => '123456789',
  );

  is($me->_flowcell_barcode, '12345678903', 'Extracts the Flowcell barcode correctly');
  is($me->_spiked_hyb_barcode, '999999999999', 'Extracts the Spiked Hyb barcode correctly');
  is($me->_flowcell_id, '27-5829', 'Extracts the flowcell id correctly');

  lives_ok { $me->prepare_messages } 'Prepares those messages just fine';
}

{
  my $me = wtsi_clarity::mq::me::flowcell_enhancer->new(
    process_url => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/processes/24-30038',
    step_url    => 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/steps/24-30038',
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

1;