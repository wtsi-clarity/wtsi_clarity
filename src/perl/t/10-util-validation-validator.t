use strict;
use warnings;

use Test::More tests => 14;

use_ok('wtsi_clarity::util::validation::validator');

{
  my $validation = wtsi_clarity::util::validation::validator->new(value => 1);
  isa_ok($validation, 'wtsi_clarity::util::validation::validator');

  # Check they chain properly
  isa_ok($validation->has_length(3), 'wtsi_clarity::util::validation::validator');
  isa_ok($validation->is_integer(), 'wtsi_clarity::util::validation::validator');
}

{
  my $validation = wtsi_clarity::util::validation::validator->new(value => 1);
  isa_ok($validation, 'wtsi_clarity::util::validation::validator');

  is(scalar @{$validation->_validators}, 0, '_validators should be empty');
  is(scalar @{$validation->_errors},     0, '_errors should be empty');

  $validation->has_length(1);
  is(scalar @{$validation->_validators}, 1, '_validators should contain one validator');

  $validation->is_integer();
  is(scalar @{$validation->_validators}, 2, '_validators should now contain two validators');

  isa_ok($validation->result(), 'wtsi_clarity::util::validation::result');

  is(scalar @{$validation->_validators}, 0, '_validators should be empty after result is called');
  is(scalar @{$validation->_errors},     0, '_errors should be empty after result is called');

  $validation->has_length(99);

  is(scalar @{$validation->_validators}, 1, '_validators should have one validator again');
  is(scalar @{$validation->_errors}, 1, '_errors should have one error');
}

1;