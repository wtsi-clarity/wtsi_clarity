package wtsi_clarity::epp::ics::tag_plate_common;

use Moose::Role;
use wtsi_clarity::util::error_reporter qw/croak/;
use Readonly;

our $VERSION = '0.0';

Readonly::Scalar my $TAG_PLATE_BARCODE_UDF_NAME => q[Tag Plate];

requires qw/ find_udf_element process_doc/;

has 'barcode' => (
    isa        => 'Str',
    is         => 'ro',
    required   => 0,
    lazy_build => 1,
);
sub _build_barcode {
  my $self = shift;
  my $tag_plate_barcode = $self->find_udf_element($self->process_doc, $TAG_PLATE_BARCODE_UDF_NAME);
  if (!$tag_plate_barcode) {
    croak( "'$TAG_PLATE_BARCODE_UDF_NAME' udf process field is missing");
  }
  my $barcode = $tag_plate_barcode->textContent;
  if (!$barcode) {
    croak( 'Tag plate barcode value is not set');
  }
  return $barcode;
}

no Moose::Role;

1;

__END__

=head1 NAME

 wtsi_clarity::epp::ics::tag_plate_common

=head1 SYNOPSIS

=head1 DESCRIPTION

 Common methods for epp modules dealing with tag plates and indexing.

=head1 SUBROUTINES/METHODS

=head2 barcode

  Accessor for Gatekeeter tag plate barcode.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item wtsi_clarity::util::error_reporter

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
