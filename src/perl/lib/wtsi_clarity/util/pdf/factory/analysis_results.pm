package wtsi_clarity::util::pdf::factory::analysis_results;

use Moose::Role;
use Carp;
use Readonly;

Readonly::Scalar our $HEADER_STYLE => q(HEADER_STYLE);
Readonly::Scalar my $NUMBER_OF_COLUMNS => 12;

our $VERSION = '0.0';

requires qw/table_header_row table_footer_row format_table_cell format_style_table_cell build/;

sub format_tables {
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
      } else {
        push @table_row, q{};
      }
    }

    push @formatted_table, \@table_row;
  }

  push @formatted_table, $table->{'footer_row'}->();

  return \@formatted_table;
}

sub table_row_first_column {
  my $row = shift;
  return $row;
}

sub headers_row {
  return [($HEADER_STYLE) x ($NUMBER_OF_COLUMNS+1)];
}

sub style_row_first_column {
  return $HEADER_STYLE;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::factory::analysis_results

=head1 SYNOPSIS

  use wtsi_clarity::util::pdf::factory::analysis_results;
  my $factory = wtsi_clarity::util::pdf::factory::pico_analysis_results->new();
  $factory->build($pdf_data);

=head1 DESCRIPTION

  Creates the pico analysis PDF

=head1 SUBROUTINES/METHODS

=head2 format_tables

=head2 table_row_first_column

=head2 headers_row

=head2 style_row_first_column

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