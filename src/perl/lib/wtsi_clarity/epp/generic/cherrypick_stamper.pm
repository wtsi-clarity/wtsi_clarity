package wtsi_clarity::epp::generic::cherrypick_stamper;

use Moose;
use Readonly;
use Carp;
use XML::LibXML;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::epp::generic::stamper_common';

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $IO_MAP_PATH              => q{ /prc:process/input-output-map[output[@output-type='Analyte']]};
Readonly::Scalar my $OUTPUT_ANALYTE_URI_PATH  => q{./output/@uri};
##use critic

Readonly::Scalar my $PLATE_96_WELL            => q{96 Well Plate};

our $VERSION = '0.0';

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  $self->post_placement_doc($self->build_placement_xml);

  return;
};


sub build_placement_xml {
  my ($self) = @_;

  my @analyte_nodes = $self->process_doc->findnodes($IO_MAP_PATH);
  if (!@analyte_nodes) {
    croak 'No analytes registered';
  }

  my $placement_xml = $self->_base_placement_doc;
  my $container_data = $self->get_basic_container_data;
  my @location_values = @{$self->init_96_well_location_values};

  my $output_placements_element =
    $placement_xml->getElementsByTagName('output-placements')->pop();

  foreach my $analyte_node (@analyte_nodes) {
    my $placement_uri = $analyte_node->findvalue($OUTPUT_ANALYTE_URI_PATH);
    ($placement_uri) = $placement_uri =~ /\A([^?]*)/smx; #drop part of the uri starting with ? (state)

    # if location values has run out, then we filled in the current container
    # so we have to create a new one and regenerate the location values, as well
    if (!@location_values) {
      @location_values = @{$self->init_96_well_location_values};

      my $container_xml = $self->create_new_container($PLATE_96_WELL);
      $container_data = $self->get_container_data($container_xml);
      $self->add_container_to_placement($placement_xml, $container_data->{'uri'});
    }

    my $location_value = shift @location_values;

    my $output_placement_element = $self->create_output_placement_tag($placement_xml, $placement_uri, $container_data, $location_value);
    $output_placements_element->addChild($output_placement_element);
  }

  return $placement_xml;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::cherrypick_stamper

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::cherrypick_stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
  )->run();

=head1 DESCRIPTION

  Stamps the content of 1 or more source plate(s) to desctination plate(s) for cherry-picking.

=head1 SUBROUTINES/METHODS

=head2 run

  Method executing the epp callback

=head2 process_url

  Clarity process url, required.

=head2 step_url

  Clarity step url, required.

=head2 build_placement_xml

  Builds the XML document for the placement HTTP request.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item XML::LibXML

=item wtsi_clarity::epp

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
