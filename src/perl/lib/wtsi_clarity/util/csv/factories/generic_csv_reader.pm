package wtsi_clarity::util::csv::factories::generic_csv_reader;

use Moose;
use Carp;
use Text::CSV;

our $VERSION = '0.0';

sub build {
  my ($self, %args) = @_;

  my $file_content = $args{'file_content'} || croak qq{Requires a file content!};

  my $csv_parser = Text::CSV->new();
  my $header_line = shift $file_content;
  $csv_parser->parse($header_line);
  my @headers = map { _cleanup_key($_) } $csv_parser->fields();

  my $output = [];

  foreach my $line (@{$file_content}) {
    chomp $line;
    $csv_parser->parse($line);
    my @values = $csv_parser->fields();
    my %hash;
    @hash{ @headers } = map { _cleanup_key($_) } @values;
    push @{$output}, \%hash;
  }
  return $output;
}

sub _cleanup_key {
  my $key = shift;
  $key =~ s/^\s+|\s+$//xmsg ;
  return $key;
}


1;

__END__

=head1 NAME

wtsi_clarity::util::csv::factories::generic_csv_reader

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::csv::factories::generic_csv_reader->new();
  $factory->build( file_content  => [ 'a,b', '1,2', '4.0, 5'], )

=head1 DESCRIPTION

  Class able to output the content given as an argument as a CSV text

=head1 SUBROUTINES/METHODS

=head2 build

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::util::textfile

=item Mojo::Collection

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