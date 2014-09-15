package wtsi_clarity::epp::sm::volume_check;

use Moose;
use Carp;
use File::Copy;
use File::Spec::Functions;
use Readonly;

use wtsi_clarity::file_parsing::volume_check;
use wtsi_clarity::util::types;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ANALYTE_PATH => q( prc:process/input-output-map[output/@output-generation-type='PerInput'] );
Readonly::Scalar my $LOCATION_PATH => q ( art:artifact/location/value );
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

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
  return catfile $self->config->robot_file_dir->{'sm_volume_check'}, $self->input;
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  # Parse the robot file
  my $parsed_file = $self->_parse_robot_file();
  $self->_update_analytes($parsed_file);

  copy($self->robot_file, $self->output)
    or croak sprintf 'Failed to copy %s to %s', $self->robot_file, $self->output;
  return;
};

sub _parse_robot_file {
  my $self = shift;
  my $parser = wtsi_clarity::file_parsing::volume_check->new(file_path => $self->robot_file);
  return $parser->parse();
}

sub _update_analytes {
  my ($self, $parsed_file) = @_;

  foreach my $analyteNode ($self->process_doc->findnodes($ANALYTE_PATH)) {
    my $analyteUri = $self->_extract_analyte_uri($analyteNode);
    my $analyteDoc = $self->fetch_and_parse($analyteUri);
    my $wellLocation = $self->_extract_well_location($analyteDoc);

    $self->_update_analyte($analyteUri, $analyteDoc, $wellLocation, $parsed_file);
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

sub _update_analyte {
  my ($self, $analyteUri, $analyteDoc, $wellLocation, $parsed_file) = @_;

  croak "Well location $wellLocation does not exist in volume check file " . $self->robot_file if (!exists($parsed_file->{$wellLocation}));

  my $newVolume = $parsed_file->{$wellLocation};
  $self->add_udf_element($analyteDoc, "Volume", $newVolume);

  $self->request->put($analyteUri, $analyteDoc->toString());

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::volume_check

=head1 SYNOPSIS

  use wtsi_clarity::epp::sm::volume_check;
  wtsi_clarity::epp::sm::volume_check->new(process_url => 'http://some.com/process/1234XM',
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

=item wtsi_clarity::file_parsing::volume_check

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
