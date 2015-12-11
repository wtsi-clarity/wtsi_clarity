use strict;
use warnings;
use Test::More tests => 6;
use Test::MockObject::Extends;

use_ok('wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator');

{
  my $little_tip_process = wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator->new(
    process_url => 'http://clarity.dev/processes/122-22459',
    _well_volumes => [1,2,3,4,5],
  );

  is($little_tip_process->_tip_size, 'p50', 'Gets the right tip size for volumes all under 50');

  my $big_tip_process = wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator->new(
    process_url => 'http://clarity.dev/processes/122-22459',
    _well_volumes => [1,2,3,4,51],
  );

  is($big_tip_process->_tip_size, 'p250', 'Gets the right tip size for volumes containing a value over 50');
}

{
  my $expected_result = [
    'Sample,Name,Source EAN13,Source Barcode,Source Stock,Source Well,Destination EAN13,Destination Barcode,Destination Well,Source Volume',
    '1,PCRXP1,Not used,Not used,Not used,A1,Not used,Not used,A1,180',
    '2,PCRXP1,Not used,Not used,Not used,B1,Not used,Not used,B1,180',
    '3,PCRXP1,Not used,Not used,Not used,C1,Not used,Not used,C1,100',
    '4,PCRXP1,Not used,Not used,Not used,D1,Not used,Not used,D1,75',
    '5,PCRXP1,Not used,Not used,Not used,E1,Not used,Not used,E1,54.3478260869565',
    '6,PCRXP1,Not used,Not used,Not used,F1,Not used,Not used,F1,50',
    '7,PCRXP1,Not used,Not used,Not used,G1,Not used,Not used,G1,42.8571428571429',
    '8,PCRXP1,Not used,Not used,Not used,H1,Not used,Not used,H1,37.5',
    '9,PCRXP1,Not used,Not used,Not used,A2,Not used,Not used,A2,33.3333333333333',
    '10,PCRXP1,Not used,Not used,Not used,B2,Not used,Not used,B2,29.9031139109286',
    '11,PCRXP1,Not used,Not used,Not used,C2,Not used,Not used,C2,3',
  ];
  my $sorted_input_analytes = [
    { well => 'A:1', molarity => 1 },
    { well => 'B:1', molarity => 2 },
    { well => 'C:1', molarity => 30 },
    { well => 'D:1', molarity => 40 },
    { well => 'E:1', molarity => 55.2 },
    { well => 'F:1', molarity => 60 },
    { well => 'G:1', molarity => 70 },
    { well => 'H:1', molarity => 80 },
    { well => 'A:2', molarity => 90 },
    { well => 'B:2', molarity => 100.324 },
    { well => 'C:2', molarity => 1000 },
  ];

  my $mocked_rearray_to_hyb = Test::MockObject::Extends->new(
    wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator->new(
      process_url => 'http://clarity.dev/processes/122-22459',
    )
  );

  $mocked_rearray_to_hyb->mock(q(_sorted_input_analytes), sub {
    return $sorted_input_analytes;
  });

  $mocked_rearray_to_hyb->mock(q(_formatted_date), sub {
    return '011215';
  });

  $mocked_rearray_to_hyb->mock(q(_output_container_signature), sub {
    return 'ABC123';
  });

  my $file_content = $mocked_rearray_to_hyb->_beckman_file->content;

  is_deeply($file_content, $expected_result, 'get_file returns a file object with the correct content');
  is($mocked_rearray_to_hyb->beckman_file_name, 'ABC123_rearray_to_hyb_p250_011215.csv', 'Names the file correctly');
}

{
  my $beckman_creator = wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator->new(
    process_url => 'http://clarity.dev/processes/122-22459',
  );

  can_ok($beckman_creator, qw/ run /);
}


1;
