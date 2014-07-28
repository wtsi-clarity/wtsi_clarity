package wtsi_clarity::mq::message::epp;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;
use MooseX::Storage;

use wtsi_clarity::util::types;

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

has 'step_start' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 1,
);

has 'timestamp' => (
  isa        => 'WtsiClarityTimestamp',
  is         => 'ro',
  required   => 1,
  coerce     => 1,
);

1;

__END__

=head1 NAME

wtsi_clarity::mq::message::epp

=head1 SYNOPSIS

  my $m = wtsi_clarity::mq::message::epp->new(
      process_url => 'some',
      step_url    => 'other',
      step_start  => 1,
      timestamp   => DateTime->now(),
  );
  print $m->timestamp; prints a formatted string

  $m = wtsi_clarity::mq::message::epp->new(
      process_url => 'some',
      step_url    => 'other',
      step_start  => 1,
      timestamp   => 'some time',
  );
  print $m->timestamp; prints "some time"
 

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
