use strict;
use warnings;

use Test::More tests => 5;

use_ok('wtsi_clarity::util::string');
can_ok('wtsi_clarity::util::string', qw/trim/);

{
  is(wtsi_clarity::util::string::trim(' asdf  '), 'asdf', 'Successfully trims a string with whitespace leading and trailing');
  is(wtsi_clarity::util::string::trim('asdf  '), 'asdf', 'Successfully trims a string with whitespace leading');
  is(wtsi_clarity::util::string::trim(' asdf'), 'asdf', 'Successfully trims a string with whitespace trailing');
}