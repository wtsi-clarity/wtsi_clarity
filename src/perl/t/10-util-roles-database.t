use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use DBI;
use DateTime;
use Test::MockObject::Extends;
use Carp;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();

my $dsn = $config->database->{'dsn'};
my $user = $config->database->{'user'};
my $password = $config->database->{'pass'};
my $dbh = DBI->connect($dsn, $user, $password, {
  PrintError => 0,
  RaiseError => 1,
  AutoCommit => 1,
  FetchHashKeyName => 'NAME_lc',
});
eval {
  $dbh->do('DROP TABLE hash')
};
$dbh->do('CREATE TABLE hash (id integer PRIMARY KEY AUTOINCREMENT, filename varchar, hash varchar, location varchar, uploaded_at DEFAULT CURRENT_TIMESTAMP)');

{
  my $filename = "test_file_name";
  my $hash = "test_hash";
  my $location = "test_location";

  my $database = Moose::Meta::Class->create(
    'New::Class',
    roles => [qw/wtsi_clarity::util::roles::database/],
  )->new_object(process_url => 'unimportant');

  lives_ok {
    $database->insert_hash_to_database($filename, $hash, $location);
  } "Inserts into the database without crashing.";

  my $sth = $dbh->prepare('SELECT filename, hash, location, uploaded_at FROM hash');
  $sth->execute();

  my $count = 0;
  while(my $ref = $sth->fetchrow_hashref()) {
    is($ref->{'filename'}, $filename, "Filename correct");
    is($ref->{'hash'}, $hash, "Hash correct");
    is($ref->{'location'}, $location, "Location correct");

    $count++;
  }

  is($count, 1, "Correct number of rows added");
}

$dbh->disconnect();
unlink "test.db";

{
  my $database = Test::MockObject::Extends->new(
    Moose::Meta::Class->create(
      'New::Class',
      roles => [qw/wtsi_clarity::util::roles::database/],
    )->new_object(process_url => 'unimportant')
  )->mock(q(_build_database), sub {
    croak 'Pointlessly opens database';
  });

  lives_ok {
    $database->DEMOLISH()
  } 'Database is only made when needed.'
}

1;
