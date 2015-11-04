package wtsi_clarity::util::pdf::factory::pico_analysis_results;

use Moose;
use Carp;
use Readonly;


with 'wtsi_clarity::util::pdf::factory::analysis_results';
extends 'wtsi_clarity::util::pdf::pdf_generator';

Readonly::Scalar our $NUMBER_OF_COLUMNS => 12;

Readonly::Scalar my $buffer_table_y_position => 100;

our $VERSION = '0.0';

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

  my ($plate_table, $plate_table_cell_styles) = $self->format_tables($parameters);

  my $pdf_generator = wtsi_clarity::util::pdf::pdf_generator->new();

  my $page = $self->pdf->page();
  $page->mediabox('A4');

  $pdf_generator->add_title_to_page($page, 'Picogreen Analysis');
  $pdf_generator->add_timestamp($page);

  $pdf_generator->add_buffer_block_to_page($self->pdf, $page, $plate_table, 'Results', $plate_table_cell_styles, $buffer_table_y_position);

  return $self->pdf;
}

sub table_header_row {
  return [0..$NUMBER_OF_COLUMNS];
}

sub table_footer_row {
  my @row = ();
  push @row, q{*};
  push @row, 1..$NUMBER_OF_COLUMNS;
  return \@row;
}

sub format_table_cell {
  my $cell = shift;
  my $concentration = sprintf '%.2f', $cell->{'concentration'};
  my $cv = sprintf '%.2f', $cell->{'cv'};

  return join "\n", $concentration, $cv, $cell->{'status'};
}

sub format_style_table_cell {
  my $cell = shift;
  return uc $cell->{'status'};
}

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::factory::pico_analysis_results

=head1 SYNOPSIS
  
  use wtsi_clarity::util::pdf::factory::pico_analysis_results;
  my $factory = wtsi_clarity::util::pdf::factory::pico_analysis_results->new();
  $factory->build($pdf_data);
  
=head1 DESCRIPTION

  Creates the pico analysis PDF 

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

=item use wtsi_clarity::util::pdf_generator::pico_analysis_results;

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