package wtsi_clarity::util::pdf::layout::pico_analysis_results;

use Moose;
use Readonly;

Readonly::Scalar my $buffer_table_y_position => 700;

extends 'wtsi_clarity::util::pdf::pdf_generator';

our $VERSION = '0.0';

sub create {
  my $self = shift;

  my $font_bold = $self->pdf->corefont('Helvetica-Bold');
  my $font = $self->pdf->corefont('Helvetica');

  # for each output container, we produce a new page...
  foreach my $page_data (@{$self->pdf_data->{'pages'}}) {
    my $page = $self->pdf->page();
    $page->mediabox('A4');

    wtsi_clarity::util::pdf::pdf_generator::add_title_to_page($page, $font_bold, $page_data->{'title'});
    wtsi_clarity::util::pdf::pdf_generator::add_timestamp($page, $font, $self->pdf_data->{'stamp'});

    wtsi_clarity::util::pdf::pdf_generator::add_buffer_block_to_page($self->pdf, $page, $font_bold, $page_data->{'plate_table'}, $page_data->{'plate_table_title'}, $page_data->{'plate_table_cell_styles'}, $buffer_table_y_position);
  }

  return $self->pdf;
};

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::layout::pico_analysis_results

=head1 SYNOPSIS

  my $generator = wtsi_clarity::util::pdf::layout::pico_analysis_results->new(pdf_data => ... );
  my $file = $generator->create();

=head1 DESCRIPTION

  Creates a pdf document describing the plates.

=head1 SUBROUTINES/METHODS

=head2 pdf_data - hash describing the data to display
(see t/10-util-pdf_worksheet_generator.t for format)

=head2 create() - creates pdf file, which then can be saved using saveas().

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

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

