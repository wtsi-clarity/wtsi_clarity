use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use Test::Warn;
use Test::MockObject::Extends;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Carp;
use Cwd;

my $dir = tempdir( CLEANUP => 1);

# load the original test config file
local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
# local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = '/t/data/epp/sm/volume_checker';
use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

sub _write_config {
  my $robot_dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak  "Cannot open file $file for writing";
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
  my $in = 'robot_in.csv';
  my $out = 'robot_out.csv';
  my $file = catfile($dir, $in);
  `touch $file`;

  local $ENV{'WTSI_CLARITY_HOME'} = $dir;
  my $working = catfile $dir, 'working';
  mkdir $working;
  chdir $working;

  local $ENV{http_proxy} = 'http://my';
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $current . '/t/data/epp/sm/volume_checker';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

  use wtsi_clarity::util::request;
  my $r = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $r->mock(q(put), sub{my ($self, $uri, $content) = @_; return $content;});

  my $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-17469',
    input       => $in,
    output      => $out,
  );
  is ($epp->robot_file, $file, 'robot file located correctly');
  throws_ok { $epp->run }  qr/Well location A:1 does not exist in volume check file/,
    'well is missing in an empty robot file';

  my $f = join q[/], $current, 't/data/epp/sm/volume_checker/test_1.CSV';
  my $command = "cp $f $dir/$in";
  `$command`;

  $epp = wtsi_clarity::epp::sm::volume_checker->new(
    request     => $r,
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-17469',
    input       => $in,
    output      => $out,
  );
  warning_like { $epp->run }
  qr/Run method is called for class wtsi_clarity::epp::sm::volume_checker, process/,
  'callback runs OK, logs process details';

  chdir $current;
  ok(-e catfile($working, $out), 'robot file has been copied');
}

1;
