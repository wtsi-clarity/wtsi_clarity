package wtsi_clarity::util::validation::result;

use Moose;

our $VERSION = '0.0';

has '_errors' => (
  isa      => 'ArrayRef',
  is       => 'ro',
  init_arg => 'errors',
  required => 0,
  default  => sub { [] },
);

has '_value' => (
  isa      => 'Any',
  is       => 'ro',
  init_arg => 'value',
  required => 1,
);

sub failed {
  my $self = shift;
  return (scalar @{$self->_errors} == 0) ? 0 : 1;
}

sub error_message {
  my $self = shift;
  my $message = q{};

  if ($self->failed) {
    $message = 'Validation for value ' . $self->_value . ' failed. ';
    $message .= join(q{. }, @{$self->_errors}) . q{.};
  }

  return $message;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::validation::result

=head1 SYNOPSIS

use wtsi_clarity::util::validation::result;

my $validation = wtsi_clarity::util::validation::result->new(
  value  => '1234aaa',
  errors => ['Barcode too short', 'Barcode not an integer']
);

if ($validation->failed) {
  print $validation->error_message;
}

=head1 DESCRIPTION

A simple class to provide a nice interface for error messages

=head1 SUBROUTINES/METHODS

=head2 failed
  Returns 1 if there are any errors, returns 0 otherwise

=head2 error_message
  Stringifies all the errors into one error message

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL by Chris Smith

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
