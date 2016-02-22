#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  use_ok('WWW::Clarity');

  my $clarity;

  lives_ok {
      $clarity = WWW::Clarity->new(
        username => 'testuser',
        password => 'testpass',
      )
    } 'Instanciates okay.';

  lives_ok {
      $clarity->request
    } 'Can make a request object.';
}

done_testing();

