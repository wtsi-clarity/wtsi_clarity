use strict;
use warnings;
use Moose::Meta::Class;
use Test::More tests => 3;
use Test::Exception;
use Cwd;
use Carp;
use XML::LibXML;
use XML::SemanticDiff;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::epp::generic::plate_storer');

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/plate_storer';
  my $plate_storer = wtsi_clarity::epp::generic::plate_storer->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-17479');
  cmp_ok ( $plate_storer->_freezer_barcode(), 'eq', '1233', q{The freezer barcode should be correct.}) ;
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/plate_storer';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $testdata_dir  = q{/t/data/epp/generic/plate_storer/};
  my $testdata_file = q{testdata1};
  my $expected_file = q{testdata1_expected_results};

  my $plate_storer = wtsi_clarity::epp::generic::plate_storer->new( process_url => 'http://clarity-ap:8080/api/v2/processes/24-17479' );

  my $expected_results = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file ;
  my $testdata_xml     = $plate_storer->_update_container_details();

  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($testdata_xml, $expected_results);
  cmp_ok(scalar @differences, '==', 0, 'update_nodes should update properly the given XML document');
}


1;
