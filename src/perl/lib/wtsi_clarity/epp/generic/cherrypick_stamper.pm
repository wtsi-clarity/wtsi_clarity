package wtsi_clarity::epp::generic::cherrypick_stamper;

use Moose;
use Readonly;
use Carp;
use XML::LibXML;
use List::Util qw/reduce first/;

extends 'wtsi_clarity::epp';
with qw{wtsi_clarity::epp::generic::roles::stamper_common wtsi_clarity::epp::generic::roles::container_common};

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $IO_MAP_PATH              => q{ /prc:process/input-output-map[output[@output-type='Analyte']]};
Readonly::Scalar my $OUTPUT_ANALYTE_URI_PATH  => q{./output/@uri};
Readonly::Scalar my $ARTIFACT_BY_LIMSID       => q{art:details/art:artifact[@limsid="%s"]};
Readonly::Scalar my $INPUT_URI                => q{./input/@uri};
Readonly::Scalar my $INPUT_LIMSID             => q{./input/@limsid};
Readonly::Scalar my $LOCATION_VALUE           => q{./location/value};
Readonly::Scalar my $CONTAINER_LIMS_ID        => q{./location/container/@limsid};
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

# Transforms an io_node XML::Element into a useful data representation
sub _augment_input {
  my ($self, $input_analytes, $io_node) = @_;

  my $id                = $io_node->findvalue($INPUT_LIMSID);

  my $full_input        = $input_analytes->findnodes(sprintf $ARTIFACT_BY_LIMSID, $id)->pop();
  my $location          = $full_input->findvalue($LOCATION_VALUE);
  my $container_lims_id = $full_input->findvalue($CONTAINER_LIMS_ID);

  return {
    io_node           => $io_node,
    location          => $location,
    container_lims_id => $container_lims_id,
  }
}

sub _group_by_container {
  my ($self, $memo, $io) = @_;

  my $container = $io->{'container_lims_id'};

  if (!exists $memo->{$container}) {
    $memo->{$container} = [];
  }

  push $memo->{$container}, $io;

  return $memo;
}

# Finds the index of two well locations in a pre-initialized
# array of well values, and returns the result of a comparison between the 2
# values. Will be used as part of a sort.
sub _sort_analyte {
  my ($self, $sort_by, $analyte_a, $analyte_b) = @_;

  my @sort_by = @{$sort_by};

  my $location_index_a = first { $sort_by[$_] eq $analyte_a->{'location'} } 0..$#sort_by;
  my $location_index_b = first { $sort_by[$_] eq $analyte_b->{'location'} } 0..$#sort_by;

  return $location_index_a <=> $location_index_b;
}

=head2 _sort_analytes

  Description: Takes an array of io nodes, groups them by container id, and sorts by location
               within those containers

  Arg [1]:    XML::LibXML::NodeList $io_nodes - Array of input-output-map nodes
  Example:    $self->_sort_analytes($io_nodes)
  ReturnType: XML::LibXML::NodeList

=cut
sub _sorted_io {
  my ($self, $process_doc, $sort_by) = @_;

  my @io_nodes = $process_doc->findnodes($IO_MAP_PATH);

  if (!@io_nodes) {
    croak 'No analytes registered';
  }

  my @input_analyte_uris = map { $_->findvalue($INPUT_URI) } @io_nodes;
  my $input_analytes = $self->request->batch_retrieve('artifacts', \@input_analyte_uris);

  my @analytes = map { $self->_augment_input($input_analytes, $_) } @io_nodes;

  # Group by container
  my @analytes_by_container = values reduce { $self->_group_by_container($a, $b) } {}, @analytes;

  # Sort analytes within container then just return the io_node... Perl is so pretty...
  my @sorted_io = map { $_->{'io_node'} } map {
    sort { $self->_sort_analyte($sort_by, $a, $b) } @{$_} } @analytes_by_container;

  return XML::LibXML::NodeList->new(@sorted_io);
}

sub build_placement_xml {
  my ($self) = @_;

  my @location_values = @{$self->init_96_well_location_values};

  my $sorted_analytes = $self->_sorted_io($self->process_doc, \@location_values);

  my $placement_xml = $self->_base_placement_doc;
  my $container_data = $self->get_basic_container_data;

  my $output_placements_element =
    $placement_xml->getElementsByTagName('output-placements')->pop();

  foreach my $analyte_node (@{$sorted_analytes}) {
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
