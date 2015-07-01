package wtsi_clarity::util::validators;

use strict;
use warnings;

use wtsi_clarity::util::validation;

use List::Util   qw/reduce/;
use Scalar::Util qw/looks_like_number/;
use Readonly;
use Exporter 'import';

our @EXPORT_OK = qw/flgen_bc ean13_bc/;

our $VERSION = '0.0';

Readonly::Scalar my $FLUIDIGM_BC_LENGTH => 10;
Readonly::Scalar my $EAN_BC_LENGTH      => 13;

sub flgen_bc {
  return _validator(_has_length($FLUIDIGM_BC_LENGTH), _is_integer())->(shift);
}
sub ean13_bc {
  return _validator(_has_length($EAN_BC_LENGTH), _is_integer())->(shift);
}

sub _validator {
  my @validators = @_;

  return sub {
    my $val = shift;

    my $errors = reduce {
      if (!$b->{'check'}->($val)) {
        push @{$a}, $b->{'message'};
      }
      return $a;
    } [], @validators;

    return wtsi_clarity::util::validation->new(value => $val, errors => $errors);
  }
}

sub _has_length {
  my $length = shift;
  my $message = shift;

  return {
    check   => sub {
      my $val = shift;
      return $length == length $val;
    },
    message => $message // 'The barcode must have a length of ' . $length,
  }
}

sub _is_integer {
  my $message = shift;

  return {
    check   => \&looks_like_number,
    message => $message // 'The barcode must be numeric',
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::util::validators

=head1 SYNOPSIS

use wtsi_clarity::util::validators qw/flgen_bc/;

my $validation = flgen_bc('1234567');

if (!$validation->failed) {
  croak $validation->error_message;
}

=head1 DESCRIPTION

A module for providing a couple of different validations, each of which return a Validation
object with 2 methods on: failed and error_message.

=head1 SUBROUTINES/METHODS

=head2 flgen_bc
  Tests to see if a given value has a length of 10, and is numeric.

=head2 ean13_bc
  Tests to see if a given value has a length of 13, and is numeric.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item wtsi_clarity::util::validation

=item List::Util

=item Scalar::Util

=item Exporter

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
