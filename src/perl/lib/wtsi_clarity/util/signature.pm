package wtsi_clarity::util::signature;

use Moose;
use Digest::MD5 qw(md5_base64);
use wtsi_clarity::util::error_reporter qw/croak/;
use Readonly;
use namespace::autoclean;

Readonly::Scalar my $MAX_LENGTH => 22;

our $VERSION = '0.0';

has 'sig_length' => (
  isa        => 'Num',
  is         => 'ro',
  required   => 0,
  default    => $MAX_LENGTH,
);

sub encode {
  my ($self, @inputs) = @_;

  my $length = $self->sig_length;
  if ($length > $MAX_LENGTH) {
    croak( qq[Maximum signature length is $MAX_LENGTH]);
  }

  my $result = md5_base64(@inputs);
  return uc(substr $result, 0, $length);
}

__PACKAGE__->meta->make_immutable;

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

=head2 sig_length, defaults to 32

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Digest::MD5

=item wtsi_clarity::util::error_reporter

=item Readonly

=item namespace::autoclean

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

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
