package wtsi_clarity::mq::message_handler;

use Moose;
use Carp;

use wtsi_clarity::mq::message;
use wtsi_clarity::mq::mapper;

our $VERSION = '0.0';

has 'mapper' => (
  is        => 'ro',
  isa       => 'wtsi_clarity::mq::mapper',
  required  => 0,
  default   => sub { return wtsi_clarity::mq::mapper->new() },
);

sub process_message {
  my ($self, $json_string) = @_;
  my $message = $self->_thaw($json_string);
  my $package_name = $self->_find_enhancer_by_purpose($message->purpose);

  $self->_require_enhancer($package_name);

  $self->_prepare_messages($package_name, $message);

  return 1;
}

sub _prepare_messages {
  my ($self, $package_name, $message) = @_;

  return $package_name->new(
            process_url => $message->process_url,
            step_url    => $message->step_url,
            timestamp   => $message->timestamp,
          )->prepare_messages();
}

sub _thaw {
  my ($self, $json_string) = @_;
  return wtsi_clarity::mq::message->thaw($json_string);
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

wtsi_clarity::mq::message_handler

=head1 SYNOPSIS

  my $message_handler = wtsi_clarity::mq::message_handler->new();
  $message_handler->process_message($json_string);

=head1 DESCRIPTION

 Handles messages coming off RabbitMQ. Dispatches them to relevant message enhancer.

=head1 SUBROUTINES/METHODS

=head2 process_message

  Takes in JSON string. Converts to mq::message, and dispatches to relevant message enhancer.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::mq::message

=item wtsi_clarity::mq::mapper

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
