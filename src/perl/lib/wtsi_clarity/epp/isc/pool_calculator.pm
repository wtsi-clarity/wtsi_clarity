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
Readonly::Scalar my $INPUT_OUTPUT_PATH   => q{prc:process/input-output-map};
Readonly::Scalar my $INPUT_LIMSID        => q{./input/@limsid};
Readonly::Scalar my $OUTPUT_LIMSID       => q{./output/@limsid};
Readonly::Scalar my $FIRST_INPUT_LIMSID  => q(prc:process/input-output-map[1]/input/@limsid);
Readonly::Scalar my $FIRST_INPUT_URI     => q(prc:process/input-output-map[1]/input/@uri);
Readonly::Scalar my $FIRST_OUTPUT_LIMSID => q(prc:process/input-output-map[1]/output/@limsid);
Readonly::Scalar my $OUTPUT_ANALYTE_URIS => q(prc:process/input-output-map/output[@output-type="Analyte"]/@uri);
Readonly::Scalar my $ALL_ANALYTES        => q(prc:process/input-output-map/output[@output-type="Pool"]/@uri | prc:process/input-output-map/input/@uri);
Readonly::Scalar my $CONTAINER_LIMSID    => q{/art:artifact/location/container/@limsid};
Readonly::Scalar my $ARTIFACT_BY_LIMSID  => q{art:details/art:artifact[@limsid="%s"]};
Readonly::Scalar my $PLATE_ROW_NUMBER    => 8;
Readonly::Scalar my $PLATE_COLUMN_NUMBER => 12;
## use critic

sub get_volume_calculations_and_warnings {
  my $self = shift;
  my %molarities = ();
  super();

  $molarities{$self->_container_id} = $self->_96_plate_molarities;

  my $pool_calculator = wtsi_clarity::file_parsing::ISC_pool_calculator->new(
    data             => \%molarities,
    mapping          => $self->_mapping,
    min_volume       => $self->min_volume,
    max_volume       => $self->max_volume,
    max_total_volume => $self->max_total_volume,
  );

  return $pool_calculator->get_volume_calculations_and_warnings();
};

has '_mapping' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  lazy_build => 1,
);

sub _build__mapping {
  my $self = shift;

  my @mapping = map {
    my $input_analyte = $self->_analytes->findnodes(sprintf $ARTIFACT_BY_LIMSID, $_->[0])->pop();
    my $output_analyte = $self->_analytes->findnodes(sprintf $ARTIFACT_BY_LIMSID, $_->[1])->pop();

    {
      'source_plate' => $input_analyte->findvalue('./location/container/@limsid'),
      'source_well'  => $input_analyte->findvalue('./location/value'),
      'dest_plate'   => $output_analyte->findvalue('./location/container/@limsid'),
      'dest_well'    => $output_analyte->findvalue('./location/value'),
    };

  } @{$self->_input_output_map};

  return \@mapping;
}

has '_input_output_map' => (
  is => 'ro',
  isa => 'ArrayRef[ArrayRef]',
  lazy_build => 1,
);

sub _build__input_output_map {
  my $self = shift;

  my @input_output_map = map {
    [$_->findvalue($INPUT_LIMSID), $_->findvalue($OUTPUT_LIMSID)]
  } $self->process_doc->findnodes($INPUT_OUTPUT_PATH)->get_nodelist;

  return \@input_output_map;
}

has '_analytes' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__analytes {
  my $self = shift;
  my @all_analyte_uris = $self->process_doc->findnodes($ALL_ANALYTES)->get_nodelist;
  my @uris = map { $_->getValue() } @all_analyte_uris;
  return $self->request->batch_retrieve('artifacts', \@uris);
}

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

  my $output_lims_ids = $self->_forked_plate_process_xml->findnodes($OUTPUT_ANALYTE_URIS)->to_literal_list();
  my $output_analytes = $self->request->batch_retrieve('artifacts', $output_lims_ids);

  my @artifact_list = $output_analytes->findnodes('art:details/art:artifact')->get_nodelist();

  foreach my $artifact (@artifact_list) {
    my $well = $artifact->findvalue('location/value');
    my $molarity = $artifact->findvalue('udf:field[@name="Molarity"]');

    if ($molarity eq q{}) {
      next;
    }

    $well_molarities{$well} = $molarity;
  }

  if (scalar keys %well_molarities == 0) {
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

  my $pool_calculator = wtsi_clarity::epp::isc::pool_calculator->new(
    process_doc => $process_doc
  );

  $pool_calculator->get_volume_calculations_and_warnings();

=head1 DESCRIPTION

 Fetches molarities from a forked plate, and calculaties an equi-molar pooling based on them.

=head1 SUBROUTINES/METHODS

=head2 run - runs the process. Returns the warnings and volumes from the pool calculator

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item Carp

=item wtsi_clarity::epp::generic::stamper;

=item wtsi_clarity::file_parsing::ISC_pool_calculator;

=item wtsi_clarity::isc::pooling::mapper;

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