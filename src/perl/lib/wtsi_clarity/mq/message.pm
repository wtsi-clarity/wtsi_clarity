package wtsi_clarity::mq::message;

use Moose;
use Readonly;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Storage;
use Carp;
use List::MoreUtils qw/any/;

use wtsi_clarity::util::config;

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

our $VERSION = '0.0';

subtype 'WtsiClarityTimestamp'
      => as 'Str';

subtype 'WtsiClarityDateTime'
      => as 'DateTime';

coerce 'WtsiClarityTimestamp',
       from 'WtsiClarityDateTime',
       via { $_->strftime('%a %b %d %Y %T') };

Readonly::Scalar my $MESSAGE_PATH => q{wtsi_clarity::mq::message_types::%s_message};

has 'process_url' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'step_url' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'timestamp' => (
  isa      => 'WtsiClarityTimestamp',
  is       => 'ro',
  required => 1,
  coerce   => 1,
);

sub create {
  my ($message_type, %args) = @_;
  return $message_type->new(%args);
}

sub defrost {
  my ($message_type, $message) = @_;
  return $message_type->thaw($message);
}

around ['create', 'defrost'] => sub {
  my $orig         = shift;
  my $self         = shift;
  my $message_type = shift;

  # TODO: Make the config module a singleton (or something)...
  my $config = wtsi_clarity::util::config->new();
  my @valid_message_types = values $config->message_queues;

  if (!_message_type_is_valid($message_type, @valid_message_types)) {
    croak 'Message type must be one of the following: ' . join q{,}, @valid_message_types;
  }

  my $message = _get_message_module($message_type);

  return $orig->($message, @_);
};

sub _get_message_module {
  my $message_type = shift;
  my $module       = sprintf $MESSAGE_PATH, $message_type;

  my $loaded = eval "require $module";

  if (!$loaded) {
    croak "The required package: $module does not exist";
  }

  return $module;
}

sub _message_type_is_valid {
  my ($routing_key, @message_types) = @_;
  return (any { $_ eq $routing_key } @message_types) ? 1 : undef;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::message

=head1 SYNOPSIS

  my $m = wtsi_clarity::mq::message->new(
      process_url => 'some',
      step_url    => 'other',
      step_start  => 1,
      timestamp   => DateTime->now(),
  );
  print $m->timestamp; # prints a formatted string

  $m = wtsi_clarity::mq::message->new(
      process_url => 'some',
      step_url    => 'other',
      step_start  => 1,
      timestamp   => 'some time',
  );
  print $m->timestamp; # prints "some time"


=head1 DESCRIPTION

  A serializable to json wrapper for messages from clarity epp
  scripts.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 step_url - required attribute

=head2 step_start - required boolean attribute

=head2 timestamp - required attribute, can be given either
  as DateTime objest or a string

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Moose::Util::TypeConstraints

=item MooseX::StrictConstructor

=item MooseX::Storage

=item namespace::autoclean

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
