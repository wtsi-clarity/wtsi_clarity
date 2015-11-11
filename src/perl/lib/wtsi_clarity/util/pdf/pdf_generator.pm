package wtsi_clarity::util::pdf::pdf_generator;

use Moose;
use Carp;
use Readonly;
use PDF::API2;
use PDF::Table;
use DateTime;

our $VERSION = '0.0';

Readonly::Scalar my $left_margin              => 20;

Readonly::Scalar my $font_normal              => 'Helvetica';
Readonly::Scalar my $font_bold                => 'Helvetica-Bold';

Readonly::Scalar my $title_height             => 40;
Readonly::Scalar my $title_size               => 15;

Readonly::Scalar my $subtitle_shift           => 10;
Readonly::Scalar my $subtitle_size            => 10;

Readonly::Scalar my $stamp_size               => 8;
Readonly::Scalar my $stamp_height             => 20;

Readonly::Scalar my $A4_LANDSCAPE_HEIGHT      => 8.27;
Readonly::Scalar my $A4_LANDSCAPE_WIDTH       => 11.7;
Readonly::Scalar my $DPI_RESOLUTION           => 72;


# TODO revert it back as required => 1
has 'pdf_data' => (
  isa      => 'HashRef',
  is       => 'ro',
  required => 0,
);

has 'pdf' => (
  isa      => 'PDF::API2',
  is       => 'ro',
  default   => sub {
    return PDF::API2->new();
  },
  required => 0,
);

has 'cell_font_size' => (
  isa       => 'Int',
  is        => 'rw',
  default   => 7,
);

has 'col_width' => (
  isa       => 'Int',
  is        => 'rw',
  default   => 30,
);

has 'page_height' => (
  isa       => 'Int',
  is        => 'rw',
  default   => 840,
);

has 'stamp' => (
  is      => 'rw',
  default => sub {
    my $date = DateTime->now->strftime('%A %d-%B-%Y at %H:%M:%S');

    return qq{This file was created on $date};
  },
);

sub A4_LANDSCAPE {
  return (0, 0, $A4_LANDSCAPE_WIDTH * $DPI_RESOLUTION, $A4_LANDSCAPE_HEIGHT * $DPI_RESOLUTION);
}

sub get_nb_row {
  my ($self, $data) = @_;
  return scalar @{$data};
}

sub get_nb_col {
  my ($self, $data) = @_;
  return scalar @{$data->[0]};
}

## no critic (Subroutines::ProhibitManyArgs)
sub add_io_block_to_page {
  my ($self, $pdf, $page, $table_data, $table_title, $y_pos) = @_;

  $self->add_text_to_page($page, $self->pdf->corefont($font_bold), $table_title, $left_margin, $y_pos, $subtitle_size);
  $self->add_table_to_page($pdf, $page, $table_data, $left_margin, $y_pos + $subtitle_shift);
  return;
}

sub add_buffer_block_to_page {
  my ($self, $pdf, $page, $table_data, $table_title, $table_cell_styles, $y_pos) = @_;

  $self->add_text_to_page($page, $self->pdf->corefont($font_bold), $table_title, $left_margin, $y_pos , $subtitle_size);
  my $properties = $self->transform_all_properties($table_cell_styles);
  $self->add_buffer_table_to_page($pdf, $page, $table_data, $properties, $y_pos + $subtitle_shift);
  return;
}

sub transform_all_properties {
  my ($self, $data) = @_;
  my $table_properties = [];
  foreach my $j (0 .. $self->get_nb_row($data) - 1) {
    my $row_properties = [];
    foreach my $i (0 .. $self->get_nb_col($data) - 1) {
      push $row_properties, $self->transform_property($data->[$j]->[$i]);
    }
    push $table_properties, $row_properties;
  }

  return $table_properties;
}

sub transform_property {
  my ($self, $property) = @_;
  # orange, yellow, blue, magenta, pink, a different shade of magenta, a different shade of pink, cyan, light green, red, green2, green3
  my @list_of_colours = ('#F5BA7F', '#F5E77D', '#7DD3F5', '#DB7DF5', '#F57FBA', '#F57DE7', '#F57DD3', '#7DF5DB', '#1FB714', '#DD0806', '#339966', '#99CC00');
  my $pdf_property;

  for ($property) {
    /HEADER_STYLE|EMPTY_STYLE/xms and do {
      $pdf_property = {
        background_color => 'white',
        font_size => $self->cell_font_size(),
        justify => 'center',
      };
      last;
    };

    /COLOUR_(\d+)/xms and do {
      $pdf_property = {
        background_color => $list_of_colours[$1],
        font_size => $self->cell_font_size(),
        justify => 'center',
      };
      last;
    };

    /PASSED/xms and do {
      $pdf_property = {
        background_color => '#175C08',
        font_size => $self->cell_font_size(),
        justify => 'center',
        font_color => '#FFF',
      };
      last;
    };

    /FAILED/xms and do {
      $pdf_property = {
        background_color => '#6B0200',
        font_size => $self->cell_font_size(),
        justify => 'center',
        font_color => '#FFF',
      }
    }
  }

  return $pdf_property;
}

sub add_title_to_page {
  my ($self, $page, $title) = @_;
  $self->add_text_to_page($page, $self->pdf->corefont($font_bold), $title, $left_margin, $title_height, $title_size);
  return;
}

sub add_timestamp {
  my ($self, $page) = @_;
  $self->add_text_to_page($page, $self->pdf->corefont($font_normal), $self->stamp(), $left_margin, $stamp_height, $stamp_size);
  return;
}

sub add_buffer_table_to_page {
  my ($self, $pdf, $page, $data, $table_properties, $y) = @_;
  my $y_pos = $self->page_height - $y;

  my $pdftable = PDF::Table->new();
  my @table_data = @{$data}; # this pdf library eats the array ! So we need to give it a copy!

  my $nb_core_col = $self->get_nb_col(\@table_data) - 2;

  $pdftable->table(
    # required params
    $pdf, $page, \@table_data,

    x => $left_margin,
    w => ($nb_core_col + 1) * $self->col_width(),
    start_y => $y_pos,
    start_h => 600,
    padding => 1,
    font  =>      $pdf->corefont('Courier-Bold', -encoding => 'latin1'),
    cell_props => $table_properties,
    column_props => [
      { min_w => 0, max_w => $self->col_width() / 2, },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => $self->col_width(), max_w => $self->col_width(), },
      { min_w => 0, max_w => $self->col_width() / 2, },
    ]
  );
  return;
}

sub add_table_to_page {
  my ($self, $pdf, $page, $data, $x_pos, $y) = @_;
  my $y_pos = $self->page_height - $y;

  my $pdftable_source = PDF::Table->new();
  my @local_data = @{$data}; # this pdf library eats the array ! So we need to give it a copy!

  $pdftable_source->table(
    $pdf, $page, \@local_data,
    x => $x_pos, w => 400,
    start_y    => $y_pos,
    start_h    => 100,
    font_size  => 9,
    padding    => 4,
    font       => $pdf->corefont('Helvetica', -encoding => 'latin1'),
  );

  return;
}

sub add_text_to_page {
  my ($self, $page, $font, $content, $x_pos, $y, $font_size) = @_;
  my $y_pos = $self->page_height - $y;

  my $text = $page->text();
  $text->font($font, $font_size);
  $text->translate($x_pos, $y_pos);
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

=head2 A4_LANDSCAPE

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

