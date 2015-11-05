package wtsi_clarity::genotyping::fluidigm::file_wrapper;

use Moose;
use Carp;
use Readonly;
use English qw{-no_match_vars};

use wtsi_clarity::util::types;
use wtsi_clarity::util::string qw/trim/;

our $VERSION = '0.0';

Readonly::Scalar my $EXPECTED_NUM_COLUMNS => 12;

has 'file_name' => (
  is       => 'ro',
  isa      => 'WtsiClarityReadableFile',
  required => 1,
);

has 'header' => (
  is     => 'ro',
  isa    => 'ArrayRef[Str]',
  writer => '_write_header',
);

has 'column_names' => (
  is     => 'ro',
  isa    => 'ArrayRef[Str]',
  writer => '_write_column_names',
);

has 'fluidigm_barcode' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  lazy     => 1,
  builder  => '_build_fluidigm_barcode',
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
  my $self = shift;

  open my $in, '<:encoding(utf8)', $self->file_name
    or croak "Failed to open Fluidigm export file '",
  $self->file_name, "': $OS_ERROR";

  my ($header, $column_names, $sample_data) = $self->_parse_fluidigm_table($in);

  close $in or croak "Unable to close Fluidigm export file";

  $self->_write_header($header);
  $self->_write_column_names($column_names);
  $self->_write_content($sample_data);

  return;
}

sub _parse_fluidigm_table {
  my ($self, $fh) = @_;
  binmode $fh, ':encoding(utf8)';

  my @header = _read_header($fh);
  my @column_names = _read_column_names($fh);
  my %sample_data = _read_sample_data($fh);

  return (\@header, \@column_names, \%sample_data);
}

sub _read_header {
  my $file = shift;

  my @header;
  while (my $line = <$file>) {
    chomp $line;

    if ($line =~ m/^\s*$/sxm) {
      next;
    } elsif ($line =~ /^Experiment/smx) {
      last;
    } else {
      push @header, $line;
    }
  }
  if (!@header) {
    croak "Parse error: no header rows found";
  }

  return @header;
}

sub _read_column_names {
  my $file = shift;

  my @column_names;
  while (my $line = <$file>) {
    chomp $line;

    if ($line =~ /^ID/sxm) {
      @column_names = map {
        trim $_
      } split /,/sxm, $line;
      my $num_columns = scalar @column_names;
      if ($num_columns != $EXPECTED_NUM_COLUMNS) {
        croak "Parse error: expected $EXPECTED_NUM_COLUMNS columns, but found $num_columns atr line $.";
      }
      last;
    }
  }
  if (!@column_names) {
    croak "Parse error: no column names found";
  }

  return @column_names;
}

sub _read_sample_data {
  my $file = shift;

  my %sample_data;
  my $num_sample_rows = 0;

  while (my $line = <$file>) {
    chomp $line;

    if ($line =~ /^S\d+\-[A-Z]\d+/smx) {
      my @columns = map {
        trim $_
      } split /,/sxm, $line;
      my $num_columns = scalar @columns;
      if ($num_columns != $EXPECTED_NUM_COLUMNS) {
        croak "Parse error: expected $EXPECTED_NUM_COLUMNS columns, but found $num_columns at line $.";
      }

      my $id = $columns[0];
      my ($sample_address, $assay_num) = split /-/sxm, $id;

      if (!$sample_address) {
        croak "Parse error: no sample address in '$id' at line $.";
      }
      if (!$assay_num) {
        croak "Parse error: no assay number in '$id' at line $.";
      }

      if (!exists $sample_data{$sample_address}) {
        $sample_data{$sample_address} = [];
      }

      push @{$sample_data{$sample_address}}, \@columns;
      $num_sample_rows++;
    }
  }

  ## no critic (MagicNumbers)
  if ($num_sample_rows == (96 * 96)) {
    if (scalar keys %sample_data != 96) {
      croak "Parse error: expected data for 96 samples, found ", scalar keys %sample_data;
    }
  } elsif ($num_sample_rows == (192 * 24)) {
    if (scalar keys %sample_data != 192) {
      croak "Parse error: expected data for 192 samples, found ", scalar keys %sample_data;
    }
  } else {
    croak "Parse error: expected ", 96 * 96, " or ", 192 * 24, " sample data rows, found $num_sample_rows";
  }
  ## use critic

  return %sample_data;
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
