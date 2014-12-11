package wtsi_clarity::util::pdf::layout::pool_analysis_results;

use Moose;
use Readonly;

Readonly::Scalar my $SOURCE_TABLE_HEIGHT      => 510;
Readonly::Scalar my $BUFFER_TABLE_Y_POSITION  => 430;
Readonly::Scalar my $A4_LANDSCAPE_HEIGHT      => 8.27;
Readonly::Scalar my $A4_LANDSCAPE_WIDTH       => 11.7;
Readonly::Scalar my $DPI_RESOLUTION           => 72;

extends 'wtsi_clarity::util::pdf::pdf_generator';

our $VERSION = '0.0';

sub A4_LANDSCAPE {
  return (0, 0, $A4_LANDSCAPE_WIDTH*$DPI_RESOLUTION, $A4_LANDSCAPE_HEIGHT*$DPI_RESOLUTION);
}

sub create {
  my $self = shift;

  my $font_bold = $self->pdf->corefont('Helvetica-Bold');
  my $font = $self->pdf->corefont('Helvetica');

  my $pdf_generator = wtsi_clarity::util::pdf::pdf_generator->new(cell_font_size => 5);

  # for each output container, we produce a new page...
  foreach my $page_data (@{$self->pdf_data->{'pages'}}) {
    my $page = $self->pdf->page();
    $page->mediabox(A4_LANDSCAPE);

    $pdf_generator->add_title_to_page($page, $font_bold, $page_data->{'title'});
    $pdf_generator->add_timestamp($page, $font, $self->pdf_data->{'stamp'});

    $pdf_generator->add_io_block_to_page($self->pdf, $page, $font_bold, $page_data->{'input_table'}, $page_data->{'input_table_title'}, $SOURCE_TABLE_HEIGHT);

    $pdf_generator->add_buffer_block_to_page($self->pdf, $page, $font_bold, $page_data->{'plate_table'}, $page_data->{'plate_table_title'}, $page_data->{'plate_table_cell_styles'}, $BUFFER_TABLE_Y_POSITION);
  }

  return $self->pdf;
};

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::layout::pool_analysis_results

=head1 SYNOPSIS

  my $generator = wtsi_clarity::util::pdf::layout::pool_analysis_results->new(pdf_data => ... );
  my $file = $generator->create();

=head1 DESCRIPTION

  Creates a pdf document describing the plates.

=head1 SUBROUTINES/METHODS

=head2 create() - creates pdf file, which then can be saved using saveas().

=head2 A4_LANDSCAPE - Defines the size of an A4 paper sheet for landscape format.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
