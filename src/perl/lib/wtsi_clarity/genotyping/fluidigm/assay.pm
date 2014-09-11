package wtsi_clarity::genotyping::fluidigm::assay;

use Moose;
use Readonly;

Readonly::Scalar our $EMPTY_NAME          => '[ Empty ]';
Readonly::Scalar our $NO_TEMPLATE_CONTROL => 'NTC';
Readonly::Scalar our $NO_CALL             => 'No Call';

our $VERSION = '0.0';

has 'assay'          => (is => 'ro', isa => 'Str', required => 1);
has 'snp_assayed'    => (is => 'ro', isa => 'Str', required => 1);
has 'x_allele'       => (is => 'ro', isa => 'Str', required => 1);
has 'y_allele'       => (is => 'ro', isa => 'Str', required => 1);
has 'sample_name'    => (is => 'ro', isa => 'Str', required => 1);
has 'type'           => (is => 'ro', isa => 'Str', required => 1);
has 'auto'           => (is => 'ro', isa => 'Str', required => 1);
has 'confidence'     => (is => 'ro', isa => 'Num', required => 1);
has 'final'          => (is => 'ro', isa => 'Str', required => 1);
has 'converted_call' => (is => 'ro', isa => 'Str', required => 1);
has 'x_intensity'    => (is => 'ro', isa => 'Num', required => 1);
has 'y_intensity'    => (is => 'ro', isa => 'Num', required => 1);

=head2 is_control

  Arg [1]    : None

  Example    : $result->is_control
  Description: Return whether the result is for a control assay.
  Returntype : Bool

=cut

sub is_control {
  my ($self) = @_;

  # It is not clear how no-template controls are being
  # represented. There seem to be several ways in play, currently:
  #
  # a) The snp_assayed column is empty
  # b) The sample_name column contains the token '[ Empty ]'
  # c) The type, auto, call and converted_call columns contain the token 'NTC'
  #
  # or some combination of the above.

  return ($self->snp_assayed eq q{} or
          $self->sample_name eq $EMPTY_NAME or
          $self->type        eq $NO_TEMPLATE_CONTROL);
}

=head2 is_call

  Arg [1]    : None

  Example    : $result->is_call
  Description: Return whether the result has called a genotype.
  Returntype : Bool

=cut

sub is_call {
  my ($self) = @_;

  return $self->final ne $NO_CALL;
}

=head2 is_gender_marker

  Arg[1]     : None

  Example    : $result->is_gender_marker
  Description: Return whether the result is a gender marker
  Returntype : Bool

=cut

sub is_gender_marker {
  my $self = shift;

  return $self->snp_assayed =~ /^GS/sxm;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm::assay

=head1 SYNOPSIS

  my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
      assay          => 'S26-A01',
      snp_assayed    => '',
      x_allele       => 'C',
      y_allele       => 'T',
      sample_name    => 'ABC0123456789',
      type           => 'Unknown',
      auto           => 'No Call',
      confidence     => '0.1',
      final          => 'XY',
      converted_call => 'C:T',
      x_intensity    => '0.1',
      y_intensity    => '0.1'
    );

=head1 DESCRIPTION

  Respresents a single assay

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
