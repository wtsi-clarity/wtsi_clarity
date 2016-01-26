use strict;
use warnings;
use Test::More;
use Test::Exception;
use DateTime;
use Test::MockObject::Extends;

my $exit_code = system('ihelp > /dev/null 2>&1');

if ($exit_code != 0) {
  plan skip_all => 'iRODS icommands needs to be installed and they needs to be on the PATH.';
} else {
  plan tests => 23;
}

use_ok('wtsi_clarity::irods::irods_publisher');

{
  my $publisher = wtsi_clarity::irods::irods_publisher->new();
  isa_ok($publisher, 'wtsi_clarity::irods::irods_publisher');
}

my $data_path = 't/data/irods/irods_publisher';
my $test_file_name = 'test_file.txt';

my $file_to_put = "$data_path/$test_file_name";
my $destination_path = "$test_file_name";
my $long_destination_path = '27-15592.20160104155831.manifest.txt';
my $file_to_add_metadata = $destination_path;
my $file_to_remove = $destination_path;

my $overwrite = 1;

my @metadatum = (
  {
    "attribute" => "type",
    "value"     => "manifest.txt",
  },
  {
    "attribute" => "time",
    "value"     => DateTime->now(),
  }
);


{
  # add a file to iRODS
  my $publisher = wtsi_clarity::irods::irods_publisher->new();

  lives_ok {
    $exit_code = $publisher->_put($file_to_put, $destination_path, $overwrite)
  }
    'Successfully put file to iRODS.';
  is($exit_code, 0, "Successfully exited from the iput command.");
  lives_ok {
    $exit_code = $publisher->_add_metadata_to_file($file_to_add_metadata, @metadatum)
  }
    'Successfully add metadata to the file in iRODS.';
  is($exit_code, 0, "Successfully exited from the imeta command.");

  # cleanup
  lives_ok {
    $exit_code = $publisher->remove($file_to_remove)
  }
    'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

{
  my $publisher = Test::MockObject::Extends->new(
    wtsi_clarity::irods::irods_publisher->new()
  );

  lives_ok {
    $exit_code = $publisher->publish($file_to_put, $destination_path, $overwrite, @metadatum)
  } 'Successfully published the file into iRODS and added the metadata to it.';

  is($exit_code, 1, "Successfully exited from the iput and imeta commands.");
  is(length $publisher->md5_hash, 32, "Generated a hash");

  # cleanup
  lives_ok {
    $exit_code = $publisher->remove($file_to_remove)
  } 'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

{
  my $publisher = Test::MockObject::Extends->new(
    wtsi_clarity::irods::irods_publisher->new()
  );

  lives_ok {
    $exit_code = $publisher->publish($file_to_put, $long_destination_path, $overwrite, @metadatum)
  } 'Successfully published the file into iRODS and added the metadata to it.';

  is($exit_code, 1, "Successfully exited from the iput and imeta commands.");
  is(length $publisher->md5_hash, 32, "Generated a hash for a long file name");

  # cleanup
  lives_ok {
    $exit_code = $publisher->remove($long_destination_path)
  } 'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

{
  my $publisher = Test::MockObject::Extends->new(
    wtsi_clarity::irods::irods_publisher->new()
  )->mock(q(_save_hash), sub {
  });

  lives_ok {
    $exit_code = $publisher->publish($file_to_put, $destination_path, $overwrite, @metadatum)
  } 'Successfully published the file into iRODS and added the metadata to it without hash.';

  is($exit_code, 1, "Successfully exited from the iput and imeta commands without hash.");
  is($publisher->md5_hash, undef, "Left hash attribute as undef.");

  # cleanup
  lives_ok {
    $exit_code = $publisher->remove($file_to_remove)
  } 'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

1;