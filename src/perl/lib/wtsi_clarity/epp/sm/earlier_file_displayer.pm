package wtsi_clarity::epp::sm::earlier_file_displayer;

use Moose;
use Carp;
use Readonly;
use URI::Escape;
use XML::LibXML;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_LIMSID_PATH               => q{/art:artifact/sample/@limsid};
Readonly::Scalar my $RESULTFILE_ARTIFACT_LIMSID_PATH  => q{/art:artifacts/artifact/@limsid};
Readonly::Scalar my $FILE_LIMSID_PATH                 => q{/art:artifact/file:file/@limsid};
## use critic

my @str_attribute_params = (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has [ 'process_type', 'file_name', 'udf_name'] => @str_attribute_params;

override 'run' => sub {
  my $self = shift;

  super();

  my $tecan_file_uri = $self->_get_tecan_file_uri;

  $self->add_udf_element($self->process_doc, $self->udf_name, $tecan_file_uri);

  $self->request->put($self->process_url, $self->process_doc->toString);

  return;
};

sub _get_tecan_file_uri {
  my ($self) = @_;

  my $file_id = $self->_get_and_validate_file_id;

  return $self->config->clarity_api->{'app_uri'} . q{/files/} . $file_id;
}

sub _get_and_validate_file_id {
  my $self = shift;

  my ($file_id) = $self->_file_limsid =~ /(\d+)$/smx;

  if (!defined $file_id) {
    $self->_throw_file_not_found_error;
  }

  return $file_id;
}

sub _throw_file_not_found_error {
  my $self = shift;

  my $filename = $self->file_name;
  my $process_type = $self->process_type;
  croak qq{The '$filename' could not be found in the given process: '$process_type'.};
}

has '_sample_limsid'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__sample_limsid {
  my $self = shift;

  my $output_artifact_xml = $self->fetch_and_parse($self->process_doc->output_analyte_uris->[0]);
  my @sample_limsids = $output_artifact_xml->findvalue($SAMPLE_LIMSID_PATH);

  if (scalar @sample_limsids < 1) {
    $self->_throw_file_not_found_error;
  }

  return $sample_limsids[0];
}

has '_result_file_limsid'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__result_file_limsid {
  my $self = shift;

  my $artifact_uri = $self->process_doc->output_artifact_uris->[0];

  my $result_file_request_uri = $self->config->clarity_api->{'base_uri'} .
    q{/artifacts?} .
    q{samplelimsid=}  . $self->process_doc->sample_limsid_by_artifact_uri($artifact_uri) .
    q{&process-type=}  . uri_escape($self->process_type) .
    q{&type=ResultFile} .
    q{&name=}         . $self->file_name;

  my $result_file_search_artifact_xml = $self->fetch_and_parse($result_file_request_uri);

  my @result_file_limsids = map {
    $_->getValue
  } $result_file_search_artifact_xml->findnodes($RESULTFILE_ARTIFACT_LIMSID_PATH)->get_nodelist;

  if (scalar @result_file_limsids < 1) {
    $self->_throw_file_not_found_error;
  }

  @result_file_limsids = sort @result_file_limsids;

  return $result_file_limsids[- 1];
}

has '_file_limsid'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__file_limsid {
  my $self = shift;

  my $result_file_uri = $self->config->clarity_api->{'base_uri'} .
    q{/artifacts/} .
    $self->_result_file_limsid;

  my $result_file_artifact_xml = $self->fetch_and_parse($result_file_uri);

  my @file_limsids = $result_file_artifact_xml->findnodes($FILE_LIMSID_PATH)->get_nodelist;

  if (scalar @file_limsids < 1) {
    $self->_throw_file_not_found_error;
  }

  return $file_limsids[0]->getValue;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::earlier_file_displayer

=head1 SYNOPSIS

  my $earlier_file_displayer = wtsi_clarity::epp::sm::file_download->new(er
    process_url   => 'http://clarity.com/processes/1234',
    process_type  => 'Fluidigm Worksheet & Barcode (SM)',
    file_name     => 'Tecan File',
    udf_name      => 'Tecan File',
  );

=head1 DESCRIPTION

  Makes a file downloadable from a previous process.

=head1 SUBROUTINES/METHODS


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item use URI::Escape

=item use XML::LibXML

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