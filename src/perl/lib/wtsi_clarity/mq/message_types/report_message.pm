package wtsi_clarity::mq::message_types::report_message;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.0';

extends 'wtsi_clarity::mq::message';

enum 'WtsiClarityMqReportPurpose', [qw( 14MG_sample_manifest )];

has 'purpose' => (
  isa       => 'WtsiClarityMqReportPurpose',
  is        => 'ro',
  required  => 1,
);

has 'publish_to_irods' => (
  isa       => 'Bool',
  is        => 'ro',
  required  => 1,
  default   => 1,
);

1;

__END__

=head1 NAME

wtsi_clarity::mq::message_types::report_message

=head1 SYNOPSIS

  my $m = wtsi_clarity::mq::message_types::report_message->new(
      process_url => 'some',
      step_url    => 'other',
      step_start  => 1,
      timestamp   => DateTime->now(),
      purpose     => '14MG_sample_manifest'
  );
  print $m->timestamp; # prints a formatted string

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

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
