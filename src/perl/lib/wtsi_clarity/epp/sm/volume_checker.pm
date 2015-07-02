package wtsi_clarity::epp::sm::volume_checker;

use Moose;
use Carp;
use File::Copy;
use File::Spec::Functions;
use Readonly;

use wtsi_clarity::file_parsing::volume_checker;
use wtsi_clarity::util::types;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ANALYTE_PATH           => q( prc:process/input-output-map[output/@output-generation-type='PerInput'] );
Readonly::Scalar my $LOCATION_PATH          => q( art:artifact/location/value );
Readonly::Scalar my $SAMPLE_URI_PATH        => q( art:artifact/sample/@uri );
## use critic

Readonly::Scalar my $VOLUME_UDF_FIELD_NAME              => q(Volume);
Readonly::Scalar my $WTSI_WORKING_VOLUME_UDF_FIELD_NAME => q(WTSI Working Volume (µL) (SM));

extends 'wtsi_clarity::epp';

with  'wtsi_clarity::util::clarity_elements',
      'wtsi_clarity::util::filename';

our $VERSION = '0.0';

has 'input'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);

sub _build_input {
  my $self = shift;
  return $self->output;
}

has 'output'  => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has 'robot_file'  => (
  isa        => 'WtsiClarityReadableFile',
  is         => 'ro',
  required   => 0,
  traits     => [ 'NoGetopt' ],
  lazy_build => 1,
);

sub _build_robot_file {
  my $self = shift;

  my $filename = $self->with_uppercase_extension($self->input);

  return catfile $self->config->robot_file_dir->{'sm_volume_check'}, $filename;
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  $self->_update_volumes;

  copy($self->robot_file, $self->output)
    or croak sprintf 'Failed to copy %s to %s', $self->robot_file, $self->output;
  return;
};

sub _parse_robot_file {
  my $self = shift;
  my $parser = wtsi_clarity::file_parsing::volume_checker->new(file_path => $self->robot_file);
  return $parser->parse();
}

sub _update_volumes {
  my ($self) = @_;

  my $parsed_file = $self->_parse_robot_file();

  foreach my $analyteNode ($self->process_doc->findnodes($ANALYTE_PATH)) {
    my $analyteUri = $self->_extract_analyte_uri($analyteNode);
    my $analyteDoc = $self->fetch_and_parse($analyteUri);
    my $wellLocation = $self->_extract_well_location($analyteDoc);

    my $sample_uri = $analyteDoc->findvalue($SAMPLE_URI_PATH);
    my $sample_doc = $self->fetch_and_parse($sample_uri);

    croak "Well location $wellLocation does not exist in volume check file " . $self->robot_file if (!exists($parsed_file->{$wellLocation}));

    my $new_volume = $parsed_file->{$wellLocation};

    # TODO refactor the QC report to read the volume from the sample and not from the analyte,
    # then the line, which is updating the analyte could be removed
    $self->_update_artifact_with_volume($analyteUri, $analyteDoc, $new_volume, $VOLUME_UDF_FIELD_NAME);
    $self->_update_artifact_with_volume($sample_uri, $sample_doc, $new_volume, $WTSI_WORKING_VOLUME_UDF_FIELD_NAME);
  }

  return;
}

sub _extract_analyte_uri {
  my ($self, $analyte) = @_;
  my $url = $analyte->findvalue(qw (output/@uri) );
  return $url;
}

sub _extract_well_location {
  my ($self, $analyteDoc) = @_;
  return $analyteDoc->findvalue($LOCATION_PATH);
}

sub _update_artifact_with_volume {
  my ($self, $analyteUri, $analyteDoc, $new_volume, $field_name) = @_;

  $self->add_udf_element($analyteDoc, $field_name, $new_volume);

  $self->request->put($analyteUri, $analyteDoc->toString());

  return $analyteDoc;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::volume_checker

=head1 SYNOPSIS

  use wtsi_clarity::epp::sm::volume_checker;
  wtsi_clarity::epp::sm::volume_checker->new(process_url => 'http://some.com/process/1234XM',
                                           output      => 'LP45678.csv')->run();

=head1 DESCRIPTION

 Volume check for sample management workflow.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 output - required attribute - file name to copy the robot csv files to

=head2 robot_file - full path to the robot output file

 If not given, will be built from the robot_file>>sm_volume_check configuration
 fil entry and the name supplied in the output attribute

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item File::Copy

=item File::Spec::Functions

=item Readonly

=item wtsi_clarity::file_parsing::volume_checker

=item wtsi_clarity::util::types

=item wtsi_clarity::util::clarity_elements

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
