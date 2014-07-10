package wtsi_clarity::epp::sm::cp_bed_verification;

use Moose;
use Carp;
use Readonly;
use File::Temp;
use File::Slurp;
use File::Spec::Functions;
use File::Copy;
use JSON;

use wtsi_clarity::util::request;
extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_LIMSID => q( /prc:process/@limsid );
Readonly::Scalar my $INPUT_PATH => q( /prc:process/input-output-map[1]/input/@limsid );
Readonly::Scalar my $PREVIOUS_PROCESS_PATH => q( /prc:processes/process[@limsid!="%s"]/@uri );
Readonly::Scalar my $PREVIOUS_PROCESS_OUTPUT => q( /prc:process/input-output-map/output/@uri );
Readonly::Scalar my $ARTIFACT_NAME => q( /art:artifact/name );
Readonly::Scalar my $ARTIFACT_FILE_PATH => q ( /art:artifact/file:file/@uri );
Readonly::Scalar my $FILE_CONTENT_LOCATION => q ( /file:file/content-location );
Readonly::Scalar my $ROBOT_PATH => q ( /prc:process/udf:field[@name="Robot ID"] );
Readonly::Scalar my $BEDS_PATH => q( /prc:process/udf:field[starts-with(@name, "Bed")] );
Readonly::Scalar my $PLATES_PATH => q( /prc:process/udf:field[starts-with(@name, "Plate")] );
Readonly::Scalar my $OUTPUT_LIMSID_PATH => q ( prc:process/input-output-map[1]/output/@limsid );

Readonly::Scalar my $TECAN_CONFIG_FILE => q (tecan_beds.json);
## use critic

=head2 _tecan_bed_config

Decoded JSON from the tecan_beds.json config file

=cut
has '_tecan_bed_config' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__tecan_bed_config {
  my $self = shift;
  my $file_path = catfile($self->config->dir_path, $TECAN_CONFIG_FILE);
  open my $fh, '<:encoding(UTF-8)', $file_path
    or croak qq[Could not retrive the configuration file at $file_path\n];
  # local $RS = undef;
  local $/ = undef;
  my $json_text = <$fh>;
  close $fh
    or croak qq[Could not close handle to $file_path\n];

  return decode_json($json_text);
}

=head2 _robot_id

The selected Robot ID from the process document

=cut
has '_robot_id' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__robot_id {
  my $self = shift;
  my $robot_id = $self->process_doc->findvalue($ROBOT_PATH);

  if ($robot_id eq '') {
    croak "Robot ID must be set first";
  }

  return $robot_id;
}

=head2 _output_limsid

The limsid of the output result file. Used to rename the Tecan file
obtained from the previous step to if bed verification is 
successful.

