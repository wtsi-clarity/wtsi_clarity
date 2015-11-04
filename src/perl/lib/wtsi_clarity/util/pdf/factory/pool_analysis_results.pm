package wtsi_clarity::util::pdf::factory::pool_analysis_results;

use Moose;
use Readonly;

use wtsi_clarity::util::well_mapper;

with 'wtsi_clarity::util::pdf::factory::analysis_results';
extends 'wtsi_clarity::util::pdf::pdf_generator';

our $VERSION = '0.0';

Readonly::Scalar our $NUMBER_OF_COLUMNS => 12;
Readonly::Scalar our $ASSET_NUMBER_OF_ROWS => 8;
Readonly::Scalar our $ASSET_NUMBER_OF_COLUMNS => 12;

Readonly::Scalar my $SOURCE_TABLE_HEIGHT      => 100;
Readonly::Scalar my $BUFFER_TABLE_Y_POSITION  => 200;

has 'plate_table' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  default => sub {
    my $self = shift;

    return {
      header_row => \&table_header_row,
      row_first_column => \&table_row_first_column,
      format_cell => \&format_table_cell,
      footer_row => \&table_footer_row,
    }
  },
);

has 'plate_style_table' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  default => sub {
    my $self = shift;

    return {
      header_row => \&headers_row,
      row_first_column => \&style_row_first_column,
      format_cell => \&format_style_table_cell,
      footer_row => \&headers_row,
    }
  },
);

sub build {
  my ($self, $parameters) = @_;

  my $pdf_generator = wtsi_clarity::util::pdf::pdf_generator->new(cell_font_size => 5, col_width => 60, page_height => 595);

  for my $parameter (@{$parameters}) {
    my ($plate_table, $plate_table_cell_styles) = $self->format_tables($parameter->{'plate_table_data'});

    my $page = $self->pdf->page();
    $page->mediabox($self->A4_LANDSCAPE);

    $pdf_generator->add_title_to_page($page, 'Pooling worksheets');
    $pdf_generator->add_timestamp($page);

    $pdf_generator->add_io_block_to_page($self->pdf, $page, _get_input_table_data($parameter->{'input_table_data'}), 'Source Plate', $SOURCE_TABLE_HEIGHT);

    $pdf_generator->add_buffer_block_to_page($self->pdf, $page, $plate_table, 'Results', $plate_table_cell_styles, $BUFFER_TABLE_Y_POSITION);
  }

  return $self->pdf;
}

sub _get_input_table_data {
  my $input_table_data = shift;

  my @input_table = ();
  push @input_table, ['Plate name', 'Barcode', 'Signature'];

  my @input_table_data = ();
  foreach my $table_row_data (@{$input_table_data}) {
    push @input_table_data, $table_row_data;
  }

  push @input_table, \@input_table_data;

  return \@input_table;
}

sub table_header_row {
  return [q{}, 1..$NUMBER_OF_COLUMNS];
}

sub table_footer_row {
  return [q{}, 1..$NUMBER_OF_COLUMNS];
}

sub format_table_cell {
  my $cell = shift;

  my $study_sample_name = join q{_}, $cell->{'study_name'}, $cell->{'sample_name'};

  return join "\n", $study_sample_name, $cell->{'organism'}, $cell->{'bait_library_name'};
}

sub format_style_table_cell {
  my $cell = shift;
  my $pooled_location = wtsi_clarity::util::well_mapper->well_location_index(
    $cell->{'pooled_into'}, $ASSET_NUMBER_OF_ROWS, $ASSET_NUMBER_OF_COLUMNS ) - 1;
  return q{COLOUR_} . $pooled_location;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::factory::pool_analysis_results

=head1 SYNOPSIS
  
  use wtsi_clarity::util::pdf::factory::pool_analysis_results;
  my $factory = wtsi_clarity::util::pdf::factory::pool_analysis_results->new();
  $factory->build($pdf_data, $input_table_parameters);
  
=head1 DESCRIPTION

  Creates the PDF analysis file for pooling.

=head1 SUBROUTINES/METHODS

=head2 build

=head2 table_header_row

=head2 table_footer_row

=head2 format_table_cell

=head2 format_style_table_cell

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item use wtsi_clarity::util::pdf_generator::pool_analysis_results;

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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