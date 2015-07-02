package wtsi_clarity::epp::generic::roles::barcode_common;

use Moose::Role;
use Readonly;
use Carp;

use wtsi_clarity::util::barcode qw/calculateBarcode/;

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

Readonly::Scalar my $BARCODE_PREFIX_UDF_NAME  => q{Barcode Prefix};
Readonly::Scalar my $DEFAULT_BARCODE_PREFIX   => q{SM};

has '_barcode_prefix' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__barcode_prefix {
  my $self = shift;
  return $self->find_udf_element_textContent(
    $self->process_doc->xml, $BARCODE_PREFIX_UDF_NAME, $DEFAULT_BARCODE_PREFIX);
}

sub generate_barcode {
  my ($self, $container_id) = @_;
  if (!$container_id) {
    croak 'Container id is not given';
  }
  $container_id =~ s/-//smxg;
  return calculateBarcode($self->_barcode_prefix, $container_id);
}

no Moose::Role;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::roles::barcode_common

=head1 SYNOPSIS

  with 'wtsi_clarity::epp::generic::roles::barcode_common';

=head1 DESCRIPTION

  Common utility methods for dealing with barcode generation.

=head1 SUBROUTINES/METHODS

=head2 generate_barcode

  Generate barcode from the given container limsid.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::barcode

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
