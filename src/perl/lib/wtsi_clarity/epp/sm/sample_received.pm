package wtsi_clarity::epp::sm::sample_received;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use DateTime;
use JSON qw / decode_json /;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ANALYTE_PATH => q( prc:process/input-output-map/input/@uri );
Readonly::Scalar my $URI_PATH => q ( art:artifact/sample/@uri );
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();

  $self->_fetch_and_update_samples($self->process_doc);

  return 1;
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

    $self->_update_sample_date_received($sampleDoc, $sampleURI);
  }

  return 1;
}

sub _update_sample_date_received {
  my ($self, $sampleDoc, $sampleURI) = @_;

  $self->set_element($sampleDoc, 'date_received', $self->_today());
  my $nameElem = $self->find_element($sampleDoc, 'name');

  $self->set_element($sampleDoc, 'supplier_sample_name', $nameElem->textContent);
  $self->set_element($sampleDoc, 'name', $self->_get_uuid());

  $self->request->put($sampleURI, $sampleDoc->toString());

  return 1;
}

sub _get_uuid {
  my $self = shift;

  my $request = wtsi_clarity::util::request->new('content_type' => 'application/json');

  my $response = $request->get($self->config->uuid_api->{'uri'});
  my $response_json = decode_json $response;

  if (!exists $response_json->{'uuid'}) {
    croak 'Could not retrieve a uuid';
  }

  return $response_json->{'uuid'};
}

sub _today {
  return DateTime->now->strftime('%Y-%m-%d');
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

=head1 SUBROUTINES/METHODS

=head2 run - callback for the date_received action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=item DateTime

=item JSON

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

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
