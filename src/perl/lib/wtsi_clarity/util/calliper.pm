package wtsi_clarity::util::calliper;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::util::csv::factory;

our $VERSION = '0.0';

has 'reader_type' => (
  is => 'ro',
  isa => 'Str',
  default => sub {
    return 'generic_reader';
  },
);

has 'headers' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub {
              return ['Plate Name', 'Well Label', 'Sample Name', 'Peak Count', 'Total Conc. (ng\/ul)', 'Region[200-1400] Molarity (nmol\/l)'];
                  },
);

sub interpret {
  my ($self, $file_content, $barcode) = @_;

  my $factory = wtsi_clarity::util::csv::factory->new();
  return $factory->create(type          => $self->reader_type,
                          headers       => $self->headers,
                          file_content  => $file_content,
                          barcode       => $barcode);
};

1;

__END__

=head1 NAME

wtsi_clarity::util::calliper

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::calliper->new();
  my $data = $factory->interpret($file_content, $barcode);

=head1 DESCRIPTION

  Class able to read output from a calliper robot. (Potentially, it can be used
  -once implemented- to write the calliper driver)

=head1 SUBROUTINES/METHODS

=head2 interpret

  transform some data into a valid object representing the calliper.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::csv::factory::generic_csv_writer

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