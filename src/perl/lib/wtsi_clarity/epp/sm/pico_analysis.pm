package wtsi_clarity::epp::sm::pico_analysis;

use Moose;
use Carp;
use Readonly;
use File::Temp qw/ tempdir /;
use wtsi_clarity::file_parsing::dtx_concentration_calculator;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_process';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar our $INPUT_URIS_PATH       => q(/prc:process/input-output-map/input/@uri);
Readonly::Scalar our $ARTIFACT_PATH         => q(/art:details/art:artifact);
Readonly::Scalar our $ARTIFACT_NAME_PATH    => q(/art:artifact/name);
Readonly::Scalar our $CONTAINER_LIMSID_PATH => q(location/container/@limsid);
Readonly::Scalar our $FIRST_OUTPUT          => q(/prc:process/input-output-map[1]/output/@uri);
Readonly::Scalar our $SECOND_OUTPUT         => q(/prc:process/input-output-map[2]/output/@uri);
Readonly::Scalar our $FILE_URL_PATH         => q(/art:artifact/file:file/@uri);
Readonly::Scalar our $FILE_CONTENT_LOCATION => q(/file:file/content-location);
Readonly::Scalar our $ARTIFACT_LIMSID_PATH  => q(@limsid);
Readonly::Scalar our $STANDARD_PLATE_NAME   => q(StandardPlate);
Readonly::Scalar our $PICO_ASSAY_PLATE_NAME => q(PicoAssay);
Readonly::Scalar our $PROCESS_NAME          => q(Pico DTX (SM));
## use critic

our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();

  # Fetch the files
  my ($dtx1, $dtx2, $standard) = $self->_get_dtx_files();

  # Do the analysis
  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_doc => $standard,
    plateA_doc   => $dtx1,
    plateB_doc   => $dtx2,
  );

  my $results = $calculator->get_analysis_results();

  # Format the results

  # Pass the results to the PDF generator

  # Attach PDF to process

  return;
};

has '_input_uris' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__input_uris {
  my ($self) = @_;

  my $input_node_list = $self->process_doc->findnodes($INPUT_URIS_PATH);
  my @input_uris = map { $_->getValue() } $input_node_list->get_nodelist();

  return \@input_uris;
}

has '_input_artifact_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifact_details {
  my $self = shift;
  return $self->request->batch_retrieve('artifacts', $self->_input_uris);
};

has '_container_to_artifact_map' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__container_to_artifact_map {
  my $self = shift;
  my %container_to_artifact_map = ();

  my @artifacts = $self->_input_artifact_details->findnodes($ARTIFACT_PATH)->get_nodelist();

  foreach my $artifact (@artifacts) {
    my $container_limsid = $artifact->findvalue($CONTAINER_LIMSID_PATH);
    my $artifact_limsid  = $artifact->findvalue($ARTIFACT_LIMSID_PATH);

    if (!exists $container_to_artifact_map{$container_limsid}) {
      $container_to_artifact_map{$container_limsid} = $artifact_limsid;
    }
  }

  return \%container_to_artifact_map;
}

sub _get_dtx_files {
  my $self = shift;
  my %files = ();

  my @artifact_limsids = values $self->_container_to_artifact_map;

  foreach (0..1) {
    my $artifact_limsid = $artifact_limsids[$_];
    my $process_xml = $self->find_previous_process($artifact_limsid, $PROCESS_NAME);
    my ($dtx, $standard) = $self->_get_files($process_xml);

    my $key_name = 'dtx' . ($_ + 1);
    $files{$key_name} = $dtx;

    $files{'standard'} = $standard;
  }

  $self->_fetch_files(\%files);

  return ($files{'dtx1'}, $files{'dtx2'}, $files{'standard'});
}

sub _fetch_files {
  my ($self, $files) = @_;
  my $tempdir = tempdir( CLEANUP => 1);

  foreach my $file_name (keys %{$files}) {
    my $temp_file_path = $tempdir . qq{/$file_name};
    my ($server, $remote_path) = _extract_locations($files->{$file_name});
    my $file = $self->request->download_file($server, $remote_path, $temp_file_path);

    $files->{$file_name} =  $self->xml_parser->load_xml(
      location => $temp_file_path
    );
  }

  return;
}

sub _extract_locations {
  my $url = shift;
  return $url =~ /sftp:\/\/([^\/]+)(.*)/smx;
}

sub _get_files {
  my ($self, $process_xml) = @_;

  my @output_analyte_urls = (
    $process_xml->findvalue($FIRST_OUTPUT),
    $process_xml->findvalue($SECOND_OUTPUT),
  );

  my @output_analyte_xml = map { $self->fetch_and_parse($_); } @output_analyte_urls;

  my $dtx;
  my $standard;

  # Always two files...
  foreach (0..1) {
    my ($file_name, $file_location) = $self->_extract_file_info($output_analyte_xml[$_]);
    if ($file_name eq $STANDARD_PLATE_NAME) {
      $standard = $file_location;
    } elsif ($file_name eq $PICO_ASSAY_PLATE_NAME) {
      $dtx = $file_location;
    }
  }

  return ($dtx, $standard);
}

sub _extract_file_info {
  my ($self, $output_analyte) = @_;

  my $file_url = $self->_extract_file_url($output_analyte);
  my $file_xml = $self->fetch_and_parse($file_url);

  return ($self->_extract_file_name($output_analyte), $self->_extract_file_location($file_xml));
}

sub _extract_file_url {
  my ($self, $output_analyte) = @_;
  my $file_url = $output_analyte->findvalue($FILE_URL_PATH);
  return $file_url;
}

sub _extract_file_name {
  my ($self, $output_analyte) = @_;
  my $file_name = $output_analyte->findvalue($ARTIFACT_NAME_PATH);
  return $file_name;
}

sub _extract_file_location {
  my ($self, $file_xml) = @_;
  my $file_location = $file_xml->findvalue($FILE_CONTENT_LOCATION);
  return $file_location;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::pico_analysis

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::pico_analysis->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will find the DTX files for the 2 plates, fetch their standard file, run analysis and 
  produce a PDF of the results

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item List::MoreUtils;

=item wtsi_clarity::util::batch

=item wtsi_clarity::util::clarity_elements

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