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
  plan tests => 13;
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

  my $exit_code;

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
  $publisher->mock(q(insert_hash_to_database), sub {
    my ($self, $filename, $hash, $location) = @_;
    is(length $hash, 32, "A hash is generated.");
  });

  my $exit_code;

  lives_ok {
    $exit_code = $publisher->publish($file_to_put, $destination_path, $overwrite, @metadatum)
  }
    'Successfully published the file into iRODS and added the metadata to it.';

  is($exit_code, 1, "Successfully exited from the iput and imeta commands.");

  # cleanup
  lives_ok {
    $exit_code = $publisher->remove($file_to_remove)
  }
    'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

1;