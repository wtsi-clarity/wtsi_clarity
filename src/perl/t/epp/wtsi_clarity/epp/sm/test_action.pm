# Dummy action class for testing
package wtsi_clarity::epp::sm::test_action;

use Moose;
use Carp;
use Getopt::Long qw(:config pass_through);

extends 'wtsi_clarity::epp';

with 'MooseX::Getopt';

override 'run' => sub {
  my $self= shift;
  $self->epp_log('Run method from '. ref $self);
};

1;
