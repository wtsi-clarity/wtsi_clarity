package wtsi_clarity::util::pdf::factory::pool_analysis_results;

use Moose;
use Readonly;

use wtsi_clarity::util::pdf::layout::pool_analysis_results;
use wtsi_clarity::util::well_mapper;

with 'wtsi_clarity::util::pdf::factory::analysis_results';

our $VERSION = '0.0';

Readonly::Scalar our $NUMBER_OF_COLUMNS => 12;
Readonly::Scalar our $ASSET_NUMBER_OF_ROWS => 8;
Readonly::Scalar our $ASSET_NUMBER_OF_COLUMNS => 12;

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

  my ($plate_table, $plate_table_cell_styles) = $self->format_tables($parameters->{'plate_table_data'});

  my $pdf_data = {
    'stamp' => 'Created: ' . DateTime->now->strftime('%A %d-%B-%Y at %H:%M:%S'),
    'pages' => [
      {
        'title' => 'Pooling worksheets',
        'input_table_title' => 'Source Plate',
        'input_table' => _get_input_table_data($parameters->{'input_table_data'}),
        'plate_table_title' => 'Results',
        'plate_table' => $plate_table,
        'plate_table_cell_styles' => $plate_table_cell_styles,
      }
    ]
  };

  my $pool_pdf_generator = wtsi_clarity::util::pdf::layout::pool_analysis_results->new(pdf_data => $pdf_data);
  return $pool_pdf_generator->create();
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