package wtsi_clarity::util::pdf_worksheet_generator;

use Moose;
use Carp;
use Readonly;
use PDF::API2;
use PDF::Table;

our $VERSION = '0.0';

Readonly::Scalar my $col_width                => 40;
Readonly::Scalar my $left_margin              => 20;
Readonly::Scalar my $title_height             => 780;
Readonly::Scalar my $title_size               => 20;
Readonly::Scalar my $stamp_height             => 760;
Readonly::Scalar my $stamp_size               => 8;
Readonly::Scalar my $subtitle_shift           => 20;
Readonly::Scalar my $subtitle_size            => 12;
Readonly::Scalar my $source_table_height      => 700;
Readonly::Scalar my $destination_table_height => 450;
Readonly::Scalar my $buffer_table_height      => 375;

has 'pdf_data' => (
  isa => 'HashRef',
  is => 'ro',
  required => 1,
);

sub _get_nb_row {
  my ($data) = @_;
  return scalar @{$data};
}

sub _get_nb_col {
  my ($data) = @_;
  return scalar @{$data->[0]};
}

sub create_worksheet_file {
  my ($self) = @_;
  my $pdf = PDF::API2->new();
  my $font_bold = $pdf->corefont('Helvetica-Bold');
  my $font = $pdf->corefont('Helvetica');


  # for each output container, we produce a new page...
  foreach my $page_data (@{$self->pdf_data->{'pages'}}) {
    my $page = $pdf->page();
    $page->mediabox('A4');

    _add_title_to_page($page, $font_bold, $page_data->{'title'});
    _add_timestamp(    $page, $font,      $self->pdf_data->{'stamp'});

    _add_io_block_to_page($pdf, $page, $font_bold, $page_data->{'input_table'},  $page_data->{'input_table_title'},  $source_table_height);
    _add_io_block_to_page($pdf, $page, $font_bold, $page_data->{'output_table'}, $page_data->{'output_table_title'}, $destination_table_height);

    _add_buffer_block_to_page($pdf, $page, $font_bold, $page_data->{'plate_table'}, $page_data->{'plate_table_title'}, $page_data->{'plate_table_cell_styles'}, $buffer_table_height);
  }
  return $pdf;
}
## no critic (Subroutines::ProhibitManyArgs)
sub _add_io_block_to_page {
  my ($pdf, $page, $font, $table_data, $table_title, $y_pos) = @_;
  _add_text_to_page($page, $font, $table_title, $left_margin, $y_pos+$subtitle_shift, $subtitle_size);
  _add_table_to_page($pdf, $page, $table_data,  $left_margin, $y_pos);
  return;
}

sub _add_buffer_block_to_page {
  my ($pdf, $page, $font, $table_data, $table_title, $table_cell_styles, $y_pos) = @_;
  _add_text_to_page($page, $font, $table_title, $left_margin, $y_pos+$subtitle_shift, $subtitle_size);
  my $properties = _transform_all_properties($table_cell_styles);
  _add_buffer_table_to_page($pdf, $page, $table_data, $properties , $y_pos);
  return;
}

sub _transform_all_properties {
  my ($data) = @_;
  my $table_properties = [];
  foreach my $j (0 .. _get_nb_row($data) - 1) {
    my $row_properties = [];
    foreach my $i (0 .. _get_nb_col($data) - 1) {
       push $row_properties, _transform_property($data->[$j]->[$i]);
    }
    push $table_properties, $row_properties;
  }

  return $table_properties;
}

sub _transform_property {
  my $property = shift ;
  my @list_of_colours = ('#F5BA7F', '#F5E77D', '#7DD3F5', '#DB7DF5', '#F57FBA', '#F57DE7', '#F57DD3', '#7DF5DB');
  my $pdf_property ;

  for ($property) {
    /HEADER_STYLE|EMPTY_STYLE/xms and do {
        $pdf_property = {
          background_color => 'white',
          font_size=> 7,
          justify => 'center',
        };
        last;
      };

    /COLOUR_(\d+)/xms and do {
        $pdf_property = {
          background_color => $list_of_colours[$1],
          font_size=> 7,
          justify => 'center',
        };
        last;
      };
  }

  return $pdf_property;
}

sub _add_title_to_page {
  my ($page, $font, $title) = @_;
  _add_text_to_page($page, $font, $title, $left_margin, $title_height, $title_size);
  return;
}

sub _add_timestamp {
  my ($page, $font, $stamp) = @_;
  _add_text_to_page($page, $font, $stamp, $left_margin, $stamp_height, $stamp_size);
  return;
}

sub _add_buffer_table_to_page {
  my ($pdf, $page, $data, $table_properties, $y) = @_;
  my $pdftable = PDF::Table->new();
  my @table_data = @{$data}; # this pdf library eats the array ! So we need to give it a copy!

  my $nb_core_col = _get_nb_col(\@table_data) - 2;
  my $nb_core_row = _get_nb_row(\@table_data) - 2;

  $pdftable->table(
    # required params
    $pdf, $page, \@table_data,

    x => $left_margin,
    w => ($nb_core_col + 1)*$col_width,
    start_y => $y,
    start_h => 375,
    padding => 2,
    font  =>      $pdf->corefont('Courier-Bold', -encoding => 'latin1'),
    cell_props => $table_properties,
    column_props => [
      { min_w => $col_width/2, max_w => $col_width/2, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width/2, max_w => $col_width/2, },
    ]
  );
  return;
}

sub _add_table_to_page {
  my ($pdf, $page, $data, $x, $y) = @_;
  my $pdftable_source = PDF::Table->new();
  my @local_data = @{$data}; # this pdf library eats the array ! So we need to give it a copy!

  $pdftable_source->table(
    $pdf, $page, \@local_data,
    x => $x, w => 400,
    start_y    => $y,
    start_h    => 100,
    font_size  => 9,
    padding    => 4,
    font       => $pdf->corefont('Helvetica', -encoding => 'latin1'),
  );

  return;
}

sub _add_text_to_page {
  my ($page, $font, $content, $x, $y, $font_size) = @_;
  my $text = $page->text();
  $text->font($font, $font_size);
  $text->translate($x, $y);
  $text->text($content);
  return;
}
## use critic

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf_worksheet_generator

=head1 SYNOPSIS

  my $generator = wtsi_clarity::util::pdf_worksheet_generator->new(pdf_data => ... );
  my $file = $generator->create_worksheet_file();

=head1 DESCRIPTION

  Creates a pdf document describing the plates.

=head1 SUBROUTINES/METHODS

=head2 pdf_data - hash describing the data to display
(see t/10-util-pdf_worksheet_generator.t for format)

=head2 create_worksheet_file() - creates pdf file, which then can be saved using saveas().

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item PDF::API2

=item PDF::Table

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

