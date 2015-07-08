package wtsi_clarity::util::validation::validator;

use Moose;
use Moose::Util::TypeConstraints;
use List::Util qw/reduce/;
use wtsi_clarity::util::validation::predicates;
use wtsi_clarity::util::validation::result;

our $VERSION = '0.0';

subtype 'ValidationObject'
  => as 'HashRef'
  => where {
    exists $_->{'check'} && ref $_->{'check'} eq 'CODE' && exists $_->{'message'};
  };

has '_value' => (
  is       => 'ro',
  isa      => 'Any',
  required => 1,
  init_arg => 'value',
);

has '_validators' => (
  is       => 'ro',
  isa      => 'ArrayRef[ValidationObject]',
  traits   => [qw/Array/],
  init_arg => undef,
  lazy     => 1,
  default  => sub { [] },
  handles  => {
    _add_validator => 'push',
  },
  clearer  => '_clear_validators',
);

around '_add_validator' => sub {
  my $orig = shift;
  my $self = shift;
  $self->$orig(_validation_object(@_));
  return $self;
};

after 'result' => sub {
  my $self = shift;
  $self->_clear_validators;
};

sub result {
  my $self = shift;
  return wtsi_clarity::util::validation::result->new(value => $self->_value, errors => $self->_errors);
}

sub has_length {
  my ($self, $length, $message) = @_;
  $message = $message // 'The barcode must have a length of ' . $length;
  $self->_add_validator(wtsi_clarity::util::validation::predicates::has_length_of($length), $message);
  return $self;
}

sub is_integer {
  my $self    = shift;
  my $message = shift // 'The barcode must be numeric';
  $self->_add_validator(wtsi_clarity::util::validation::predicates::is_integer(), $message);
  return $self;
}

sub _validation_object {
  my ($check, $message) = @_;
  return { check => $check, message => $message, };
}

sub _errors {
  my $self = shift;

  my $errors = reduce {
    if (!$b->{'check'}->($self->_value)) {
      push @{$a}, $b->{'message'};
    }
    return $a;
  } [], @{$self->_validators};

  return $errors;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::validation::validator

=head1 SYNOPSIS

use wtsi_clarity::util::validation::validator;

my $validation = wtsi_clarity::util::validation::validator
  ->new(value => 'abcdef')
  ->is_integer()
  ->has_length(5)
  ->result();

if ($validation->failed) {
  croak $validation->error_message;
}


=head1 DESCRIPTION

Pass in the value to be validated and then chain together a load of validations.

Get back a wtsi_clarity::util::validations::result object

=head1 SUBROUTINES/METHODS

=head2 is_integer
  Tests to see if the given value is an integer.

=head2 has_length($length)
  Tests to see if the given value has a length of $length

=head2 result
  Gives back the result of the tests (using a wtsi_clarity::util::validations::result object)

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Moose::Util::TypeConsraints

=item List::Util qw/reduce/

=item wtsi_clarity::util::validation::predicates

=item wtsi_clarity::util::validation::result

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
