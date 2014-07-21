# Dummy action class for testing
package wtsi_clarity::epp::sm::test_action3;

use strict;
use warnings;
use Moose;

extends 'wtsi_clarity::epp::sm::test_action';

has 'test_action3_attr' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

override 'run' => sub {
  my $self= shift;
  my $message = 'Run method from '. ref $self;
  $self->epp_log( $message 
    . 'test_action3_attr attribute value is '. $self->test_action3_attr
  );
};

1;
