package wtsi_clarity::util::clarity_udf;

use Moose;
use Carp;

our $VERSION = '0.0';

has 'element' => (
  is => 'ro',
  isa => 'XML::LibXML::Element',
  required => 1,
);

sub get_value {
  my $self = shift;
  return $self->element->textContent;
};

sub get_name {
  my $self = shift;
  ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  return $self->element->findvalue('@name');
};

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_udf

=head1 SYNOPSIS

  package wtsi_clarity::util::clarity_bed;
  extends 'wtsi_clarity::util::clarity_udf';

  my $bed = wtsi_clarity::util::clarity_bed->new(element => $xml_elem);

=head1 DESCRIPTION

  An abstract parent class for Clarity UDF elements

=head1 SUBROUTINES/METHODS

=head2 get_value Returns the textContent of the element

=head2 get_name Returns the name of the element

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose;

=item Carp;

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