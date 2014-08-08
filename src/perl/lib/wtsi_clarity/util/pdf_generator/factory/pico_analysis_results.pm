package wtsi_clarity::util::pdf_generator::factory::pico_analysis_results;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::pdf_generator::pico_analysis_results;

Readonly::Scalar our $HEADER_STYLE => q(HEADER_STYLE);
Readonly::Scalar our $NUMBER_OF_COLUMNS => 12;

our $VERSION = '0.0';

has 'plate_table' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  default => sub {
    my $self = shift;

    return {
      header_row => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::table_header_row,
      row_first_column => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::table_row_first_column,
      format_cell => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::format_table_cell,
      footer_row => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::table_footer_row,
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
      header_row => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::headers_row,
      row_first_column => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::style_row_first_column,
      format_cell => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::format_style_table_cell,
      footer_row => \&wtsi_clarity::util::pdf_generator::factory::pico_analysis_results::headers_row,
    }
  },
);

sub build {
  my ($self, $parameters) = @_;

  my ($plate_table, $plate_table_cell_styles) = $self->_format_tables($parameters);

  my $pdf_data = {
    'stamp' => 'Something',
    'pages' => [
      {
        'title' => 'Picogreen Analysis',
        'plate_table_title' => 'Table',
        'plate_table' => $plate_table,
        'plate_table_cell_styles' => $plate_table_cell_styles,
      }
    ]
  };

  my $pico_pdf_generator = wtsi_clarity::util::pdf_generator::pico_analysis_results->new(pdf_data => $pdf_data);
  return $pico_pdf_generator->create();
}

sub _format_tables {
  my ($self, $plate_table_info) = @_;

  return (
    $self->_format($self->plate_table, $plate_table_info),
    $self->_format($self->plate_style_table, $plate_table_info),
  );
}

sub _format {
  my ($self, $table, $table_info) = @_;

  my @formatted_table = ();
  push @formatted_table, $table->{'header_row'}->();

  foreach my $row_letter ('A'..'H') {
    my @table_row = ();

    push @table_row, $table->{'row_first_column'}->($row_letter);

    foreach my $column_number (1..$NUMBER_OF_COLUMNS) {
      my $cell = join q{:}, $row_letter, $column_number;

      if (exists $table_info->{$cell}) {
        push @table_row, $table->{'format_cell'}->($table_info->{$cell});
      }
    }

    push @formatted_table, \@table_row;
  }

  push @formatted_table, $table->{'footer_row'}->();

  return \@formatted_table;
}

sub table_header_row {
  return [0..$NUMBER_OF_COLUMNS];
}

sub table_row_first_column {
  my $row = shift;
  return $row;
}

sub table_footer_row {
  my @row = ();
  push @row, q{*};
  push @row, 1..$NUMBER_OF_COLUMNS;
  return \@row;
}

sub format_table_cell {
  my $cell = shift;
  return join "\n", $cell->{'concentration'}, $cell->{'cv'}, $cell->{'status'};
}

sub headers_row {
  return [($HEADER_STYLE) x ($NUMBER_OF_COLUMNS+1)];
}

sub style_row_first_column {
  return $HEADER_STYLE;
}

sub format_style_table_cell {
  my $cell = shift;
  return uc $cell->{'status'};
}

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf_generator::factory::pico_analysis_results

=head1 SYNOPSIS
  
  use wtsi_clarity::util::pdf_generator::factory::pico_analysis_results;
  my $factory = wtsi_clarity::util::pdf_generator::factory::pico_analysis_results->new();
  $factory->build($pdf_data);
  
=head1 DESCRIPTION

  Creates the pico analysis PDF 

=head1 SUBROUTINES/METHODS

=head2 build

=head2 format_style_table_cell

=head2 format_table_cell

=head2 headers_row

=head2 style_row_first_column

=head2 table_footer_row

=head2 table_header_row

=head2 table_row_first_column

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