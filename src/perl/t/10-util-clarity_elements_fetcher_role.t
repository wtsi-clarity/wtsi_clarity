use strict;
use warnings;
use Test::More tests => 7;
use Cwd;
use XML::LibXML;


##################  start of test class ####################
package test::10_util_clarity_elements_fetcher_role_test_class;
use Moose;
use Carp;
use XML::LibXML;
use Readonly;

Readonly::Scalar my $OUTPUT_PATH          => q(/prc:process/input-output-map/output/@uri);
Readonly::Scalar my $PROCESS_PURPOSE_PATH => q(/prc:process/udf:field[@name="Plate Purpose"]);
Readonly::Scalar my $CONTAINER_PATH       => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $TARGET_NAME          => q(WTSI Container Purpose Name);

# we bypass clarity_element_fetcher, as we don't want to test it
# and want to control the behaviours usually activated by the run method
extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role';

sub get_targets_uri {
  return ( $OUTPUT_PATH, $CONTAINER_PATH );
};

sub update_one_target_data {
  my ($self, $targetDoc, $targetURI, $value) = @_;

  $self->set_udf_element_if_absent($targetDoc, $TARGET_NAME, $value);

  return $targetDoc->toString();
};

sub get_data {
  my ($self, $targetDoc, $targetURI) = @_;
  if ($targetURI eq 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7562'){
    return '7562';
  }
  if ($targetURI eq 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7563'){
    return '7563';
  }
};

no Moose;
##################  end of test class ####################
package main;
use lib qw ( t );
use util::xml;

# Run tests for adding volume element
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/element_fetcher';
  my $testInstance = test::10_util_clarity_elements_fetcher_role_test_class->new(
     process_url => q[http://clarity-ap:8080/api/v2/processes/24-99912],
  );

  $testInstance->fetch_and_update_targets($testInstance->process_doc);
  my $hash = $testInstance->_targets;
  cmp_ok(scalar keys %{$hash}, '==', 2, q/Should find 2 targets/);


  while (my ($targetURI, $targetDoc) = each %{$hash} ) {
    cmp_ok($targetURI, '~~', [ 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7562',
                               'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7563'],
                               'The keys of the target hash should be their URI.' );
    my @nodes = util::xml::find_elements ($targetDoc, q{/con:container/udf:field[@name="WTSI Container Purpose Name"]} );
    cmp_ok(scalar(@nodes), '==', 1, 'supplier udf tag should be created.');
    if ($targetURI eq 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7562'){
      cmp_ok($nodes[0]->textContent, 'eq', '7562', 'udf value should be correct.');
    }
    if ($targetURI eq 'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containers/27-7563'){
      cmp_ok($nodes[0]->textContent, 'eq', '7563', 'udf value should be correct.');
    }
  }

}

1;
