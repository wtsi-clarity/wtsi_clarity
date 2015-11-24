package wtsi_clarity::mq::mh::unified_message_handler;

use Moose;
use Carp;
use JSON;
use Encode;

with 'wtsi_clarity::mq::mh::warehouse_message_handler_interface';

our $VERSION = '0.0';

has 'warehouse_type' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{unified},
);

1;

__END__

=head1 NAME

wtsi_clarity::mq::mh::unified_message_handler

=head1 SYNOPSIS

  my $message_handler = wtsi_clarity::mq::mh::unified_message_handler->new();
  $message_handler->process_message($json_string);

=head1 DESCRIPTION

 Handles messages coming off RabbitMQ. Dispatches them to relevant message enhancer.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::mq::message

=item wtsi_clarity::mq::mapper

=item wtsi_clarity::mq::client

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
