use strict;
use warnings;

use Test::More tests => 5;

use_ok('wtsi_clarity::util::validation');

{
  my $validation = wtsi_clarity::util::validation->new(value => 1);
  isa_ok($validation, 'wtsi_clarity::util::validation');
  is($validation->failed, 0, 'False when no error messages are present');
}

{
  my $validation = wtsi_clarity::util::validation->new(
    errors => [
      'Here is error number one',
      'Here is error number two',
    ],
    value => '83'
  );

  is($validation->failed, 1, 'True when error messages are present');

  is($validation->error_message, 'Validation for value 83 failed. Here is error number one. Here is error number two.',
    'Provides a lovely string with all the error messages');
}

1;