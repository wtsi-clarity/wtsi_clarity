package wtsi_clarity::mq::mh::message_handler_interface;

use Moose::Role;
use Carp;

use wtsi_clarity::mq::message;
use wtsi_clarity::mq::mapper;

requires 'process';

our $VERSION = '0.0';

has 'mapper' => (
  is        => 'ro',
  isa       => 'wtsi_clarity::mq::mapper',
  required  => 0,
  default   => sub { return wtsi_clarity::mq::mapper->new() },
);

around 'process' => sub {
  my ($orig, $self, %args) = @_;

  my $message = $self->_thaw(%args);
  my $package_name = $self->_find_enhancer_by_purpose($message->purpose);

  $self->_require_enhancer($package_name);

  return $self->$orig($message, $package_name);
};

sub _thaw {
  my ($self, %args) = @_;
  return wtsi_clarity::mq::message->defrost($args{'routing_key'}, $args{'message'});
}

sub _find_enhancer_by_purpose {
  my ($self, $purpose) = @_;
  return $self->mapper->package_name($purpose);
}

sub _require_enhancer {
  my ($self, $enhancer_name) = @_;
  my $loaded = eval "require $enhancer_name";
  if (!$loaded) {
    croak "The required package: $enhancer_name does not exist"
  }
  return 1;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::mh::message_handler_interface

=head1 SYNOPSIS

package wtsi_clarity::mq::mh::report_message_handler;

with 'wtsi_clarity::mq::mh::message_handler_interface';

sub process {
  my ($self, $message, $package_name) = @_;
  # ...
}

=head1 DESCRIPTION

 A Moose::Role to be used when creating message handlers. The role will ensure that a process
 method is present, using the "around" method modifier to automatically thaw the message (which
 comes off the queue as JSON), and find the correct package using that message. This message and
 package will then be passed through to the original process method.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item wtsi_clarity::mq::message

=item wtsi_clarity::mq::mapper

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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
