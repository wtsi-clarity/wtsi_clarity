package wtsi_clarity::epp::isc::tag_indexer;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::tag_plate::service;
use wtsi_clarity::tag_plate::layout;

extends 'wtsi_clarity::epp';
with qw/
        wtsi_clarity::util::clarity_elements
        wtsi_clarity::epp::isc::tag_plate_common
       /;

our $VERSION = '0.0';

##no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $DETAILS_ARTIFACT_PATH     => q{/art:details/art:artifact};
Readonly::Scalar my $REAGENT_LABEL_PATH        => q{/art:artifact/reagent-label};
Readonly::Scalar my $OUTPUT_URI_PATH           => q{/prc:process/input-output-map[output/@output-type='Analyte']};
Readonly::Scalar my $URI_SEARCH_STRING         => q{@uri};
##use critic

has '_batch_artifacts_doc' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__batch_artifacts_doc {
  my $self = shift;

  my @uris = ();
  foreach my $analyte_mapping ($self->process_doc->findnodes($OUTPUT_URI_PATH)) {
    my $output_uri = $analyte_mapping->findvalue(q(output/) . $URI_SEARCH_STRING);
    push @uris, $output_uri;
  }

  if (!@uris) {
    croak 'No output analytes found';
  }

  return $self->request->batch_retrieve('artifacts', \@uris);
}

has '_tag_layout' => (
  isa             => 'wtsi_clarity::tag_plate::layout',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__tag_layout {
  my $self = shift;
  return wtsi_clarity::tag_plate::layout->new(
    gatekeeper_info => wtsi_clarity::tag_plate::service->new(
      barcode => $self->barcode)->get_layout()
  );
}

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method
  $self->_index();
  $self->request->batch_update('artifacts', $self->_batch_artifacts_doc);

  return;
};

sub _index {
  my $self = shift;

  foreach my $analyte_xml ($self->_batch_artifacts_doc->findnodes($DETAILS_ARTIFACT_PATH)) {
    my $location = $analyte_xml->getElementsByTagName(q[value])->[0]->textContent;
    my ($location_index, $tag) = $self->_tag_layout->tag_info($location);
    $self->_add_tags_to_analyte($analyte_xml, $location_index, $tag);
  }

  return;
}

sub _add_tags_to_analyte {
  my ($self, $analyte_xml, $location_index, $tag) = @_;

  $self->_remove_reagent_labels($analyte_xml);

  my $reagent_label = XML::LibXML::Element->new('reagent-label');
  $reagent_label->setAttribute('name', $self->_reagent_name($location_index, $tag));
  $analyte_xml->addChild($reagent_label);

  return $analyte_xml;
}

sub _reagent_name {
  my ($self, $location_index, $tag) = @_;

  my $tagset_name = $self->_tag_layout->tag_set_name;

  return sprintf '%s: tag %s (%s)', $tagset_name, $location_index, $tag;
}

sub _remove_reagent_labels {
  my ($self, $analyte_xml) = @_;

  my @reagent_labels = $analyte_xml->findnodes($REAGENT_LABEL_PATH);
  foreach my $reagent_label (@reagent_labels) {
    my $parent_node = $reagent_label->parentNode;
    $parent_node->removeChild( $reagent_label );
  }

  return;
}

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::tag_indexer

=head1 SYNOPSIS


=head1 DESCRIPTION

  Epp callback for applying tag indexes.

=head1 SUBROUTINES/METHODS

=head2 run

  Executes the callback.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
