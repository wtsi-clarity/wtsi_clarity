use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;
use File::Temp qw/ tempdir /;

use_ok('wtsi_clarity::util::config');

my $chome_name = 'WTSI_CLARITY_HOME';
{
  my $c = wtsi_clarity::util::config->new();
  isa_ok( $c, 'wtsi_clarity::util::config');
  
  is($c->wtsi_clarity_home_var_name, $chome_name, 'homa var name from object instance');
  is(wtsi_clarity::util::config->wtsi_clarity_home_var_name, $chome_name, 'home var name called on package name');

  #unset the env vars within this scope in case they are set in caller's environment
  local $ENV{'HOME'} = q[];
  local $ENV{$chome_name} = q[];
  
  throws_ok {$c->dir_path}
    qr/cannot find location of the wtsi_clarity project configuration directory/,
    'error if none of the variables defining the location of config directory is set';
  
  local $ENV{$chome_name}= q[/somedir];
  throws_ok {$c->dir_path}
    qr/Validation failed for 'WtsiClarityDirectory'/,
    'error when config directory does not exist';
  local $ENV{$chome_name}= q[t];
    throws_ok {$c->file}
    qr/Validation failed for 'WtsiClarityReadableFile'/,
    'error when config file does not exist';

  local $ENV{$chome_name}= q[t/data/config];
  #get new instance, since dir_path has been already built for the prev instance
  $c = wtsi_clarity::util::config->new();
  my $path;
  lives_ok {$path = $c->file} 'config file is found';
  is($path, 't/data/config/config', 'config path is correct');

  my $dir = tempdir( CLEANUP => 1);
  my $conf_dir = join q[/], $dir, q[.wtsi_clarity];
  mkdir $conf_dir;
  my $conf_file = join q[/], $conf_dir, q[config];
  `touch $conf_file`;

  local $ENV{$chome_name}= q[];
  local $ENV{'HOME'} = $dir;
  $c = wtsi_clarity::util::config->new();
  is($c->dir_path, $conf_dir, 'wtsi clarity conf directory is found in the home directory');
  is($c->file, $conf_file, 'conf file is found');
}

{
  local $ENV{$chome_name}= q[t/data/config];
  my $c = wtsi_clarity::util::config->new();

  throws_ok {$c->some_mq} qr/Can't locate object method "some_mq" /, 'error calling non-existing attribute';

  foreach my $method (qw/clarity_api clarity_mq warehouse_mq/) {
    lives_and {is ref($c->$method), 'HASH'} "$method returns a hash ref";
  }
}

1;