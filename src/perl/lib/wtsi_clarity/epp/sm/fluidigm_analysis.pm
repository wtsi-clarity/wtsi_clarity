package wtsi_clarity::epp::sm::fluidigm_analysis;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::genotyping::fluidigm;
with qw/ wtsi_clarity::util::clarity_elements wtsi_clarity::util::well_mapper /;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $FIRST_ANALYTE_PATH => q{ /prc:process/input-output-map[1]/input/@uri };
Readonly::Scalar my $CONTAINER_PATH => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $CONTAINER_NAME => q{ /con:container/name };
Readonly::Scalar my $OUTPUT_ARTIFACTS_URI_PATH => q{ /prc:process/input-output-map/output/@limsid };
Readonly::Scalar my $BATCH_ARTIFACT_PATH => q{ /art:details/art:artifact };
Readonly::Scalar my $LOCATION_PATH => q{ location/value };
Readonly::Scalar my $CALL_RATE => q{WTSI Fluidigm Call Rate (SM)};
Readonly::Scalar my $GENDER => q{WTSI Fluidigm Gender (SM)};
## use critic

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';

our $VERSION = '0.0';

has '_filename' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__filename {
  my $self = shift;
  my $container_hash = $self->fetch_targets_hash($FIRST_ANALYTE_PATH, $CONTAINER_PATH);
  my $container = (values $container_hash)[0];
  return $container->findvalue($CONTAINER_NAME);
}

has '_filepath' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__filepath {
  my $self = shift;
  return join q{/}, $self->config->robot_file_dir->{'fluidigm_analysis'}, $self->_filename;
}

has '_output_artifacts' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__output_artifacts {
  my $self = shift;

  my $ids = $self->grab_values($self->process_doc, $OUTPUT_ARTIFACTS_URI_PATH);
  my @uris = map { join q{/}, $self->config->clarity_api->{'base_uri'}, 'artifacts', $_ } @{$ids};

  return $self->request->batch_retrieve('artifacts', \@uris);
}

override 'run' => sub {
  my $self = shift;
  super();

  # Parse the file
  my %sample_assay_set = wtsi_clarity::genotyping::fluidigm
                          ->new(directory => $self->_filepath)
                          ->parse();

  # Loop through sample assay set updating artifacts
  foreach my $artifact ($self->_output_artifacts->findnodes($BATCH_ARTIFACT_PATH)->get_nodelist()) {
    # get location of the artifact
    my $location = $artifact->findvalue($LOCATION_PATH);

    # convert location to well position
    my $well_location = 'S';

    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    $well_location .= sprintf '%02d', $self->well_location_index($location, 8, 12);
    ## use critic

    # find that sample in sample_assay_set, next if it wasn't done for some reason...
    next if (!exists $sample_assay_set{$well_location});

    my $sample_assay = $sample_assay_set{$well_location};

    # update artifact with gender and call rate
    my $call_rate_node = $self->create_udf_element($self->_output_artifacts, $CALL_RATE, $sample_assay->call_rate);
    my $gender_node = $self->create_udf_element($self->_output_artifacts, $GENDER, $sample_assay->gender);

    $artifact->appendChild($call_rate_node);
    $artifact->appendChild($gender_node);
  }

  # update artifacts
  $self->request->batch_update('artifacts', $self->_output_artifacts);

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::fluidigm_analysis

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::fluidigm_analysis->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will extract the filepath for a fluidigm results directory, parse the necessary files inside,
  and update the analytes with the call rate and gender.

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
