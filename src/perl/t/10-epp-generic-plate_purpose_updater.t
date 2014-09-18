use strict;
use warnings;
use Test::More tests => 12;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::epp::generic::plate_purpose_updater', 'can use wtsi_clarity::epp::generic::plate_purpose_updater' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/plate_purpose_updater';

  my $PURPOSE = 'WGS Stock DNA';

  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $plate_purpose = wtsi_clarity::epp::generic::plate_purpose_updater->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-99911');
  # , $FAKE_PURPOSE
  lives_ok { $plate_purpose->fetch_and_update_targets($plate_purpose->process_doc) } 'managed to fetch and updates the containers';

  cmp_ok(scalar keys %{$plate_purpose->_targets}, '==', 1,
    'There should be only one container for the 5 artifacts as they have the same container.');

  my $PURPOSE_PATH = '/con:container/udf:field';

  foreach my $containerURI (keys %{$plate_purpose->_targets})
  {
    my @elements = util::xml::find_elements( $plate_purpose->_targets->{$containerURI}, $PURPOSE_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The purpose should be added to the container.');
    cmp_ok($elements[0]->textContent(), 'eq', $PURPOSE, 'The purpose should be '.$PURPOSE );
  }
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/plate_purpose_updater';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  my $PURPOSE = 'Because...';

  my $plate_purpose = wtsi_clarity::epp::generic::plate_purpose_updater->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-99912');

  lives_ok { $plate_purpose->fetch_and_update_targets($plate_purpose->process_doc) } 'managed to fetch and updates the containers';

  cmp_ok(scalar keys %{$plate_purpose->_targets}, '==', 2,
    'There should be two containers for the 5 artifacts as they have different containers.');

  my $PURPOSE_PATH = '/con:container/udf:field';

  foreach my $containerURI (keys %{$plate_purpose->_targets})
  {
    my @elements = util::xml::find_elements( $plate_purpose->_targets->{$containerURI}, $PURPOSE_PATH) ;
    cmp_ok(scalar @elements, '==', 1, 'The purpose should be added to the container.');
    cmp_ok($elements[0]->textContent(), 'eq', $PURPOSE, 'The purpose should be '.$PURPOSE );
  }
}

1;
