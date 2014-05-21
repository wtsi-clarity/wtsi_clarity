package wtsi_clarity::util::signature;

use Moose;

use Compress::Zlib;
use MIME::Base64;
use Readonly;

Readonly::Scalar my $MAX_LENGTH => 32;

our $VERSION = '0.0';

has 'length' => (
  isa        => 'Num',
  is         => 'ro',
  required   => 0,
  default    => $MAX_LENGTH,
);

sub encode {
  my ($self, @inputs) = @_;
  
  my $length = $self->length;
  my $input = join q{}, @inputs;
  my $result = encode_base64(compress($input), q{});

  if (length $result < $length) {
    my $pre = '0' x ($length - length $result);
    $result = $pre . $result;
  } else {
    $result = substr $result, 0, $length;
  }

  return $result;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::signature

=head1 SYNOPSIS
  
  use wtsi_clarity::util::signature;
  wtsi_clarity::util::signature->encode(@inputs);
  
=head1 DESCRIPTION

 Creates a compressed hash string from a list of strings.

=head1 SUBROUTINES/METHODS

=head2 encode

=head2 length, defaults to 32

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Compress::Zlib;

=item MIME::Base64;

=item Readonly;

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

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
