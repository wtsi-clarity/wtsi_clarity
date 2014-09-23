use strict;
use warnings;
use Test::Exception;
use Test::More tests => 5;

use wtsi_clarity::util::error_reporter qw/croak/;

{
  my $error = qq{(some code:) - error line 1
(some code:) - error line 2
(some code:) - error line 3
(some code:) - error line 4};
  my $expected = qq{(some code:) - error line 1 . . . . (some code:) - error line 2 . . . . (some code:) - error line 3 . . . . (some code:) - error line 4};

  my $msg = wtsi_clarity::util::error_reporter::_make_long_format_error($error);

  cmp_ok($msg, 'eq', $expected, q/_make_long_format_error should return the correct format/);
}

{
  my $error = qq{(some code:) - error line 1};
  my $expected = qq{(some code:) - error line 1};

  my $msg = wtsi_clarity::util::error_reporter::_make_long_format_error($error);

  cmp_ok($msg, 'eq', $expected, q/_make_long_format_error should return the correct format/);
}

{
  my $error = qq{(some code:) - error line 1
(some code:) - error line 2
(some code:) - error line 3
(some code:) - error line 4};
  my $expected = qq{(some code:) - error line 4};

  my $msg = wtsi_clarity::util::error_reporter::_make_short_format_error($error);

  cmp_ok($msg, 'eq', $expected, q/_make_short_format_error should return the correct format/);
}

{
  throws_ok { wtsi_clarity::util::error_reporter::croak("hello") } qr/\[ERROR\]: Please contact support. Error detail: hello/, "croak should return the correct error.";
}

{
  throws_ok { wtsi_clarity::util::error_reporter::croak_with_stack("hello\nhello") } qr/\[ERROR\]: hello/, "croak_with_stack should return ONE line with the \\n replaced.";
}

1;
