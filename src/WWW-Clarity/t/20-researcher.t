#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use WWW::Clarity;
use WWW::Clarity::Mocks::MockRequest;

BEGIN {
  my $mock_request = WWW::Clarity::Mocks::MockRequest->new(
    username => 'testuser',
    password => 'testpass',
  );
  my $clarity = WWW::Clarity->new(
    username => 'testuser',
    password => 'testpass',
    request  => $mock_request,
  );
  my $uri = 'http://web-claritytest-01.internal.sanger.ac.uk:8080/api/v2/researchers/555';
  my $researcher = $clarity->get_researcher($uri);

  isa_ok($researcher, 'WWW::Clarity::Models::Researcher', 'Object returned by Clarity');

  is($researcher->get_first_name, 'Ronan', 'Has correct first name.');
  is($researcher->get_last_name, 'Forman', 'Has correct last name.');
  is($researcher->get_email, 'rf9@sanger.ac.uk', 'Has correct email.');
  is($researcher->get_user_name, 'rf9', 'Has correct username.');

  is($researcher->get_full_name, 'Ronan Forman', 'Builds correct full name.');

  $researcher->set_first_name('Fake');
  is($researcher->get_first_name, 'Fake', 'Sets first name correctly.');

  $researcher->save();

  my $new_researcher = $clarity->get_researcher($uri);
  is($new_researcher->get_first_name, 'Fake', 'Updated the api.');

  $new_researcher->set_first_name('Ronan')->save();

  is($researcher->get_first_name, 'Fake', 'Still has changed value.');
  $researcher->refresh();
  is($researcher->get_first_name, 'Ronan', 'Reverts to stored value on refresh.');
}

done_testing();
