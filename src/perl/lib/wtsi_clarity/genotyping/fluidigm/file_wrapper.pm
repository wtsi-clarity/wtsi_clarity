package wtsi_clarity::genotyping::fluidigm::file_wrapper;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::types;
use wtsi_clarity::util::string qw/trim/;

our $VERSION = '0.0';

Readonly::Scalar my $HEADER_BARCODE_ROW => 0;
Readonly::Scalar my $HEADER_BARCODE_COL => 2;

Readonly::Scalar my $HEADER_CONF_THRESHOLD_ROW => 5;
Readonly::Scalar my $HEADER_CONF_THRESHOLD_COL => 1;

has 'file_name' =>
  (is       => 'ro',
   isa      => 'WtsiClarityReadableFile',
   required => 1);

has 'header' =>
  (is     => 'ro',
   isa    => 'ArrayRef[Str]',
   writer => '_write_header');

has 'column_names' =>
  (is     => 'ro',
   isa    => 'ArrayRef[Str]',
   writer => '_write_column_names');

has 'fluidigm_barcode' =>
  (is       => 'ro',
   isa      => 'Str',
   required => 1,
   lazy     => 1,
   builder  => '_build_fluidigm_barcode');

has 'content' =>
  (is      => 'ro',
   isa     => 'HashRef',
   default => sub { return {} },
   writer  => '_write_content');

sub BUILD {
  my ($self) = @_;

  open my $in, '<:encoding(utf8)', $self->file_name
    or croak "Failed to open Fluidigm export file '",
                     $self->file_name, "': $!";
  my ($header, $column_names, $sample_data) = $self->_parse_fluidigm_table($in);
  close $in;

  $self->_write_header($header);
  $self->_write_column_names($column_names);
  $self->_write_content($sample_data);
}

sub _parse_fluidigm_table {
  my ($self, $fh) = @_;
  binmode($fh, ':utf8');

  # True if we are in the header lines from 'Chip Run Info' to 'Allele
  # Axis Mapping' inclusive
  my $in_header = 0;
  # True if we are in the unique column names row above the sample
  # block
  my $in_column_names = 0;
  # True if we are past the header and into a data block
  my $in_sample_block = 0;

  # Arrays of sample data lines keyed on Chamber IDs
  my %sample_data;

  # For error reporting
  my $line_num = 0;
  my $expected_num_columns = 12;
  my $num_sample_rows = 0;

  my @header;
  my @column_names;

  while (my $line = <$fh>) {
    ++$line_num;
    chomp($line);
    next if $line =~ m/^\s*$/;

    if ($line =~ /^Chip Run Info/) { $in_header = 1 }
    if ($line =~ /^Experiment/)    { $in_header = 0 }
    if ($line =~ /^ID/)            { $in_column_names = 1 }
    if ($line =~ /^S[0-9]+\-[A-Z][0-9]+/) {
      $in_column_names = 0;
      $in_sample_block = 1;
    }

    if ($in_header) {
      push(@header, $line);
      next;
    }

    if ($in_column_names) {
      @column_names = map { trim($_) } split(',', $line);
      my $num_columns = scalar @column_names;
      unless ($num_columns == $expected_num_columns) {
        croak "Parse error: expected $expected_num_columns ",
                          "columns, but found $num_columns at line $line_num";
      }
      next;
    }

    if ($in_sample_block) {
      my @columns = map { trim($_) } split(',', $line);
      my $num_columns = scalar @columns;
      unless ($num_columns == $expected_num_columns) {
        croak "Parse error: expected $expected_num_columns ",
                          "columns, but found $num_columns at line $line_num";
      }

      my $id = $columns[0];
      my ($sample_address, $assay_num) = split('-', $id);

      unless ($sample_address) {
        croak "Parse error: no sample address in '$id' ",
                          "at line $line_num";
      }
      unless ($assay_num) {
        croak "Parse error: no assay number in '$id' ",
                          "at line $line_num";
      }

      if (! exists $sample_data{$sample_address}) {
        $sample_data{$sample_address} = [];
      }

      push(@{$sample_data{$sample_address}}, \@columns);
      $num_sample_rows++;
      next;
    }
  }

  unless (@header) {
    croak "Parse error: no header rows found";
  }
  unless (@column_names) {
    croak "Parse error: no column names found";
  }

  if ($num_sample_rows == (96 * 96)) {
    unless (scalar keys %sample_data == 96) {
      croak "Parse error: expected data for 96 samples, found ",
                        scalar keys %sample_data;
    }
  }
  elsif ($num_sample_rows == (192 * 24)) {
    unless (scalar keys %sample_data == 192) {
      croak "Parse error: expected data for 192 samples, found ",
                        scalar keys %sample_data;
    }
  }
  else {
    croak "Parse error: expected ", 96 * 96, " or ", 192 * 24,
                      " sample data rows, found $num_sample_rows";
  }

  return (\@header, \@column_names, \%sample_data);
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
