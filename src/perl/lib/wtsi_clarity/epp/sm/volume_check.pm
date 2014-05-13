package wtsi_clarity::epp::sm::volume_check;

use Moose;
use Carp;
use File::Copy;
use File::Spec::Functions;
use XML::LibXML;
use Readonly;
use Encode;

use wtsi_clarity::file_parsing::volume_check;
use wtsi_clarity::util::request;
use wtsi_clarity::util::types;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ANALYTE_PATH => q( prc:process/input-output-map[output/@output-generation-type='PerInput'] );
Readonly::Scalar my $VOLUME_PATH => q( smp:sample/udf:field[starts-with(@name, 'Volume')] );
Readonly::Scalar my $LOCATION_PATH => q ( art:artifact/location/value );
Readonly::Scalar my $URI_PATH => q ( art:artifact/sample/@uri );
## use critic

extends 'wtsi_clarity::epp';

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
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'robot_file'  => (
  isa             => 'WtsiClarityReadableFile',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);

has 'request' => (
  isa => 'wtsi_clarity::util::request',
  is  => 'ro',
  traits => [ 'NoGetopt' ],
  default => sub {
    return wtsi_clarity::util::request->new();
  },
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  # Parse the robot file
  my $parsed_file = $self->_parse_robot_file();

  # Fetch the process xml and parse it
  my $doc = $self->_fetch_and_parse($self->process_url);

  $self->_fetch_and_update_samples($doc, $parsed_file);

  copy($self->robot_file, $self->output)
    or croak sprintf 'Failed to copy %s to %s', $self->robot_file, $self->output;
  return;
};

sub _build_robot_file {
  my $self = shift;
  return catfile $self->config->robot_file_dir->{'sm_volume_check'}, $self->input;
}

sub _parse_robot_file {
  my $self = shift;
  my $parser = wtsi_clarity::file_parsing::volume_check->new(file_path => $self->robot_file);
  return $parser->parse();
}

sub _fetch_and_parse {
  my ($self, $url) = @_;
  my $parser = XML::LibXML->new();

  my $doc = $parser->parse_string($self->request->get($url));

  return $doc;
}

sub _fetch_and_update_samples {
  my ($self, $doc, $parsed_file) = @_;

  foreach my $analyteNode ($doc->findnodes($ANALYTE_PATH)) {
    my $uri = $self->_extract_analyte_uri($analyteNode);
    my $analyteDoc = $self->_fetch_and_parse($uri);
    my $sampleInfo = $self->_extract_sample_info($analyteDoc);
    my $sampleDoc = $self->_fetch_and_parse($sampleInfo->{'uri'});

    $self->_updateSample($sampleDoc, $sampleInfo, $parsed_file);
  }

  return 1;
}

sub _updateSample {
  my ($self, $sampleDoc, $sampleInfo, $parsed_file) = @_;
  my $wellLocation = $sampleInfo->{'wellLocation'};

  croak 'Well location does not exist in volume check file' if (!exists($parsed_file->{$wellLocation}));

  my $newVolume = $parsed_file->{$wellLocation};
  my $volumeList = $sampleDoc->findnodes($VOLUME_PATH);

  croak 'More than 1 udf field starting with Volume found' if $volumeList->size() > 1;

  # If the udf node doesn't exist...
  if ($volumeList->size() == 0) {
    $self->_create_volume_node($sampleDoc, $newVolume);
  } else {
    $self->_update_volume_node($volumeList, $newVolume);
  }
 
  $self->request->put($sampleInfo->{'uri'}, $sampleDoc->toString());

  return 1;
}

# This probably belongs in another module...
sub _create_volume_node {
  my ($self, $sampleDoc, $newVolume) = @_;
  my $node = XML::LibXML::Element->new('udf:field'); 
  $node->setAttribute('type', 'Numeric');
  $node->setAttribute('name', encode("utf8", "Volume (\x{c2b5}L) (SM)"));
  $node->appendTextNode($newVolume);
  $sampleDoc->documentElement()->appendChild($node);
}

sub _update_volume_node {
  my ($self, $volumeList, $newVolume) = @_;
  my $volumeUDF = $volumeList->pop();

  if ($volumeUDF->hasChildNodes()) {
    $volumeUDF->firstChild()->setData($newVolume);
  } else {
    $volumeUDF->addChild($volumeUDF->createTextNode($newVolume));
  }
}

sub _extract_analyte_uri {
  my ($self, $analyte) = @_;
  my $url = $analyte->findvalue(qw (input/@uri) );
  return $url;
}

sub _extract_sample_info {
  my ($self, $analyteDoc) = @_;
  my %info = ();
  $info{'wellLocation'} = $analyteDoc->findvalue($LOCATION_PATH);
  $info{'uri'} = $analyteDoc->findvalue($URI_PATH);
  return \%info;
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

=item File::Copy;

=item File::Spec::Functions;

=item XML::LibXML;

=item Readonly;

=item wtsi_clarity::file_parsing::volume_check;

=item wtsi_clarity::util::request;

=item wtsi_clarity::util::types;

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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
