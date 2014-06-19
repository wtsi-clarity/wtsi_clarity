use strict;
use warnings;
use Test::More tests => 16;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;

use_ok('wtsi_clarity::epp::sm::qc_complete', 'can use wtsi_clarity::epp::sm::qc_complete' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/qc_complete';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $qc_complete_step = wtsi_clarity::epp::sm::qc_complete->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-100359');

  lives_ok { $qc_complete_step->fetch_and_update_targets($qc_complete_step->process_doc) } 'managed to fetch and updates the samples';

  cmp_ok(scalar keys %{$qc_complete_step->_targets}, '==', 11,
    'There should be 11 artifacts (Test Fixture).');

  my $QC_COMPLETE_DATE_PATH = q(/smp:sample/udf:field[@name='QC Complete']);
  my $nb_of_today = 0;

  foreach my $sampleURI (keys %{$qc_complete_step->_targets})
  {
    my @elements = util::xml::find_elements( $qc_complete_step->_targets->{$sampleURI}, $QC_COMPLETE_DATE_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The completion date should be present on the sample.');
    my $element = shift @elements;
    $nb_of_today += 1 if ($element->textContent eq '1974-02-23');
  }

  cmp_ok($nb_of_today, '==', 2, 'Not all the date should be updated.');
}

1;