=cut
has '_output_limsid' => (
  isa => 'Str',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__output_limsid {
  my $self = shift;
  return $self->process_doc->findvalue($OUTPUT_LIMSID_PATH);
}

=head2 _udf_beds

Returns a hash of the beds used for the process using name
for a key and the bed barcode for the value. 

e.g.

  {
    "Bed 1" => 123456789,
    "Bed 2" => 987654321
  }

=cut
has '_udf_beds' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__udf_beds {
  my $self = shift;
  my $results = $self->process_doc->findnodes($BEDS_PATH);
  my %udf_beds = ();

  foreach my $node ($results->get_nodelist) {
    my $name = $node->findvalue('@name');
    my $barcode = $node->textContent;
    $udf_beds{$name} = $barcode;
  }

  return \%udf_beds;
}

=head2 _udf_plates

Returns a hash of the plates used for the process using name
for a key and the plate barcode for the value. 

e.g.

  {
    "Plate 1" => 123456789,
    "Plate 2" => 987654321
  }

=cut
has '_udf_plates' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__udf_plates {
  my $self = shift;
  my $results = $self->process_doc->findnodes($PLATES_PATH);
  my %udf_plates = ();

  foreach my $node ($results->get_nodelist) {
    my $name = $node->findvalue('@name');
    my $barcode = $node->textContent;
    $udf_plates{$name} = $barcode;
  }

  return \%udf_plates;
}

=head2 _tecan_file

Finds and downloads the tecan file, that has been generated in the previous
step of cherry-picking, to a tmp directory. 

=cut
has '_tecan_file' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__tecan_file {
  my $self = shift;

  my $process_limsid = $self->process_doc->findvalue($PROCESS_LIMSID);
  my $input = $self->process_doc->findvalue($INPUT_PATH);

  my $analyte_processes_url = $self->config->clarity_api->{'base_uri'} . '/processes?inputartifactlimsid=' . $input;
  my $analyte_processes = $self->fetch_and_parse($analyte_processes_url);
  my $previous_process_url = $analyte_processes->findvalue(sprintf $PREVIOUS_PROCESS_PATH, $process_limsid);
  
  my $previous_process = $self->fetch_and_parse($previous_process_url);
  my $previous_process_outputs = $previous_process->findnodes($PREVIOUS_PROCESS_OUTPUT);

  my $artifact = $self->_find_tecan_analyte($previous_process_outputs);
  my $artifact_file_url = $artifact->findvalue($ARTIFACT_FILE_PATH);

  my $file = $self->fetch_and_parse($artifact_file_url);
  my $content_location = $file->findvalue($FILE_CONTENT_LOCATION);

  my ($server, $remote_directory, $filename) = _extract_locations ($content_location);
  my $tmpdir = File::Temp->newdir();
  my $local_filename = $tmpdir->dirname() . $filename;

  $self->request->download_file($server, '/' . $remote_directory . '/' . $filename, $local_filename);

  return $local_filename;
}

# Duplicated from uploader_role
sub _extract_locations {
  my ($url) = @_;
  return $url =~ /sftp:\/\/([^\/]+)\/(.*)\/([^\/]+[.].+)/smx;
}

=head2 _find_tecan_analyte

Method used to loop through all outputs in a process
until one with a Tecan File is found. Returns the 
artifact if found, or else croaks.

=cut
sub _find_tecan_analyte {
  my ($self, $outputs) = @_;

  foreach my $uri (@{$outputs}) {
    my $artifact = $self->fetch_and_parse($uri->textContent());
    if ($artifact->findvalue($ARTIFACT_NAME) eq 'Tecan File') {
      return $artifact;
    }
  }

  croak q(Couldn't find an artifact with the name Tecan File);
}

=head2 _file_input_output

Parses the .gwl file to build up a hash representation of the
source and destination plates (which are in the comments)

e.g.

  {
    "SRC1" => 123456789,
    "DEST1" => 987654321
  }

=cut
has '_file_input_output' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__file_input_output {
  my $self = shift;
  my %input_output_map = ();

  open my $fh, '<', $self->_tecan_file
    or croak qq ( Failed to open $self->_tecan_file );

  while( my $line = <$fh>) {
    if ($line =~ m/^C;\s(SRC|DEST).*$/smx) {
      my ($bed, $plate) = ($line =~ /^C;\s(SRC\d+|DEST\d+)\s=\s(.+)$/); # Change this for production
      $input_output_map{$bed} = $plate;
    }
  }

  close $fh;

  return \%input_output_map;
};

=head2 _plate_bed_map

Combines the _tecan_bed_config and _file_input_output into a single
unified represtation of ultimate power.

e.g.
  [
    {
      'bed' => 21,
      'plate_barcode' => '1260253757413',
      'barcode' => '930020021696'
    },
    {
      'bed' => 1,
      'plate_barcode' => '5260275757817',
      'barcode' => '930020001650'
    }
  ]

=cut
has '_plate_bed_map' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__plate_bed_map {
  my $self = shift;
  my @plate_bed_map = ();

  if (!exists $self->_tecan_bed_config->{$self->_robot_id}) {
    carp "Could not find tecan config for robot $self->_robot_id";
  }

  my $beds = $self->_tecan_bed_config->{$self->_robot_id}{'beds'};
  
  foreach my $plate (keys %{$self->_file_input_output}) {
    
    my $conf = ();

    if (!exists $self->_tecan_bed_config->{$self->_robot_id}{'beds'}{$plate}) {
      carp "Could not find config for plate $plate";
    }

    $conf = $beds->{$plate};
    $conf->{'plate_barcode'} = $self->_file_input_output->{$plate};

    push @plate_bed_map, $conf; 
  }

  return \@plate_bed_map;
};

=head2 _offer_download

Change the name of the tecan file to the limsid of the output

=cut
sub _offer_download {
  my $self = shift;
  copy($self->_tecan_file, './' . $self->_output_limsid);
}

=head2 validate

Performs the validation by checking the _plate_bed_map
against what the user has put into the UDFs. Simple.

=cut
sub validate {
  my ($self, $plate_bed_map, $udf_beds, $udf_plates) = @_;

  foreach my $bed_plate_pair (@{$plate_bed_map}) {
    my $bed = 'Bed ' . $bed_plate_pair->{'bed'};
    my $plate = 'Plate ' . $bed_plate_pair->{'bed'};

    if (!exists $udf_beds->{$bed}) {
      croak "Could not find $bed";
    }

    if ($udf_beds->{$bed} ne $bed_plate_pair->{'barcode'}) {
      croak "$bed barcode should be " . $bed_plate_pair->{'barcode'};
    }

    if (!exists $udf_plates->{$plate}) {
      croak "Could not find $plate";
    }

    if ($udf_plates->{$plate} ne $bed_plate_pair->{'plate_barcode'}) {
      croak "Plate barcode in $bed should be equal to " . $bed_plate_pair->{'plate_barcode'};
    }
  }

  return 1;
}

override 'run' => sub {
  my $self= shift;
  super();

  print $self->_tecan_file;

  if ($self->validate($self->_plate_bed_map, $self->_udf_beds, $self->_udf_plates)) {
    $self->_offer_download();
    return 1;
  }

  return 0;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::cp_bed_verification

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::cp_bed_verification->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Checks that the correct plates have been put into the correct beds, and that all plates are present,
  according to the .gwl file generated in the previous step.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - callback for the cp_bed_verification action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose
=item Carp
=item Readonly
=item File::Temp
=item File::Slurp
=item File::Spec::Functions
=item File::Copy
=item JSON
=item wtsi_clarity::util::request

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