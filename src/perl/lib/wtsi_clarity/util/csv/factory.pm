package wtsi_clarity::util::csv::factory;

use Moose;
use Carp;
use Readonly;
use Data::Dumper;

use wtsi_clarity::util::csv::factories::generic_csv_writer;
use wtsi_clarity::util::csv::factories::generic_csv_reader;
use wtsi_clarity::util::csv::factories::calliper_csv_reader;

our $VERSION = '0.0';

sub create {
  my ($self, %args) = @_;

  my $csv_type = $args{'type'} || croak qq{Requires a csv type to generate an instance !};

  my $csv_factory;

  ##no critic ControlStructures::ProhibitCascadingIfElse
  if ( $csv_type eq 'beckman_writer') {
    $csv_factory = wtsi_clarity::util::csv::factories::generic_csv_writer->new();
  } elsif ( $csv_type eq 'report_writer') {
    $csv_factory = wtsi_clarity::util::csv::factories::generic_csv_writer->new();
  } elsif ( $csv_type eq 'generic_reader') {
    $csv_factory = wtsi_clarity::util::csv::factories::generic_csv_reader->new();
  } elsif ( $csv_type eq 'calliper_reader') {
    $csv_factory = wtsi_clarity::util::csv::factories::calliper_csv_reader->new();
  } elsif ( $csv_type eq 'fluidigm_writer') {
    $csv_factory = wtsi_clarity::util::csv::factories::generic_csv_writer->new();
  } else {
    croak "CSV file of type $csv_type cannot be created";
  }
  ##use critic

  return $csv_factory->build(%args);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::csv::factory

=head1 SYNOPSIS

  use wtsi_clarity::util::csv::factory;
  my $csv_doc = wtsi_clarity::util::csv::factory->create('csv_type', data);

=head1 DESCRIPTION

  Creates the specified CSV

=head1 SUBROUTINES/METHODS

=head2 create

  main method of the factory. Returns the desired instance.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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