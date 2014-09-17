use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::epp::sm::fluidigm_request_volume_updater', 'can use wtsi_clarity::epp::sm::fluidigm_request_volume_updater' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/fluidigm_request_volume_updater';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::fluidigm_request_volume_updater->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-101157');

  lives_ok { $step->fetch_and_update_targets($step->process_doc, '123.45') } 'managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 8,
    'There should be 8 artifacts (only get the analyte type, no ResultFile).');

  my $TARGET_DATA_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);

  foreach my $sampleURI (keys %{$step->_targets})
  {
    my @elements = util::xml::find_elements( $step->_targets->{$sampleURI}, $TARGET_DATA_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The sample volume should be present on the sample.');
    my $element = shift @elements;
    cmp_ok($element->textContent, 'eq', '123.45', 'The sample volume should be as expected.');
  }

}

1;
