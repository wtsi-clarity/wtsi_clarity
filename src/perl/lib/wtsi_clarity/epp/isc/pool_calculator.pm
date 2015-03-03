package wtsi_clarity::epp::isc::pool_calculator;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::epp::generic::stamper;
use wtsi_clarity::file_parsing::ISC_pool_calculator;
use wtsi_clarity::isc::pooling::mapper;
use List::Util qw/sum/;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::well_mapper';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_ARTIFACT_URIS => q{prc:process/input-output-map/input/@uri};
Readonly::Scalar my $FIRST_INPUT_LIMSID  => q(prc:process/input-output-map[1]/input/@limsid);
Readonly::Scalar my $FIRST_INPUT_URI     => q(prc:process/input-output-map[1]/input/@uri);
Readonly::Scalar my $FIRST_OUTPUT_LIMSID => q(prc:process/input-output-map[1]/output/@limsid);
Readonly::Scalar my $OUTPUT_ANALYTE_URIS => q(prc:process/input-output-map/output[@output-type="Analyte"]/@uri);
Readonly::Scalar my $CONTAINER_LIMSID    => q{/art:artifact/location/container/@limsid};
Readonly::Scalar my $MOLARITY_UDF_PATH   => q{/art:details/art:artifact/udf:field[@name="Molarity"]};
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
    mapping          => $self->process_doc->io_map,
    min_volume       => $self->min_volume,
    max_volume       => $self->max_volume,
    max_total_volume => $self->max_total_volume,
  );

  return $pool_calculator->get_volume_calculations_and_warnings();
};

### These three configuration options come from the GUI...
has 'min_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_min_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc->xml, 'Minimum Volume')->textContent;
}

has 'max_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_max_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc->xml, 'Maximum Volume')->textContent;
}

has 'max_total_volume' => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);

sub _build_max_total_volume {
  my $self = shift;
  return $self->find_udf_element($self->process_doc->xml, 'Maximum Total Volume')->textContent;
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

  foreach my $artifact ($self->_input_analytes->findnodes('/art:details/art:artifact')->get_nodelist) {
    my $tube_position = $artifact->findvalue('./location/value');
    my $molarity = $self->_fetch_molarities($artifact);
    $plate_molarities{$tube_position} = $molarity;
  }

  return \%plate_molarities;
}

sub _fetch_molarities {
  my $self = shift;
  my $artifact_element = shift;
  my @molarities = ();

  my $sample_id = $artifact_element->findvalue('./sample/@limsid');

  my $artifact_list = $self->request->query_resources(
        q{artifacts},
        {
          sample_id => $sample_id,
          udf       => 'udf.Molarity.min=0',
          type      => 'Analyte',
        }
  );

  my @nodelist = $artifact_list->findnodes('art:artifacts/artifact/@uri')->to_literal_list;

  if (scalar @nodelist > 2) {
    croak "Getting molarities of plates that have been through Calliper twice is not yet supported";
  }

  if (scalar @nodelist == 0) {
    return 0;
  }

  my $artifacts_with_molarities = $self->request->batch_retrieve('artifacts', \@nodelist);

  foreach my $molarity ($artifacts_with_molarities->findnodes($MOLARITY_UDF_PATH)->get_nodelist) {
    push @molarities, $molarity->textContent;
  }

  my $total = sum(@molarities);
  my $no_of_molarities = scalar @molarities;

  my $average =  $total / $no_of_molarities;

  return $average;
}

has '_input_analytes' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build__input_analytes {
  my $self = shift;
  my $uris = $self->process_doc->findnodes($INPUT_ARTIFACT_URIS)->to_literal_list;
  return $self->request->batch_retrieve('artifacts', $uris);
}

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::pool_calculator

=head1 SYNOPSIS

  my $pool_calculator = wtsi_clarity::epp::isc::pool_calculator->new(
    process_xml => $process_xml
  );

  $pool_calculator->get_volume_calculations_and_warnings();

=head1 DESCRIPTION

 Fetches molarities from a forked plate, and calculaties an equi-molar pooling based on them.

=head1 SUBROUTINES/METHODS

=head2 get_volume_calculations_and_warnings - Returns the warnings and volumes from the pool calculator

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