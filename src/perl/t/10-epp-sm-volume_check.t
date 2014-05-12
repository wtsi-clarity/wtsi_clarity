use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Carp;
use Cwd;

my $dir = tempdir( CLEANUP => 1);

sub _write_config {
  my $robot_dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak "Cannot open file $file for writing";
  print $fh "[robot_file_dir]\n";
  print $fh "sm_volume_check=$robot_dir\n";
  close $fh or carp "Cannot close file $file";
}

use_ok('wtsi_clarity::epp::sm::volume_check');

my $current = cwd;
{
  my $epp = wtsi_clarity::epp::sm::volume_check->new(
    process_url => 'http://some.com/process/XM4567', output => 'out');
  isa_ok( $epp, 'wtsi_clarity::epp::sm::volume_check');
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
  my $epp = wtsi_clarity::epp::sm::volume_check->new(
    process_url => 'http://some.com/process/XM4567', input => $in,  output => $out);
  is ($epp->robot_file, $file, 'robot file located correctly');

#  lives_ok {$epp->run} 'execute callback';
   chdir $current;
#  ok(-e catfile($working, $out), 'robot file has been copied');
}

1;
