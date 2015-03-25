use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Test::Warn;
use Test::MockObject::Extends;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Cwd;
use Carp;
use XML::SemanticDiff;

my $dir = tempdir( CLEANUP => 1);
my $in_up_extension = 'robot_in.CSV';
my $in_low_extension = 'robot_in.csv';
my $out = 'robot_out.csv';
my $file = catfile($dir, $in_up_extension);
`touch $file`;


# load the original test config file
local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
# local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = '/t/data/epp/sm/volume_checker';
use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

sub _write_config {
  my $robot_dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak "Cannot open file $file for writing";
  print $fh "[robot_file_dir]\n";
  print $fh "sm_volume_check=$robot_dir\n";
  print $fh "[clarity_api]\n";
  print $fh "base_uri = $base_uri\n";
  close $fh or carp "Cannot close file $file";
}

use_ok('wtsi_clarity::epp::sm::volume_checker');

my $current = cwd;
{
  my $epp = wtsi_clarity::epp::sm::volume_checker->new(
    process_url => 'http://some.com/process/XM4567', output => 'out');
  isa_ok( $epp, 'wtsi_clarity::epp::sm::volume_checker');
  is ($epp->input, $epp->output, 'input built from output');
}

{
  _write_config($dir);

  local $ENV{'WTSI_CLARITY_HOME'} = $dir;
  my $working = catfile $dir, 'working';
  mkdir $working;
  chdir $working;

  local $ENV{http_proxy} = 'http://my';
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $current . '/t/data/epp/sm/volume_checker';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  use wtsi_clarity::util::request;
  my $r = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $r->mock(q(put), sub{my ($self, $uri, $content) = @_; return $content;});

  my $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => $base_uri . '/processes/24-17469',
    input       => $in_low_extension,
    output      => $out,
  );
  is ($epp->robot_file, $file, 'robot file located correctly');
  throws_ok { $epp->run }  qr/Well location A:1 does not exist in volume check file/,
    'well is missing in an empty robot file';

  my $f = join q[/], $current, 't/data/epp/sm/volume_checker/test_1.CSV';
  my $command = "cp $f $dir/$in_up_extension";
  `$command`;

  $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => $base_uri . '/processes/24-17469',
    input       => $in_low_extension,
    output      => $out,
  );
  warning_like { $epp->run }
  qr/Run method is called for class wtsi_clarity::epp::sm::volume_checker, process/,
  'callback runs OK, logs process details';

  chdir $current;
  ok(-e catfile($working, $out), 'robot file has been copied');
}

{ # check if the analyte artifact has been updated correctly with the given volume
  local $ENV{'WTSI_CLARITY_HOME'} = $dir;

  use wtsi_clarity::util::request;
  my $r = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $r->mock(q(put), sub{my ($self, $uri, $content) = @_; return $content;});

  my $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => $base_uri . '/processes/24-17469',
    input       => $in_low_extension,
    output      => $out,
  );

  my $analyte_uri = 'http://testserver.com:1234/here/artifacts/2-44548?state=19798';
  my $original_analyte_file = q{original_analyte_without_volume.xml};
  my $updated_analyte_with_volume_file = q{updated_analyte_with_volume.xml};
  my $testdata_dir  = q{/t/data/epp/sm/volume_checker/};
  my $original_analyte_doc =
    XML::LibXML->load_xml(location => cwd . $testdata_dir . $original_analyte_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $original_analyte_file ;
  my $new_volume  = 123;

  my $updated_analyte_doc = $epp->_update_artifact_with_volume($analyte_uri, $original_analyte_doc, $new_volume, "Volume");

  my $expected_updated_analyte_with_volume_doc =
    XML::LibXML->load_xml(location => cwd . $testdata_dir . $updated_analyte_with_volume_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $updated_analyte_with_volume_file ;

  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($updated_analyte_doc, $expected_updated_analyte_with_volume_doc);
  cmp_ok(scalar @differences, '==', 0, 'Updated analyte with volume UDF tag correctly');
}

{ # check if the sample artifact has been updated correctly with the given volume
  local $ENV{'WTSI_CLARITY_HOME'} = $dir;

  use wtsi_clarity::util::request;
  my $r = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $r->mock(q(put), sub{my ($self, $uri, $content) = @_; return $content;});

  my $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => $base_uri . '/processes/24-17469',
    input       => $in_low_extension,
    output      => $out,
  );

  my $sample_uri = 'http://testserver.com:1234/here/artifacts/2-44548?state=19798';
  my $original_sample_file = q{original_sample_without_volume.xml};
  my $updated_sample_with_volume_file = q{updated_sample_with_volume.xml};
  my $testdata_dir  = q{/t/data/epp/sm/volume_checker/};
  my $original_sample_doc =
    XML::LibXML->load_xml(location => cwd . $testdata_dir . $original_sample_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $original_sample_file ;
  my $new_volume  = 123;

  my $updated_sample_doc = $epp->_update_artifact_with_volume($sample_uri, $original_sample_doc, $new_volume, "WTSI Working Volume (µL) (SM)");

  my $expected_updated_sample_with_volume_doc =
    XML::LibXML->load_xml(location => cwd . $testdata_dir . $updated_sample_with_volume_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $updated_sample_with_volume_file ;

  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($updated_sample_doc, $expected_updated_sample_with_volume_doc);
  cmp_ok(scalar @differences, '==', 0, 'Updated sample with volume UDF tag correctly');
}

1;
