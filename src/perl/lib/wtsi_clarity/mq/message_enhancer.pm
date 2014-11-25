package wtsi_clarity::mq::message_enhancer;

use Moose;

our $VERSION = '0.0';

has 'process_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'timestamp' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

sub publish {
  my ($self, $message) = @_;

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::message_enhancer

=head1 SYNOPSIS

  my $message_enhancer = wtsi_clarity::mq::message_enhancer->new();
  $message_enhancer->publish('message');

=head1 DESCRIPTION

 Base class of the message producers, which are publishing messages to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 publish

  Takes in the message string and publish it onto the unified warehouse message bus.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL

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
