package wtsi_clarity::util::clarity_bed;

use Moose;
use Carp;
use wtsi_clarity::util::string qw/trim/;
extends 'wtsi_clarity::util::clarity_udf';

our $VERSION = '0.0';

has 'barcode' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => 'get_value',
);

has 'bed_name' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_bed_name {
  my $self = shift;
  my $bed_name;

  if($self->get_name() =~ /(Bed .+)[(].*[)]/sxm) {
    $bed_name = trim $1;
    return $bed_name;
  } else {
    croak 'Could not extract bed name from ' . $self->get_name();
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_bed

=head1 SYNOPSIS

  use wtsi_clarity::util::clarity_bed;

  my $bed = wtsi_clarity::util::clarity_bed->new(bed_elem => $xml_elem);

=head1 DESCRIPTION

  Essentaily a wrapper around a bed XML::LibXML::Element set on a process document. Provides
  useful methods for barcode and bed name.

=head1 SUBROUTINES/METHODS

=head2 barcode Returns the barcode of the bed (i.e. the textContent)

=head2 bed_name
  Returns the bed name. For example, if the element_name is "Bed 1 (Input Plate 1)",
  it will return "Bed 1"

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose;

=item Carp;

=item Readonly;

=item wtsi_clarity::util::string

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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