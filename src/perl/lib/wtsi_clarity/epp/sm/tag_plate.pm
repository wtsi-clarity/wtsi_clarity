package wtsi_clarity::epp::sm::tag_plate;

use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use Readonly;
use JSON;
use JSON::Parse 'parse_json';

extends 'wtsi_clarity::epp';

with  'wtsi_clarity::util::clarity_elements',
      'wtsi_clarity::util::sequencescape_request_role';

our $VERSION = '0.0';

Readonly::Scalar my $EXHAUSTED_STATE => q[exhausted];
Readonly::Scalar my $STATE_CHANGE_PATH => q[state_changes];

has 'tag_layout_file_name' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

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

has '_ss_user_uuid' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);
sub _build__ss_user_uuid {
  my $self = shift;

  return $self->config->tag_plate_validation->{'user_uuid'};
}


has 'lot_uuid' => (
  isa       => 'Str',
  is        => 'rw',
  required  => 0,
);

has 'asset_uuid' => (
  isa       => 'Str',
  is        => 'rw',
  required  => 0,
);

has 'template_uuid' => (
  isa       => 'Str',
  is        => 'rw',
  required  => 0,
);


override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  if ($self->validate_tag_plate) {
    my $tag_plate_layout = $self->tag_plate_layout($self->template_uuid);

    # if we got back a tag plate layout,
    # then we should write the tag layout to a file and
    # set the tag plate to exhausted state
    if (defined $tag_plate_layout) {
      $self->_create_tag_layout_file($tag_plate_layout);

     # $self->set_tag_plate_to_exhausted($self->asset_uuid);
    } else {
      croak sprintf 'There was an error getting back the layout of the following asset: %s.', $self->asset_uuid;
    }
  }

  return 0;
};

sub validate_tag_plate {
  my $self = shift;

  my $tag_plate = $self->_tag_plate;

  $self->asset_uuid($tag_plate->{'asset_uuid'});
  $self->lot_uuid($tag_plate->{'lot_uuid'});
  my $tag_plate_status = $tag_plate->{'state'};

  my $lot= $self->_lot($self->lot_uuid);

  $self->_set_template_uuid($lot->{'template_uuid'});

  my $lot_type = $lot->{'lot_type'};

  if ($tag_plate_status ne $self->_valid_status) {
    croak sprintf 'The plate status: %s is not valid.', $tag_plate_status;
  } elsif ($lot_type ne $self->_valid_lot_type) {
    croak sprintf 'The lot type: %s is not valid.', $lot_type;
  }

  return 1;
}



sub tag_plate_layout {
  my $self = shift;

  if (!defined $self->template_uuid) {
    croak 'The template uuid of the tag plate is not set.';
  }

  my $url = join q{/}, ($self->_gatekeeper_url, $self->template_uuid);

  my $response = $self->ss_request->get($url);

  return parse_json($response);
}

sub set_tag_plate_to_exhausted {
  my ($self, $asset_uuid) = @_;

  my $url = join q{/}, ($self->_gatekeeper_url, $STATE_CHANGE_PATH);

  my $response = $self->ss_request->post($url, $self->_exhausted_state_content);

  return parse_json($response);
}

sub _set_template_uuid {
    my ($self, $template_uuid) = @_;
    $self->template_uuid($template_uuid);

    return;
}

sub _tag_plate {
  my $self = shift;
  my $url = join q{/}, ($self->_gatekeeper_url, $self->_find_qcable_by_barcode_uuid, 'first');

  my $response = $self->ss_request->post($url, $self->_search_content);

  my $parsed_response = parse_json($response);
  return  { 'state'       => $parsed_response->{'qcable'}->{'state'},
            'lot_uuid'    => $parsed_response->{'qcable'}->{'lot'}->{'uuid'},
            'asset_uuid'  => $parsed_response->{'qcable'}->{'asset'}->{'uuid'},
          };
}

sub _lot {
  my ($self, $lot_uuid) = @_;
  my $url = join q{/}, ($self->_gatekeeper_url, $lot_uuid);

  my $response = $self->ss_request->get($url);
  my $parsed_response = parse_json($response);

  return  { 'lot_type'      => $parsed_response->{'lot'}->{'lot_type_name'},
            'template_uuid' => $parsed_response->{'lot'}->{'template'}->{'uuid'},
          };
}

sub _search_content {
  my $self = shift;
  my $content = {};

  my $barcode_element = {};
  $barcode_element->{'barcode'} = $self->_tag_plate_barcode;

  $content->{'search'} = $barcode_element;

  return $self->_convert_to_JSON($content);
}

sub _exhausted_state_content {
  my ($self, $target_uuid) = @_;
  my $content = {};

  my $state_change_element = {};
  $state_change_element->{'target_state'} = $EXHAUSTED_STATE;
  $state_change_element->{'user'} = $self->_ss_user_uuid;
  $state_change_element->{'target'} = $target_uuid;

  $content->{'state_change'} = $state_change_element;

  return $self->_convert_to_JSON($content);
}

sub _convert_to_JSON {
  my ($self, $content) = @_;

  return JSON->new->allow_nonref->encode($content);
}

sub _create_tag_layout_file {
  my ($self, $json_content) = @_;

  # TODO ke4 check which part of the JSON response should the file contains
  my $file_content =
    $self->_convert_to_JSON($json_content->{'tag_layout_template'}->{'tag_group'});
  open my $fh, '>:encoding(UTF-8)', $self->tag_layout_file_name
    or croak qq{Could not create/open file '$self->tag_layout_file_name'.};
  print $fh $file_content;
  close $fh;

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::tag_plate

=head1 SYNOPSIS

  If you want to validate a tag plate:

  my $epp = wtsi_clarity::epp::sm::tag_plate->new(
    process_url => 'http://some.com/processes/151-12090',
    tag_layout_file_name  => 'file_name',
  )->run();

  If you want to get the layout of the tag plate:

  my $epp = wtsi_clarity::epp::sm::tag_plate->new(
    process_url => 'http://some.com/processes/151-12090',
    tag_layout_file_name  => 'file_name',
  )->run();

=head1 DESCRIPTION

  Validates the plate whether it is in the correct state ('available')
  and it has got the correct lot type ('IDT Tags').
  If the plate is valid, then it gets the layout of the tag plate
  and sets the state of the tag plate to 'exhausted'.


=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head2 validate_tag_plate

This method validates the given tag plate if its is usable for this action.
The tag plate should be in 'available' state
and the relate lot type name should be 'IDT Tags'.
The following 2 methods gather the date for the validation: _tag_plate and _lot.

=head2 _tag_plate

Sends a POST request to a 3rd party application (Gatekeeper)
and returns the following tag plate properties: state, lot_uuid, asset_uuid.
The POST request body contains the UUID of the queried tag plate.

=head2 _lot

Sends a GET request to a 3rd party application (Gatekeeper)
and returns the following lot properties: name of the lot type, UUID of the related template.

# =head2 get_tag_plate_layout

# This method gets the layout of the given tag plate
# and sets its state to 'exhausted'.
# This method using the following 2 methods to execute this task:
# tag_plate_layout and set_tag_plate_to_exhausted.

=head2 tag_plate_layout

Sends a GET request to a 3rd party application (Gatekeeper)
and gets the layout of the related tag plate.

=head2 set_tag_plate_to_exhausted

Sends a POST request to a 3rd party application (Gatekeeper)
and sets the related tag plate to exhausted state.


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