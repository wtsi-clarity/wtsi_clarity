package wtsi_clarity::util::clarity_plate;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::util::string qw/trim/;

our $VERSION = '0.0';

Readonly::Scalar my $NOT_FOUND => -1;

has 'plate_elem' => (
  is => 'ro',
  isa => 'XML::LibXML::Element',
  required => 1,
);

has ['barcode', 'element_name'] => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_barcode {
  my $self = shift;
  return $self->plate_elem->textContent;
};

sub _build_element_name {
  my $self = shift;
  ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  return $self->plate_elem->findvalue('@name');
};

sub name {
  my $self = shift;
  my $name = $self->element_name;

  if ($name =~ /[[:lower:]]$/sxm) {
    chop $name;
  }

  return $name;
}

sub is_input {
  my $self = shift;
  return (index($self->element_name, 'Input') != $NOT_FOUND);
}

sub is_output {
  my $self = shift;
  return (index($self->element_name, 'Output') != $NOT_FOUND);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_plate

=head1 SYNOPSIS

  use wtsi_clarity::util::clarity_plate;

  my $plate = wtsi_clarity::util::clarity_plate->new(plate_elem => $xml_elem);

=head1 DESCRIPTION

  Essentaily a wrapper around a plate XML::LibXML::Element set on a process document. Provides
  useful methods for barcode and plate name.

=head1 SUBROUTINES/METHODS

=head2 barcode The textContent of the element should be the barcode

=head2 element_name The element_name is the value of the name parameter on the element

=head2 name The name of the plate (removes letter off the end of it if present)

=head2 is_input Returns true if plate is an input plate (i.e. it's name contains "Input")

=head2 is_output Returns true if plate is an output plate (i.e. it's name contains "Output")

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
