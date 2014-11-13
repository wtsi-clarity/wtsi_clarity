package wtsi_clarity::epp::isc::pool_calculator;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::epp::generic::stamper;
use wtsi_clarity::file_parsing::ISC_pool_calculator;
use wtsi_clarity::isc::pooling::mapper;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_process';
with 'wtsi_clarity::util::well_mapper';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $FIRST_INPUT_LIMSID  => q(prc:process/input-output-map[1]/input/@limsid);
Readonly::Scalar my $FIRST_INPUT_URI     => q(prc:process/input-output-map[1]/input/@uri);
Readonly::Scalar my $FIRST_OUTPUT_LIMSID => q(prc:process/input-output-map[1]/output/@limsid);
Readonly::Scalar my $OUTPUT_ANALYTE_URIS => q(prc:process/input-output-map/output[@output-type="Analyte"]/@uri);
Readonly::Scalar my $CONTAINER_LIMSID    => q{/art:artifact/location/container/@limsid};
Readonly::Scalar my $PLATE_ROW_NUMBER    => 8;
Readonly::Scalar my $PLATE_COLUMN_NUMBER => 12;
## use critic

override 'run' => sub {
  my $self = shift;
  my %molarities = ();
  super();

  $molarities{$self->_container_id} = $self->_96_plate_molarities;

  my $pool_calculator = wtsi_clarity::file_parsing::ISC_pool_calculator->new(
    data             => \%molarities,
    mapping          => $self->_mapper->mapping,
    min_volume       => $self->min_volume,
    max_volume       => $self->max_volume,
    max_total_volume => $self->max_total_volume,
  );

  my ($output, $warnings) = $pool_calculator->get_volume_calculations_and_warnings();

  $self->_update_output_artifact_buffer_volumes($output);

  return 1;
};

### These three configuration options come from the GUI...
has 'min_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_min_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc, 'Minimum Volume')->textContent;
}

has 'max_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_max_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc, 'Maximum Volume')->textContent;
}

has 'max_total_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_max_total_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc, 'Maximum Total Volume')->textContent;
}
###

sub _update_output_artifact_buffer_volumes {
  my ($self, $output) = @_;

  while (my ($name, $wells) = each %{$output}) {
    while (my ($well, $pool_info_array) = each %{$output->{$name}}) {
      foreach my $pool_info (@{$pool_info_array}) {

        my $source_well = $pool_info->{'source_well'};

        my $artifact = $self->_output_artifacts
          ->findnodes("/art:details/art:artifact[location/value[text()='$source_well']]")
          ->pop();

        if (!defined $artifact) {
          carp "Couldn't find artifact at well $source_well";
          next;
        }

        my $buffer_volume_node =
          $self->create_udf_element($self->_output_artifacts, 'Buffer Volume', $pool_info->{'Volume'});

        $artifact->appendChild($buffer_volume_node);
      }
    }
  }

  return $self->request->batch_update('artifacts', $self->_output_artifacts);
}

has '_output_artifacts' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__output_artifacts {
  my $self = shift;
  my @output_artifact_uris = $self->process_doc->findnodes($OUTPUT_ANALYTE_URIS)->to_literal_list();
  return $self->request->batch_retrieve('artifacts', \@output_artifact_uris);
}

has '_mapper' => (
  is => 'ro',
  isa => 'wtsi_clarity::isc::pooling::mapper',
  lazy_build => 1,
);

sub _build__mapper {
  my $self = shift;
  return wtsi_clarity::isc::pooling::mapper->new( container_id => $self->_container_id );
}

has '_container_id' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build__container_id {
  my $self = shift;
  my $artifact_uri = $self->process_doc->findvalue($FIRST_INPUT_URI);
  my $artifact = $self->fetch_and_parse($artifact_uri);
  return $artifact->findvalue($CONTAINER_LIMSID);
}

has '_96_plate_molarities' => (
  is         => 'ro',
  isa        => 'HashRef',
  lazy_build => 1,
);

sub _build__96_plate_molarities {
  my $self = shift;
  my %plate_molarities;

  for (1..($PLATE_ROW_NUMBER * $PLATE_COLUMN_NUMBER)) {
    my $position = $self->position_to_well($_, $PLATE_ROW_NUMBER, $PLATE_COLUMN_NUMBER);
    my ($dest_well_1, $dest_well_2) = wtsi_clarity::epp::generic::stamper::calculate_destination_wells($self, $position);

    my $dest_well_1_molarity = $self->_384_plate_molarities->{$dest_well_1} || 0;
    my $dest_well_2_molarity = $self->_384_plate_molarities->{$dest_well_2} || 0;

    $plate_molarities{$position} = ($dest_well_1_molarity + $dest_well_2_molarity) / 2;
  }

  return \%plate_molarities;
}

has '_384_plate_molarities' => (
  is  => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

sub _build__384_plate_molarities {
  my $self = shift;
  my %well_molarities = ();
  my $molarities_calculated = 0;

  my $output_lims_ids = $self->_forked_plate_process_xml->findnodes($OUTPUT_ANALYTE_URIS)->to_literal_list();
  my $output_analytes = $self->request->batch_retrieve('artifacts', $output_lims_ids);

  my @artifact_list = $output_analytes->findnodes('art:details/art:artifact')->get_nodelist();

  foreach my $artifact (@artifact_list) {
    my $well = $artifact->findvalue('location/value');
    my $molarity = $artifact->findvalue('udf:field[@name="Molarity"]');

    if ($molarity eq q{}) {
      next;
    }

    # Just a little flag to check
    $molarities_calculated = 1;

    $well_molarities{$well} = $molarity;
  }

  if ($molarities_calculated == 0) {
    croak 'Molarities have not yet been obtained for forked plate';
  }

  return \%well_molarities;
}

has '_forked_plate_process_xml' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__forked_plate_process_xml {
  my $self = shift;

  my $first_input_lims_id = $self->process_doc->findvalue($FIRST_INPUT_LIMSID);
  my $post_lib_process_xml = $self->find_previous_process($first_input_lims_id, 'Post Lib PCR QC Stamp');

  if ($post_lib_process_xml == 0) {
    croak 'This plate has not been forked through Post Lib PCR QC Stamp';
  }

  my $first_output_lims_id = $post_lib_process_xml->findvalue($FIRST_OUTPUT_LIMSID);
  my $get_data_process_xml = $self->find_previous_process($first_output_lims_id, 'Post Lib PCR QC GetData');

  if ($get_data_process_xml == 0) {
    croak 'The fork of this plate has not yet been through Post Lib PRC QC';
  }

  return $get_data_process_xml;
}

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pool_calculator

=head1 SYNOPSIS

wtsi_clarity::epp::isc::pool_calculator->new(
  process_url => 'http://clarity.com/process'
)->run();

=head1 DESCRIPTION

 Fetches molarities from a forked plate, and calculaties an equi-molar pooling based on them.
 Updates an artifact's BUFFER VOLUME to tell a pooling step the volume to take from a plate

=head1 SUBROUTINES/METHODS

=head2 run - runs the process

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item Carp

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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