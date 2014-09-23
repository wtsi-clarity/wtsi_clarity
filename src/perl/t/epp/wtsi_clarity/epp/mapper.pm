package wtsi_clarity::epp::mapper;

use Moose;
use Carp;
use Readonly;
use Getopt::Long qw(:config pass_through);

with 'MooseX::Getopt';

our $VERSION = '0.0';

Readonly::Hash my %ACTION2MODULE => (
    'test_action1'        => 'sm::test_action1',
    'test_action2'        => 'sm::test_action2',
    'test_action3'        => 'sm::test_action3',
);

has 'action'  => (
    isa             => 'ArrayRef[Str]',
    is              => 'ro',
    required        => 1,
);

sub package_names {
  my $self = shift;
  my @package_names;
  foreach my $action (@{$self->action}) {
    if (!exists $ACTION2MODULE{$action}) {
      croak q[No callback for action ] . $action;
    }
    push @package_names, 'wtsi_clarity::epp::' . $ACTION2MODULE{$action};
  }
  return @package_names;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::mapper

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use wtsi_clarity::epp::mapper;
  # to get the package that handles the action
  my $package = wtsi_clarity::epp::mapper->new_with_options();

=head1 DESCRIPTION

 Maps actions as supplied on the epp script command line to modules
 implementing callbacks for these actions

=head1 SUBROUTINES/METHODS

=head2 action - required attribute

=head2 package_names - returns an array of packages that implements a callback for
 the provided actions

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Getopt

=item Getopt::Long

=item wtsi_clarity::util::error_reporter

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
