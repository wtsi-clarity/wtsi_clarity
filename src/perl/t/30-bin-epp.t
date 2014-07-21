use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw/ tempdir /;
use File::Copy;
use File::Copy::Recursive qw/ dircopy/;
use Cwd;
use Test::Warn;

# Copy all the files what needed to the test to a temporary dir
# These files will be deleted after the execution of this script.

my $dir = tempdir( CLEANUP => 1);

my $current= cwd;

my @dirs_to_create = ("$dir/lib/wtsi_clarity",
                      "$dir/lib/wtsi_clarity/util",
                      "$dir/bin");

my @additional_files_to_copy = (
  'wtsi_clarity/epp.pm',
  'wtsi_clarity/util/config.pm',
  'wtsi_clarity/util/request.pm',
  'wtsi_clarity/util/types.pm',
);

foreach my $dir_to_create (@dirs_to_create) {
  mkdir $dir_to_create;
}
my $source_wtsi = join q[/], $current, 't/epp/wtsi_clarity';
my $source_bin = join q[/], $current, 'bin';
dircopy($source_wtsi, $dirs_to_create[0]);
dircopy($source_bin, $dirs_to_create[2]);

foreach my $file (@additional_files_to_copy) {
  my $source = join q[/], $current, 'lib', $file;
  my $target = join q[/], $dir, 'lib', $file;
  copy $source, $target;
}


{
  system("$dir/bin/epp --action test_action1 --process_url dummy_url 2>$dir/lib/stderr.txt");
  open (my $fh, "<", "$dir/lib/stderr.txt");
  my $stderr;
  chomp($stderr = <$fh>);
  is( $stderr,
      "Run method from wtsi_clarity::epp::sm::test_action1",
      'callback runs OK, logs process details'
    );
  close($fh);
}

{
  system("$dir/bin/epp --action test_action1 --action test_action2 --process_url dummy_url 2>$dir/lib/stderr.txt");
  open (my $fh, "<", "$dir/lib/stderr.txt");
  my $stderr = "";
  while(my $line = <$fh>) {
    chomp($line);
    $stderr = $stderr . $line;
  }
  is( $stderr,
      "Run method from wtsi_clarity::epp::sm::test_action1".
      "Run method from wtsi_clarity::epp::sm::test_action2",
      'callback runs OK, logs process details'
    );
  close($fh);
}

{
  system("$dir/bin/epp --action test_action1 --action test_action3 --process_url dummy_url --test_action3_attr test_action3_attr_value 2>$dir/lib/stderr.txt");
  open (my $fh, "<", "$dir/lib/stderr.txt");
  my $stderr = "";
  while(my $line = <$fh>) {
    chomp($line);
    $stderr = $stderr . $line;
  }
  is( $stderr,
      "Run method from wtsi_clarity::epp::sm::test_action1".
      "Run method from wtsi_clarity::epp::sm::test_action3".
      "test_action3_attr attribute value is test_action3_attr_value",
      'callback runs OK, logs process details'
    );
  close($fh);
}

1;
