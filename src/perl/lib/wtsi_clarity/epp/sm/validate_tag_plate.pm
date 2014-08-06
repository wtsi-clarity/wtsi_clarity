package wtsi_clarity::epp::sm::validate_tag_plate;

use Moose;
use Carp;
use JSON;
use JSON::Parse 'parse_json';

extends 'wtsi_clarity::epp';

with  'wtsi_clarity::util::clarity_elements',
      'wtsi_clarity::util::sequencescape_request_role';

our $VERSION = '0.0';

has '_tag_plate_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__tag_plate_barcode {
  my $self = shift;

  my $tag_plate_barcode = $self->find_udf_element($self->process_doc, 'Tag Plate');

  croak 'Tag Plate barcode has not been set' if (!defined $tag_plate_barcode);

  return $tag_plate_barcode->textContent;
}

has '_gatekeeper_url' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__gatekeeper_url {
  my $self = shift;

  return $self->config->tag_plate_validation->{'gatekeeper_url'};
}

has '_find_qcable_by_barcode_uuid' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__find_qcable_by_barcode_uuid {
  my $self = shift;

  return $self->config->tag_plate_validation->{'find_qcable_by_barcode_uuid'};
}

has '_valid_status' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__valid_status {
  my $self = shift;

  return $self->config->tag_plate_validation->{'qcable_state'};
}

has '_valid_lot_type' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__valid_lot_type {
  my $self = shift;

  return $self->config->tag_plate_validation->{'valid_lot_type'};
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  my $tag_plate = $self->tag_plate;

  my $tag_plate_status = $tag_plate->{'state'};
  my $lot_type = $self->lot_type($tag_plate->{'lot_uuid'});

  if ($tag_plate_status ne $self->_valid_status) {
    croak sprintf 'The plate status: %s is not valid.', $tag_plate_status;
  } elsif ($lot_type ne $self->_valid_lot_type) {
    croak sprintf 'The lot type: %s is not valid.', $lot_type;
  }

  return 0;
};

sub tag_plate {
  my $self = shift;
  my $url = join q{/}, ($self->_gatekeeper_url, $self->_find_qcable_by_barcode_uuid, 'first');

  my $response = $self->ss_request->post($url, $self->_search_content);

  my $parsed_response = parse_json($response);
  return  { 'state'     => $parsed_response->{'qcable'}->{'state'},
            'lot_uuid'  => $parsed_response->{'qcable'}->{'lot'}->{'uuid'}
          };
}

sub lot_type {
  my ($self, $lot_uuid) = @_;
  my $url = join q{/}, ($self->_gatekeeper_url, $lot_uuid);

  my $response = $self->ss_request->get($url);
  my $parsed_response = parse_json($response);

  return $parsed_response->{'lot'}->{'lot_type_name'};
}

sub _search_content {
  my $self = shift;
  my $content = {};
  my $barcode_element = {};
  $barcode_element->{'barcode'} = $self->_tag_plate_barcode;
  $content->{'search'} = $barcode_element;
  return JSON->new->allow_nonref->encode($content);
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::validate_tag_plate

=head1 SYNOPSIS

  my $epp = wtsi_clarity::epp::sm::validate_tag_plate->new(
    process_url => 'http://some.com/processes/151-12090'
  )->run();

=head1 DESCRIPTION

  Validates the plate whether it is in the correct state ('available')
  and it has got the correct lot type ('IDT Tags').

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head2 tag_plate 

Sends a POST request to a 3rd party application (Gatekeeper)
and returns the following tag plate properties: state, lot_uuid.
The POST request body contains the UUID of the queried tag plate.

=head2 lot_type

Sends a GET request to a 3rd party application (Gatekeeper) and returns the name of the lot type.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item JSON

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

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