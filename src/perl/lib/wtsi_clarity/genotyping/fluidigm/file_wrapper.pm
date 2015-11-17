package wtsi_clarity::genotyping::fluidigm::file_wrapper;

use Moose;
use Carp;
use Readonly;
use English qw{-no_match_vars};

use wtsi_clarity::util::types;
use wtsi_clarity::util::string qw/trim/;

our $VERSION = '0.0';

Readonly::Scalar my $HEADER_BARCODE_ROW             => 0;
Readonly::Scalar my $HEADER_BARCODE_COL             => 2;

Readonly::Scalar my $HEADER_CONF_THRESHOLD_ROW      => 5;
Readonly::Scalar my $HEADER_CONF_THRESHOLD_COL      => 1;
Readonly::Scalar my $EXPECTED_NUM_COLUMNS           => 12;

Readonly::Scalar my $FLUIDIGM_96_WELL_COUNT         => 96;
Readonly::Scalar my $FLUIDIGM_192_WELL_COUNT        => 192;
Readonly::Scalar my $FLUIDIGM_96_SAMPLE_DATA_COUNT  => 96 * 96;
Readonly::Scalar my $FLUIDIGM_192_SAMPLE_DATA_COUNT => 192 * 24;

has 'file_name' => (
  is       => 'ro',
  isa      => 'WtsiClarityReadableFile',
  required => 1,
);

has 'content' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub {
    return {
    }
  },
  writer  => '_write_content',
);

sub BUILD {
  my ($self) = @_;

  open my $in, '<:encoding(utf8)', $self->file_name
    or croak "Failed to open Fluidigm export file '",
  $self->file_name, "': $OS_ERROR";
  my $sample_data = $self->_sample_data_from_fluidigm_table($in);
  close $in or croak "Unable to close Fluidigm export file";

  $self->_write_content($sample_data);

  return;
}

sub _sample_data_from_fluidigm_table {
  my ($self, $fh) = @_;
  binmode $fh, ':encoding(utf8)';

  # Arrays of sample data lines keyed on Chamber IDs
  my %sample_data;

  # For error reporting
  my $line_num = 0;
  my $num_sample_rows = 0;

  while (my $line = <$fh>) {
    ++$line_num;
    chomp $line;
    next if $line =~ m/^\s*$/sxm;

    if ($line =~ /^S\d+\-[[:upper:]]\d+/sxm) {
      my @columns = map {
        trim $_
      } split /,/sxm, $line;
      my $num_columns = scalar @columns;
      if ($num_columns != $EXPECTED_NUM_COLUMNS) {
        croak "Parse error: expected $EXPECTED_NUM_COLUMNS ",
        "columns, but found $num_columns at line $line_num";
      }

      my $id = $columns[0];
      my ($sample_address, $assay_num) = split /-/sxm, $id;

      if (!$sample_address) {
        croak "Parse error: no sample address in '$id' ",
        "at line $line_num";
      }
      if (!$assay_num) {
        croak "Parse error: no assay number in '$id' ",
        "at line $line_num";
      }

      $sample_data{$sample_address} ||= [];
      push @{$sample_data{$sample_address}}, \@columns;
      $num_sample_rows++;
    }
  }

  $self->_validate_data_count(\%sample_data, $num_sample_rows);

  return \%sample_data;
}

sub _validate_data_count {
  my ($self, $sample_data, $num_sample_rows) = @_;

  my $well_count = scalar keys %{$sample_data};
  if ($num_sample_rows == $FLUIDIGM_96_SAMPLE_DATA_COUNT) {
    if ($well_count != $FLUIDIGM_96_WELL_COUNT) {
      croak "Parse error: expected data for 96 samples, found ", $well_count;
    }
  }
  elsif ($num_sample_rows == $FLUIDIGM_192_SAMPLE_DATA_COUNT) {
    if ($well_count != $FLUIDIGM_192_WELL_COUNT) {
      croak "Parse error: expected data for 192 samples, found ", $well_count;
    }
  }
  else {
    croak "Parse error: expected ", $FLUIDIGM_96_SAMPLE_DATA_COUNT,
    " or ", $FLUIDIGM_192_SAMPLE_DATA_COUNT,
    " sample data rows, found $num_sample_rows";
  }
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm::file_wrapper

=head1 SYNOPSIS

  wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
    file_name => '/path/to/fluidigm/file'
  )->run();

=head1 DESCRIPTION

  Wrapper around a Fluidigm results file

=head1 SUBROUTINES/METHODS

=head2 BUILD - Constructor

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item English

=back

=head1 AUTHOR

Keith James E<lt>kdj@sanger.ac.ukE<gt>

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
