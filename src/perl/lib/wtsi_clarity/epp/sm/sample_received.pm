package wtsi_clarity::epp::sm::sample_received;

use Moose;
use Carp;
use Readonly;
use DateTime;
use JSON qw / decode_json /;

use wtsi_clarity::util::request;
extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my  $ANALYTE_PATH => q( prc:process/input-output-map/input/@uri );
Readonly::Scalar my  $URI_PATH => q ( art:artifact/sample/@uri );
Readonly::Scalar my  $SUPPLIER_UDF_FIELD_NAME  => 'WTSI Supplier Sample Name (SM)';
Readonly::Scalar our $SUPPLIER_NAME_PATH => q( /smp:sample/udf:field[@name=') . $SUPPLIER_UDF_FIELD_NAME . q('] );
Readonly::Scalar my  $DATE_RECEIVED_PATH => q( /smp:sample/date-received );
Readonly::Scalar my  $WTSI_DONOR_ID => q(WTSI Donor ID);
## use critic

has '_ss_request' => (
  isa => 'wtsi_clarity::util::request',
  is  => 'ro',
  required => 0,
  default => sub {
    return wtsi_clarity::util::request->new('content_type' => 'application/json');
  },
);

has '_date' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  default    => sub {return DateTime->now->strftime('%Y-%m-%d') },
);

override 'run' => sub {
  my $self= shift;
  super();
  $self->_fetch_and_update_samples($self->process_doc);
  return;
};

# Duplicated from volume_check
# Another thing that needs refactoring at some point...
sub _extract_sample_uri {
  my ($self, $analyteDoc) = @_;
  my $uri = $analyteDoc->findvalue($URI_PATH);
  return $uri;
}

sub _fetch_and_update_samples {
  my ($self, $doc) = @_;

  foreach my $analyteURI ($doc->findnodes($ANALYTE_PATH)) {
    my $analyteDoc = $self->fetch_and_parse($analyteURI->getValue());
    my $sampleURI = $self->_extract_sample_uri($analyteDoc);
    my $sampleDoc = $self->fetch_and_parse($sampleURI);
    if ($self->_is_new_sample($sampleDoc, $sampleURI)) {
      $self->_update_sample($sampleDoc);
      $self->request->put($sampleURI, $sampleDoc->toString());
    }
  }

  return;
}

sub _is_new_sample {
  my ($self, $doc, $url) = @_;

  $url |= q[];
  if ($doc->findnodes($SUPPLIER_NAME_PATH)) {
    $self->epp_log(qq[Supplier name already set for the sample, not updating $url]);
    return 0;
  }
  my @nodes = $doc->findnodes($DATE_RECEIVED_PATH);
  if (@nodes) {
    my $date = $self->trim_value($nodes[0]->textContent());
    if ($date) {
      $self->epp_log(qq[Date received $date already set for the sample, not updating $url]);
      return 0;
    }
  }
  return 1;
}

sub _is_donor_id_set {
  my ($self, $sampleDoc) = @_;
  return (defined $self->find_udf_element($sampleDoc, $WTSI_DONOR_ID)) ? 1 : 0;
}

sub _update_sample {
  my ($self, $sampleDoc) = @_;

  my $nameElem = $self->find_clarity_element($sampleDoc, 'name');
  my $uuid = $self->_get_uuid();

  $self->add_udf_element($sampleDoc, $SUPPLIER_UDF_FIELD_NAME, $nameElem->textContent);
  $self->add_clarity_element($sampleDoc, 'name', $uuid);
  $self->add_clarity_element($sampleDoc, 'date-received', $self->_date);

  if (!$self->_is_donor_id_set($sampleDoc)) {
    $self->add_udf_element($sampleDoc, $WTSI_DONOR_ID, $uuid);
  }

  return;
}

sub _get_uuid {
  my $self = shift;

  my $url = $self->config->uuid_api->{'uri'};
  my $response = $self->_ss_request->get($url);

  if (!$response) {
    croak qq[Empty response from $url];
  }

  my $response_json = decode_json $response;

  if (!$response_json->{'uuid'}) {
    croak qq[Could not get uuid from $url];
  }

  return $response_json->{'uuid'};
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::sample_received

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::sample_received->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'date_received' field of all samples in the process to today's date. Will also copy
  the value in the name field to the WTSI Supplier Sample Name (SM). It will then replace name
  with a UUID obtained from an extenal web service.

  If the sample already has either date received or WTSI Supplier Sample Name (SM) defined,
  it will not be updated o avoid overwriting the original values. No error will be raised.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - callback for the date_received action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item DateTime

=item JSON

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
