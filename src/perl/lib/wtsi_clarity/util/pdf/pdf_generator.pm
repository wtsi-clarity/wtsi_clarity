package wtsi_clarity::util::pdf::pdf_generator;

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

has 'pdf_data' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 1,
);

has 'pdf' => (
  isa      => 'PDF::API2',
  is       => 'ro',
  default   => sub { return PDF::API2->new(); },
  required => 0,
);

sub get_nb_row {
  my ($data) = @_;
  return scalar @{$data};
}

sub get_nb_col {
  my ($data) = @_;
  return scalar @{$data->[0]};
}

## no critic (Subroutines::ProhibitManyArgs)
sub add_io_block_to_page {
  my ($pdf, $page, $font, $table_data, $table_title, $y_pos) = @_;
  add_text_to_page($page, $font, $table_title, $left_margin, $y_pos+$subtitle_shift, $subtitle_size);
  add_table_to_page($pdf, $page, $table_data,  $left_margin, $y_pos);
  return;
}

sub add_buffer_block_to_page {
  my ($pdf, $page, $font, $table_data, $table_title, $table_cell_styles, $y_pos) = @_;
  add_text_to_page($page, $font, $table_title, $left_margin, $y_pos+$subtitle_shift, $subtitle_size);
  my $properties = transform_all_properties($table_cell_styles);
  add_buffer_table_to_page($pdf, $page, $table_data, $properties , $y_pos);
  return;
}

sub transform_all_properties {
  my ($data) = @_;
  my $table_properties = [];
  foreach my $j (0 .. get_nb_row($data) - 1) {
    my $row_properties = [];
    foreach my $i (0 .. get_nb_col($data) - 1) {
       push $row_properties, transform_property($data->[$j]->[$i]);
    }
    push $table_properties, $row_properties;
  }

  return $table_properties;
}

sub transform_property {
  my $property = shift ;
  # orange, yellow, blue, magenta, pink, a different shade of magenta, a different shade of pink, cyan
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

    /PASSED/xms and do {
      $pdf_property = {
        background_color => '#175C08',
        font_size => 7,
        justify => 'center',
        font_color => '#FFF',
      };
      last;
    };

    /FAILED/xms and do {
      $pdf_property = {
        background_color => '#6B0200',
        font_size => 7,
        justify => 'center',
        font_color => '#FFF',
      }
    }
  }

  return $pdf_property;
}

sub add_title_to_page {
  my ($page, $font, $title) = @_;
  add_text_to_page($page, $font, $title, $left_margin, $title_height, $title_size);
  return;
}

sub add_timestamp {
  my ($page, $font, $stamp) = @_;
  add_text_to_page($page, $font, $stamp, $left_margin, $stamp_height, $stamp_size);
  return;
}

sub add_buffer_table_to_page {
  my ($pdf, $page, $data, $table_properties, $y) = @_;
  my $pdftable = PDF::Table->new();
  my @table_data = @{$data}; # this pdf library eats the array ! So we need to give it a copy!

  my $nb_core_col = get_nb_col(\@table_data) - 2;
  my $nb_core_row = get_nb_row(\@table_data) - 2;

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

sub add_table_to_page {
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

sub add_text_to_page {
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

wtsi_clarity::util::pdf::pdf_generator

=head1 SYNOPSIS

  my $generator = wtsi_clarity::util::pdf::pdf_generator->new(pdf_data => ... );
  my $file = $generator->create();

=head1 DESCRIPTION

  Abstract base class to create a pdf document

=head1 SUBROUTINES/METHODS

=head2 pdf_data - hash describing the data to display
(see t/10-util-pdf_worksheet_generator.t for format)

=head2 create() - creates pdf file, which then can be saved using saveas(). Must be overriden.

=head2 add_buffer_block_to_page

=head2 add_buffer_table_to_page

=head2 add_io_block_to_page

=head2 add_table_to_page

=head2 add_text_to_page

=head2 add_timestamp

=head2 add_title_to_page

=head2 get_nb_col

=head2 get_nb_row

=head2 transform_all_properties

=head2 transform_property

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

