package wtsi_clarity::epp::generic::messenger;

use Moose;
use DateTime;

use wtsi_clarity::mq::client;
use wtsi_clarity::mq::message;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'purpose' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

has '_date' => (
  isa        => 'DateTime',
  is         => 'ro',
  required   => 0,
  default    => sub { return DateTime->now(); },
);

has '_message' => (
  isa        => 'wtsi_clarity::mq::message',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__message {
  my $self = shift;
  return wtsi_clarity::mq::message->new(
    process_url => $self->process_url,
    step_url    => $self->step_url,
    timestamp   => $self->_date,
    purpose     => $self->purpose,
  );
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  wtsi_clarity::mq::client->new()->send_message($self->_message->freeze);
  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::messenger

=head1 SYNOPSIS

=head1 DESCRIPTION

  An epp callback for sending a message (a serialized
  wtsi_clarity::mq::message object) to Rabbit MQ.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 step_url - required attribute

=head2 step_start - an optional boolean attribute, defaults to false

=head2 run - runs a callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item DateTime

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
