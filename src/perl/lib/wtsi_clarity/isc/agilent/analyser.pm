package wtsi_clarity::isc::agilent::analyser;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use Mojo::Collection 'c';

our $VERSION = '0.0';

=head2 mapping_details
  Description: Describes the mapping between the source plate
               and the differents output files
  Returntype : HashRef
=cut
has 'mapping_details' => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
);

=head2 files_content
  Description: maps the result file names with the LibXML::Document which represents them
  Returntype : HashRef
=cut
has 'files_content' => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
);

Readonly::Scalar my $SAMPLE_PATH  => q{/Chipset/Chips[1]/Chip[1]/Files[1]/File[1]/Samples[1]/Sample[Category='Sample']};
Readonly::Scalar my $PEAK_SUBPATH => qq{DAResultStructures[1]/DARIntegrator[1]/Channel[1]/PeaksMolecular[1]/PeakMolecular[2]};

sub get_analysis_results {
  my ($self) = @_;

  # for each well on the input plate (through the mapping details)
  my $t =c->new(keys %{$self->mapping_details})
          ->reduce(sub{
              my $source_well = $b;
              my $wells    = $self->mapping_details->{$source_well}{'wells'};
              my $filename = $self->mapping_details->{$source_well}{'file_path'};
              my $concentration = _average_of_measurement($self->_data_set, $filename, $source_well, $wells, 'concentration');
              my $molarity = _average_of_measurement($self->_data_set, $filename, $source_well, $wells, 'molarity');
              my $size = _average_of_measurement($self->_data_set, $filename, $source_well, $wells, 'size');
              $a->{$source_well} = {
                      'concentration' => $concentration,
                      'molarity' => $molarity,
                      'size' => $size,
                    };
              return $a;
            }, {} );

  return $t;
}

has '_data_set' => (
  is => 'ro',
  isa => 'HashRef',
  required => 0,
  lazy_build => 1,
);

sub _build__data_set {
  my ($self) = @_;

  # for each file
  return c->new(keys %{$self->files_content})
    ->reduce(sub{
      my $filename = $b;
      my $doc = $self->files_content->{$filename};
      my @well_xml_elements = $doc->findnodes($SAMPLE_PATH)->get_nodelist();

      # for each 'curve' found in the xml doc
      my $extracted_data = c->new(@well_xml_elements)
                ->reduce(sub{
                  my $element = $b;
                  my @names          = $element->find(qq{./WellNumber/text()})->get_nodelist();
                  my @concentrations = $element->find(qq{./$PEAK_SUBPATH/Concentration/text()})->get_nodelist();
                  my @molarities     = $element->find(qq{./$PEAK_SUBPATH/Molarity/text()}     )->get_nodelist();
                  my @fragmentsizes  = $element->find(qq{./$PEAK_SUBPATH/FragmentSize/text()} )->get_nodelist();

                  if (scalar @names != 1) {
                    croak qq{The number of 'WellNumber' tag is not correct. The XML '$filename' is not well formed.};
                  }

                  if (scalar @concentrations != 1) {
                    croak qq{The number of 'Concentration' tag is not correct. The XML '$filename' is not well formed.};
                  }

                  if (scalar @fragmentsizes != 1) {
                    croak qq{The number of 'FragmentSize' tag is not correct. The XML '$filename' is not well formed.};
                  }

                  if (scalar @molarities != 1) {
                    croak qq{The number of 'Molarity' tag is not correct. The XML '$filename' is not well formed.};
                  }

                  $a->{ $names[0]->textContent() } = {
                      'concentration' => $concentrations[0]->textContent,
                      'molarity' => $molarities[0]->textContent,
                      'size' => $fragmentsizes[0]->textContent,
                    };
                  return $a;
                }, {});

      $a->{$filename} = $extracted_data;
      return $a;
    }, {} );
}

sub _average_of_measurement {
  my ($data_set, $filename, $source_well, $output_wells, $measure) = @_;
  if (scalar @{$output_wells} == 0 ) {
    croak qq/One needs at least one output well value for the source well '$source_well' in $filename to calculate an average '$measure'./;
  }
  # simple 'reduce' to get the sum, then divide by the lentgth...
  return c ->new(@{$output_wells})
                ->reduce(sub{
                  my $chip_well_data = $data_set->{$filename}{$b};
                  if (!defined $chip_well_data) {
                    croak qq{The plate $filename is expected to contain a well $b!};
                  }
                  $a += $chip_well_data->{$measure};
                  return $a;
                }, 0) / (scalar @{$output_wells});
}

1;


__END__

=head1 NAME

wtsi_clarity::isc::agilent::analyser

=head1 SYNOPSIS

  my $mapping = {
    'A:1' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '1', '2' ]},
    'A:2' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '3', '4' ]},
    'A:3' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '5', '6' ]},
    'A:4' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '7', '8' ]},
    'A:5' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '11', '12' ]},
    'A:6' => { 'filename' => '1234567890_A1_B4', 'wells' => [ '9', '10' ]},
  };

  my $files_content = {
    '1234567890_A1_B4' => $parser->load_xml(...),
  };

  my $analyser = wtsi_clarity::isc::agilent::analyser->new(
    mapping_details => $mapping,
    files_content   => $files_content,
  );

  $analyser->get_analysis_results();

=head1 DESCRIPTION

  Module able to analyse the agilent results files and return the data describing the input plate.

=head1 SUBROUTINES/METHODS

=head2 get_analysis_results - return a hash representing the analysis results

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::util::clarity_elements;

=item Readonly

=item Mojo::Collection 'c';

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

