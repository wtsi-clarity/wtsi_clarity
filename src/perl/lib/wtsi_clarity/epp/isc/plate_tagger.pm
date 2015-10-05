package wtsi_clarity::epp::isc::plate_tagger;

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

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method
  my $service = wtsi_clarity::tag_plate::service->new(barcode => $self->barcode);

  $service->validate();

  $self->_index();
  $self->request->batch_update('artifacts', $self->_batch_artifacts_doc);

  $service->mark_as_used();

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

no Moose;

1;

__END__

=head1 NAME

 wtsi_clarity::epp::isc::plate_tagger

=head1 SYNOPSIS

  Either 'validate' or 'exhaust' option should be set;

  wtsi_clarity::epp::isc::plate_tagger->new(process_url => 'some', validate => 1)->run();
  wtsi_clarity::epp::isc::plate_tagger->new(process_url => 'some', exhaust  => 1)->run();

=head1 DESCRIPTION

  Epp callback for accessing the 'Gatekeeper' tag plate micro-service to validate tag
  plates and marks them as used.

=head1 SUBROUTINES/METHODS

=head2 BUILD

  Post-constructor Moose hook - checks consistency of options.

=head2 run

  Executes the callback.

=head2 validate

  Boolean flag; validation is perfomed by the run method.

=head2 exhaust

  Boolean flag; plate is marked as used by the run method.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::tag_plate::service

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
