package wtsi_clarity::genotyping::fluidigm::assay_set;

use Moose;
use Carp;
use Readonly;
use List::Util qw / reduce /;
use List::MoreUtils qw/ uniq /;

use wtsi_clarity::genotyping::fluidigm::assay;

our $VERSION = '0.0';

Readonly::Hash our %SEX_MAP => { XX => 'M', XY => 'F', YY => 'F' };

has 'file_content' => (
  is       => 'ro',
  isa      => 'ArrayRef[ArrayRef]',
  required => 1,
);

has 'assay_results' => (
  is      => 'ro',
  isa     => 'ArrayRef[wtsi_clarity::genotyping::fluidigm::assay]',
  writer  => 'write_assay_results',
  trigger => \&_build_call_rate,
);

has 'call_rate' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_call_rate',
);

sub _build_call_rate {
  my $self = shift;

  my $denominator = scalar @{$self->assay_results};
  my $numerator = reduce {
    if ($b->is_call) {
      $a++;
    };
    return $a;
  } 0, @{$self->assay_results};

  return "$numerator/$denominator";
}

has 'gender' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_gender',
);

sub _build_gender {
  my ($self) = @_;

  my $res = scalar uniq @{$self->gender_set};
  if ($res != 1) {
    return 'Unknown';
  }

  # Since gender_set is homogenous we can just return the first one...
  return $SEX_MAP{ $self->gender_set->[0] };
}

has 'gender_set' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  writer => 'write_gender_set',
  trigger => \&_build_gender,
);

sub BUILD {
  my ($self) = @_;

  my @assays;
  my @gender_set;

  foreach my $assay_result (@{$self->file_content}) {

## no critic (MagicNumbers)
    my $num_fields = scalar @{$assay_result};
    if ($num_fields != 12) {
      croak "Invalid Fluidigm record: expected 12 fields but found $num_fields";
    }

    my $assay = wtsi_clarity::genotyping::fluidigm::assay->new(
      assay          => $assay_result->[0],
      snp_assayed    => $assay_result->[1],
      x_allele       => $assay_result->[2],
      y_allele       => $assay_result->[3],
      sample_name    => $assay_result->[4],
      type           => $assay_result->[5],
      auto           => $assay_result->[6],
      confidence     => $assay_result->[7],
      final          => $assay_result->[8],
      converted_call => $assay_result->[9],
      x_intensity    => $assay_result->[10],
      y_intensity    => $assay_result->[11],
    );
## use critic

    push @assays, $assay;
    if ($assay->is_gender_marker) {
      push @gender_set, $assay->final;
    }
  }

  $self->write_assay_results(\@assays);
  $self->write_gender_set(\@gender_set);

  return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm::assay_set

=head1 SYNOPSIS

  my $assay_set = wtsi_clarity::genotyping::fluidigm::assay_set->new(
    file_content => $file_content
  );
  $assay_set->gender;
  $assay_set->call_rate;

=head1 DESCRIPTION

A class which represents the result of a Fluidigm assay on one sample
for a number of SNPs.

=head1 SUBROUTINES/METHODS

=head2 BUILD - Constructor

=head1 DEPENDENCIES

=over

=item Moose;

=item Carp;

=item Readonly;

=item List::Util qw / reduce /;

=item List::MoreUtils qw/ uniq /;

=item wtsi_clarity::genotyping::fluidigm::assay;

=back

=head1 CONFIGURATION AND ENVIRONMENT

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
