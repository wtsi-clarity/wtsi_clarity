use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Carp;

my $dir = tempdir( CLEANUP => 1);

sub _write_config {
  my $robot_dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak "Cannot open file $file for writing";
  print $fh "[robot_file_dir]\n";
  print $fh "sm_pico_green=$robot_dir\n";
  close $fh or carp "Cannot close file $file";
}

use_ok('wtsi_clarity::epp::sm::attach_dtx_file');

{
  _write_config($dir);

  my $test_dir = 't/data/sm/attach_dtx_file';
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  local $ENV{'WTSI_CLARITY_HOME'} = $dir;

  my $epp = wtsi_clarity::epp::sm::attach_dtx_file->new(
    process_url => 'http://some.com/processes/24-3053'
  );

  isa_ok( $epp, 'wtsi_clarity::epp::sm::attach_dtx_file');

  is($epp->_standard_barcode, '1234', 'Gets the standard barcode correctly');
  is($epp->_container_barcode, '5260027344708', 'Gets the container barcode correctly');
  is($epp->_file_prefix, '1234-5260027344708', 'Creates the correct file prefix');
  
  my $file_name = '1234-5260027344708_ Pico-green assay run_AllRawData_06-06-2014_10.32.21.68.xml';
  (my $escaped_file_name = $file_name) =~ s/\s/\\ /g;
  
  my $command = "cp $test_dir/$escaped_file_name $dir/$escaped_file_name";
  `$command`;

  is($epp->_get_dtx_file(), "$dir/$file_name", 'finds the file no problem');
}

1;