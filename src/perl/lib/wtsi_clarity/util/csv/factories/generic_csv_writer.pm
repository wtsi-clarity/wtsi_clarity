package wtsi_clarity::util::csv::factories::generic_csv_writer;

use Moose;
use wtsi_clarity::util::error_reporter qw/croak/;
use wtsi_clarity::util::textfile;
use Mojo::Collection;
use Data::Dumper;

our $VERSION = '0.0';

sub build {
  my ($self, %args) = @_;

  my $headers  = $args{'headers'} || croak( qq{Requires headers!});
  my $csv_data = $args{'data'}    || croak( qq{Requires some data to write down!});

  my $text_data = [];
  my $c_headers = Mojo::Collection->new(@{$headers});
  my $s_headers = $c_headers->join(', ');
  push @{$text_data},"$s_headers"; # quote are needed to stringify

  foreach my $datum (@{$csv_data}){
    my $c_datum = $c_headers->map(sub { $datum->{$_} })->join(', ');
    push @{$text_data},"$c_datum"; # quote are needed to stringify
  }

  return wtsi_clarity::util::textfile->new(content=>$text_data);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::csv::factories::generic_csv_writer

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::csv::factories::generic_csv_writer->new();
  $factory->build($csv_data);

=head1 DESCRIPTION

  Class able to output the content given as an argument as a CSV text

=head1 SUBROUTINES/METHODS

=head2 build

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::util::error_reporter

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