package wtsi_clarity::util::report;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::util::csv::factory;

our $VERSION = '0.0';

has 'writer_type' => (
  is      => 'ro',
  isa     => 'Str',
  default => sub {
    return 'report_writer';
  },
);

has 'headers' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub {
              return [  "Status",
                "Study",
                "Supplier",
                "Sanger Sample Name",
                "Supplier Sample Name",
                "Plate",
                "Well",
                "Supplier Volume",
                "Supplier Gender",
                "Concentration",
                "Measured Volume",
                "Total micrograms",
                "Fluidigm Count",
                "Fluidigm Gender",
                # "Pico",
                # "Gel",
                # "Qc Status",
                # "QC started date",
                # "Pico date",
                # "Gel QC date",
                # "Seq stamp date",
                "Genotyping Status",
                "Genotyping Chip",
                "Genotyping Infinium Barcode",
                "Genotyping Barcode",
                "Genotyping Well Cohort",
                "Proceed"
                # "Country of Origin",
                # "Geographical Region",
                # "Ethnicity",
                # "DNA Source",
                # "Is Resubmitted",
                # "Control",
                ];
              },
);

sub get_file {
  my ($self, $csv_data) = @_;

  my $factory = wtsi_clarity::util::csv::factory->new();
  return $factory->create(type    => $self->writer_type,
                          headers => $self->headers,
                          data    => $csv_data );
};

1;

__END__

=head1 NAME

wtsi_clarity::util::report

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::report->new();
  my $file = $factory->get_file($data); # returns a wtsi_clarity::util::textfile

=head1 DESCRIPTION

  Class able to creates reports. (Potentially, it can be used
  -once implemented- to read the report output too)

=head1 SUBROUTINES/METHODS

=head2 get_file

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