# Dummy action class for testing
package wtsi_clarity::epp::sm::test_action2;

use Moose;
use Carp;
use Getopt::Long qw(:config pass_through);

extends 'wtsi_clarity::epp';

with 'MooseX::Getopt';

1;
