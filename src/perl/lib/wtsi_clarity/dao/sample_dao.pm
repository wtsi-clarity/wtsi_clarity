package wtsi_clarity::dao::sample_dao;

use Moose;
use Readonly;

with 'wtsi_clarity::dao::base_dao';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_UUID_AND_NAME_PATH                => q{/smp:sample/name};
Readonly::Scalar my $SAMPLE_REFERENCE_GENOME_PATH             => q{/smp:sample/udf:field[@name='Reference Genome']};
Readonly::Scalar my $SAMPLE_WTSI_ORGANISM_PATH                => q{/smp:sample/udf:field[@name='WTSI Organism']};
Readonly::Scalar my $SAMPLE_WTSI_SUPPLIER_SAMPLE_NAME_SM_PATH => q{/smp:sample/udf:field[@name='WTSI Supplier Sample Name (SM)']};
Readonly::Scalar my $SAMPLE_WTSI_TAXON_ID_PATH                => q{/smp:sample/udf:field[@name='WTSI Taxon ID']};
Readonly::Scalar my $SAMPLE_WTSI_SUPPLIER_GENDER_PATH         => q{/smp:sample/udf:field[@name='WTSI Supplier Gender - (SM)']};
Readonly::Scalar my $SAMPLE_IS_CONTROL_PATH                   => q{/smp:sample/udf:field[@name='Control?']};
Readonly::Scalar my $SAMPLE_WTSI_SUPPLIER_PATH                => q{/smp:sample/udf:field[@name='WTSI Supplier']};
Readonly::Scalar my $SAMPLE_WTSI_DONOR_ID_PATH                => q{/smp:sample/udf:field[@name='WTSI Donor ID']};
Readonly::Scalar my $SAMPLE_PROJECT_LIMSID_PATH               => q{/smp:sample/project/@limsid};
Readonly::Scalar my $SAMPLE_WTSI_BAIT_LIBRARY_NAME_PATH       => q{/smp:sample/udf:field[@name='WTSI Bait Library Name']};
## use critic

Readonly::Array  my @SAMPLE_ATTRIBUTES                        => qw/  uuid
                                                                      name
                                                                      reference_genome
                                                                      organism
                                                                      common_name
                                                                      taxon_id
                                                                      gender
                                                                      control
                                                                      supplier_name
                                                                      public_name
                                                                      donor_id
                                                                      project_limsid
                                                                      bait_library_name
                                                                  /;

our $VERSION = '0.0';

has 'resource_type' => (
  isa         => 'Str',
  is          => 'ro',
  required    => 0,
  default     => 'samples',
);

foreach my $sample_attribute ( @SAMPLE_ATTRIBUTES ) {
  has $sample_attribute => (
    isa             => 'Str',
    is              => 'rw',
    required        => 0,
    lazy_build      => 1,
  );
}

sub _build_uuid {
  my $self = shift;
  return $self->findvalue($SAMPLE_UUID_AND_NAME_PATH);
}

sub _build_name {
  my $self = shift;

  return $self->findvalue($SAMPLE_UUID_AND_NAME_PATH);
}

sub _build_reference_genome {
  my $self = shift;

  return $self->findvalue($SAMPLE_REFERENCE_GENOME_PATH);
}

sub _build_organism {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_ORGANISM_PATH);
}

sub _build_common_name {
 my $self = shift;
  return $self->findvalue($SAMPLE_WTSI_SUPPLIER_SAMPLE_NAME_SM_PATH);
}

sub _build_taxon_id {
 my $self = shift;
  return $self->findvalue($SAMPLE_WTSI_TAXON_ID_PATH);
}

sub _build_gender {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_SUPPLIER_GENDER_PATH);
}

sub _build_control {
  my $self = shift;

  return $self->findvalue($SAMPLE_IS_CONTROL_PATH);
}

sub _build_supplier_name {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_SUPPLIER_PATH);
}

sub _build_public_name {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_SUPPLIER_SAMPLE_NAME_SM_PATH);
}

sub _build_donor_id {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_DONOR_ID_PATH);
}

sub _build_project_limsid {
  my $self = shift;

  return $self->findvalue($SAMPLE_PROJECT_LIMSID_PATH);
}

sub _build_bait_library_name {
  my $self = shift;

  return $self->findvalue($SAMPLE_WTSI_BAIT_LIBRARY_NAME_PATH);
}

sub init {
  my $self = shift;

  foreach my $sample_attribute ( @SAMPLE_ATTRIBUTES ) {
    $self->$sample_attribute;
  }

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::dao::sample_dao

=head1 SYNOPSIS
  my $sample_dao = wtsi_clarity::dao::sample_dao->new(lims_id => "1234");
  $sample_dao->to_message();

=head1 DESCRIPTION
 A data object representing a sample.
 Its data coming from the sample artifact (XML file).

=head1 SUBROUTINES/METHODS

=head2 init
  Initialize the data object with its data.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
