package wtsi_clarity::mq::messages::packer;

use Moose::Role;

our $VERSION = '0.0';

requires 'pack';

around 'pack' => sub {
  my $orig = shift;
  my $self = shift;

  my $message = $self->$orig();
  delete $message->{'__CLASS__'};

  return $message;
};

1;

__END__

=head1 NAME

wtsi_clarity::mq::messages::packer

=head1 SYNOPSIS

  package wtsi_clarity::mq::messages::flowcell;

  with Storage;
  with 'wtsi_clarity::mq::messages::packer';

  __PACKAGE__->pack();

=head1 DESCRIPTION

  When you call 'pack' from the Storage role, the object includes an attribute called '__CLASS__', whose
  value is package name of the package being packed. This role removes that attribute when 'pack' is called
  (because we don't want that attribute being send to the Warehosue Builder).

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

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
