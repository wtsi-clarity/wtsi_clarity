use strict;
use warnings;
use Test::More tests => 5;
use File::Temp qw/ tempdir /;
use File::Spec::Functions;
use Carp;

use_ok('wtsi_clarity::epp::sm::fluidigm_analysis', 'can use wtsi_clarity::epp::sm::fluidigm_analysis');
my $test_dir = 't/data/sm/fluidigm_analysis';

sub _write_config {
  my $dir = shift;
  my $file = catfile $dir, 'config';
  open my $fh, '>', $file or croak "Cannot open file $file for writing";
  print $fh "[robot_file_dir]\n";
  print $fh "fluidigm_analysis=$dir\n";
  close $fh or carp "Cannot close file $file";
}

{
  my $epp = wtsi_clarity::epp::sm::fluidigm_analysis->new(process_url => 'http://clarity.co');
  isa_ok($epp, 'wtsi_clarity::epp::sm::fluidigm_analysis');
  can_ok($epp, qw/ run /);
}

# _filename
{
  my $epp = wtsi_clarity::epp::sm::fluidigm_analysis->new(
    process_url => 'http://clartiy-ap/processes/24-16130'
  );

  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;

  is($epp->_filename, '5345895674125', 'Gets the barcode of the container i.e. the filename');
}

# _filepath
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  local $ENV{'WTSI_CLARITY_HOME'} = 't/data/config';

  my $epp = wtsi_clarity::epp::sm::fluidigm_analysis->new(
    process_url => 'http://clartiy-ap/processes/24-16130'
  );

  is($epp->_get_filepath, '/fake/dir/5345895674125', 'Successfully gets the right filepath');
}