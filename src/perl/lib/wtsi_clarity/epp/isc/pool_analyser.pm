package wtsi_clarity::epp::isc::pool_analyser;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::util::pdf::factory::pool_analysis_results;
use wtsi_clarity::dao::sample_dao;
use wtsi_clarity::dao::study_dao;

our $VERSION = '0.0';

extends 'wtsi_clarity::epp';

has 'analysis_file' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

override 'run' => sub {
  my $self = shift;
  super();

  # Pass the results to the PDF generator
  my $pdf = wtsi_clarity::util::pdf::factory::pool_analysis_results->new()->build($self->_get_parameters());

  # Attach PDF to process
  $pdf->saveas(q{./} . $self->analysis_file);

  return;
};

sub _get_parameters {
  my $self = shift;

  my $results = ();

  for my $i (0..scalar @{$self->process_doc->plate_io_map} - 1) {
    my $input_table_data = ();

    my $plate_id = $self->process_doc->plate_io_map->[$i]->{'source_plate'};
    my $barcode = $self->process_doc->plate_io_map_barcodes->[$i]->{'source_plate'};
    my $signature = $self->process_doc->get_container_signature_by_limsid($plate_id);

    $input_table_data->[0] = $plate_id;
    $input_table_data->[1] = $barcode;
    $input_table_data->[2] = $signature;

    $results->{$plate_id}->{'input_table_data'} = $input_table_data;
  }

  foreach my $io_element (@{$self->process_doc->io_map}) {
    my $sample_dao = wtsi_clarity::dao::sample_dao->new( lims_id => $io_element->{'source_well_sample_limsid'});
    my $study_dao = wtsi_clarity::dao::study_dao->new( lims_id => $sample_dao->project_limsid);

    my $plate_table_element = ();
    $plate_table_element->{'pooled_into'} = $io_element->{'dest_well'};
    $plate_table_element->{'study_name'} = $study_dao->name;
    $plate_table_element->{'sample_name'} = $sample_dao->name;
    $plate_table_element->{'organism'} = $sample_dao->organism;
    $plate_table_element->{'bait_library_name'} = $sample_dao->bait_library_name;

    $results->{$io_element->{'source_plate'}}->{'plate_table_data'}->{$io_element->{'source_well'}} = $plate_table_element;
  }

  my @values = values %{$results};

  return \@values;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pool_analyser

=head1 SYNOPSIS

  my $pooler = wtsi_clarity::epp::isc::pool_analyser->new(
    analysis_file => '122-22674',
    process_url => $base_uri . '/processes/122-21977',
  );

=head1 DESCRIPTION

  This module is creates a pdf document describing the plate, and upload it on the server.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::dao::sample_dao;

=item wtsi_clarity::dao::study_dao;

=item wtsi_clarity::util::pdf::factory::pool_analysis_results

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
