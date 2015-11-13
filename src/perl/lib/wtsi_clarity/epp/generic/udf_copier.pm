package wtsi_clarity::epp::generic::udf_copier;

use Moose;
use Carp;
use Readonly;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACTS_PATH => q(art:details/art:artifact);
Readonly::Scalar my $SAMPLE_LIMSIDS => q(./sample/@limsid);
## use critic

has 'from_process' => ( is => 'ro', isa => 'Str', required => 1 );

has 'fields' => ( is => 'ro', isa => 'ArrayRef', required => 1 );

has '_input_artifacts' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy => 1,
  default => sub { my $self = shift; $self->process_doc->input_artifacts },
);

override 'run' => sub {
  my $self = shift;
  super();

  $self->_copy_fields();
  $self->request->batch_update('artifacts', $self->_input_artifacts);

  return;
};

sub _copy_fields {
  my $self = shift;

  # Fetch input artifacts
  foreach my $input_analyte ($self->_input_artifacts->findnodes($ARTIFACTS_PATH)) {

    my @samples = $self->_sample_list_from_artifact($input_analyte);

    my $search_results = $self->_find_analytes_by_process_and_samples($self->from_process, \@samples);

    # Could not find any analytes from process
    # Unfortunately can't inform the user
    return if $search_results->size == 0;

    my $parent_analyte = $self->fetch_and_parse($search_results->pop->findvalue('@uri'));

    $self->_copy($self->fields, from => $parent_analyte, to => $input_analyte);
  }

  return 1;
}

sub _find_analytes_by_process_and_samples {
  my ($self, $process, $samples) = @_;

  my $search_result = $self->request->query_resources('artifacts', {
    sample_id    => $samples,
    process_type => $self->from_process,
    type         => 'Analyte'
  });

  return $search_result->findnodes('art:artifacts/artifact');
}

sub _sample_list_from_artifact {
  my ($self, $artifact) = @_;
  return $artifact->findnodes($SAMPLE_LIMSIDS)->to_literal_list;
}

sub _copy {
  my ($self, $fields, %analytes) = @_;

  foreach my $field (@{$fields}) {
    my $field_value = $self->find_udf_element_textContent($analytes{'from'}, $field, q{});

    next if $field_value eq q{};

    my $udf = $self->create_udf_element($self->_input_artifacts, $field);
    $udf->appendTextNode($field_value);

    $analytes{'to'}->appendChild($udf);
  }

  return 1;
}

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::udf_copier

=head1 SYNOPSIS

  wtsi_clarity::epp::generic::udf_copier->new(
    process_url  => 'http://clarity.dev/api/v2/processes/21-345',
    from_process => 'Pre Capture Library Pooling',
    fields       => ['Average Molarity (nM)'],
  )->run()

=head1 DESCRIPTION

  Will go back to the artifacts of a given process ('from_process'), get the values for the given udfs
  ('fields'), and copy their values to the artifacts of the current process.

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Genome Research Ltd.

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