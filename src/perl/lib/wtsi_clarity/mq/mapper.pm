package wtsi_clarity::mq::mapper;

use Moose;
use Carp;
use Readonly;

our $VERSION = '0.0';

Readonly::Scalar my $BASE_MQ_PACKAGE_NAME => q{wtsi_clarity::mq::};
Readonly::Hash my %PURPOSE_TO_ENHANCER_TYPE => (
  'sample'    => 'me::sample_enhancer',
);

sub package_name {
  my ($self, $message_purpose) = @_;

  my $enhancer_type = $PURPOSE_TO_ENHANCER_TYPE{$message_purpose};

  if (!$enhancer_type) {
    croak qq{Purpose $message_purpose could not be found}
  }

  return $BASE_MQ_PACKAGE_NAME . $PURPOSE_TO_ENHANCER_TYPE{$message_purpose};
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::mapper

=head1 SYNOPSIS

  my $mapper = wtsi_clarity::mq::mapper->new();
  $mapper->package_name('sample');

=head1 DESCRIPTION

 Contains a hash with the relevant message enhancer types.
 If called 'package_name' on it with the proper message purpose,
 then it returns the concrete message enhancer class.

=head1 SUBROUTINES/METHODS

=head2 package_name

  Takes in message purpose string. Returns the package name of the concrete message enhancer class.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
