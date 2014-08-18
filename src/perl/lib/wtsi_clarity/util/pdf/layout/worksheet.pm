package wtsi_clarity::util::pdf::layout::worksheet;

use Moose;
use Readonly;

Readonly::Scalar my $source_table_height      => 700;
Readonly::Scalar my $destination_table_height => 450;
Readonly::Scalar my $buffer_table_height      => 375;

extends 'wtsi_clarity::util::pdf_generator';

our $VERSION = '0.0';

override 'create' => sub {
  my $self = shift;

  my $font_bold = $self->pdf->corefont('Helvetica-Bold');
  my $font = $self->pdf->corefont('Helvetica');

  # for each output container, we produce a new page...
  foreach my $page_data (@{$self->pdf_data->{'pages'}}) {
    my $page = $self->pdf->page();
    $page->mediabox('A4');

    wtsi_clarity::util::pdf_generator::add_title_to_page($page, $font_bold, $page_data->{'title'});
    wtsi_clarity::util::pdf_generator::add_timestamp($page, $font, $self->pdf_data->{'stamp'});

    wtsi_clarity::util::pdf_generator::add_io_block_to_page($self->pdf, $page, $font_bold, $page_data->{'input_table'}, $page_data->{'input_table_title'}, $source_table_height);
    wtsi_clarity::util::pdf_generator::add_io_block_to_page($self->pdf, $page, $font_bold, $page_data->{'output_table'}, $page_data->{'output_table_title'}, $destination_table_height);

    wtsi_clarity::util::pdf_generator::add_buffer_block_to_page($self->pdf, $page, $font_bold, $page_data->{'plate_table'}, $page_data->{'plate_table_title'}, $page_data->{'plate_table_cell_styles'}, $buffer_table_height);
  }

  return $self->pdf;
};

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf_generator::worksheet

=head1 SYNOPSIS

  my $generator = wtsi_clarity::util::pdf_generator::worksheet->new(pdf_data => ... );
  my $file = $generator->create();

=head1 DESCRIPTION

  Creates a worksheet pdf document describing the plates.

=head1 SUBROUTINES/METHODS

=head2 pdf_data - hash describing the data to display
(see t/10-util-pdf_generator-worksheet.t for format)

=head2 create() - creates pdf file, which then can be saved using saveas().

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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

