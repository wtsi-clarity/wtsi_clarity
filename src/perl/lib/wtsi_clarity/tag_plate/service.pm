package wtsi_clarity::tag_plate::service;

use Moose;
use Carp;
use Readonly;
use JSON;

use wtsi_clarity::util::request;
use wtsi_clarity::util::error_reporter qw/croak/;

with qw/MooseX::Getopt wtsi_clarity::util::configurable/;

our $VERSION = '0.0';

Readonly::Scalar my $EXHAUSTED_STATE               => q[exhausted];
Readonly::Scalar my $STATE_CHANGE_PATH             => q[state_changes];
Readonly::Scalar my $GATEKEEPER_VALID_PLATE_STATUS => q[available];

has 'barcode' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has '_gkurl' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__gkurl {
  my $self = shift;
  return $self->config->tag_plate->{'gatekeeper_url'};
}

has '_gkrequest' => (
  isa        => 'wtsi_clarity::util::request',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__gkrequest {
  my $self = shift;
  my $api_key = $self->config->tag_plate->{'api_key'};
  if (!$api_key) {
    croak( 'api key for GateKeeper is not defined in the configuration file.');
  }

  return wtsi_clarity::util::request->new(
    'content_type'        => 'application/json',
    'additional_headers'  => { 'Cookie' => "api_key=$api_key"},
    'ss_request'          => 1,
  );
}

has '_tag_plate' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__tag_plate {
  my ($self) = @_;

  my $path = $self->config->tag_plate->{'search_path'};
  if (!$path) {
    croak( 'Search path is not defined in the configuration file');
  }
  my $url = join q{/}, ($self->_gkurl, $path, 'first');
  my $response = $self->_gkrequest->post($url, to_json({'search' => {'barcode' => $self->barcode,},}) );
  my $parsed_response = from_json($response);
  my $meta=  { 'state'       => $parsed_response->{'qcable'}->{'state'},
               'lot_uuid'    => $parsed_response->{'qcable'}->{'lot'}->{'uuid'},
               'asset_uuid'  => $parsed_response->{'qcable'}->{'asset'}->{'uuid'},
               'qcable_uuid' => $parsed_response->{'qcable'}->{'uuid'},
             };
  foreach my $key (keys %{$meta}) {
    if (!$meta->{$key}) {
      croak( "Failed to get '$key' info about the tag plate");
    }
  }

  return $meta;
}

sub _template_uuid {
  my ($self, $lot_uuid) = @_;
  my $url = join q{/}, ($self->_gkurl, $self->_tag_plate->{'lot_uuid'});
  my $data =  from_json($self->_gkrequest->get($url));
  return $data->{'lot'}->{'template'}->{'uuid'};
}

sub validate {
  my ($self) = @_;
  my $state = $self->_tag_plate->{'state'};
  if ($state ne $GATEKEEPER_VALID_PLATE_STATUS) {
    croak( "Plate status '$state' is not valid.");
  }
  return;
}

sub get_layout {
  my $self = shift;

  my $template_uuid = $self->_template_uuid();
  if (!$template_uuid) {
    croak( 'The template uuid of the tag plate is not set');
  }

  my $expected = $self->config->tag_plate->{'template_uuid'};
  if ($expected && ($template_uuid ne $expected)) {
    croak( "Unexpected template identifier $template_uuid");
  }

  my $url = join q{/}, ($self->_gkurl, $template_uuid);
  my $layout =  from_json($self->_gkrequest->get($url));
  if (!exists $layout->{'tag_layout_template'}) {
    croak( 'Layout template is missing');
  }
  return $layout;
}

sub mark_as_used {
  my ($self) = @_;

  my $user = $self->config->tag_plate->{'user_uuid'};
  if (!$user) {
    croak( 'User uuid is not found in the configuration file');
  }

  my $meta = $self->_tag_plate();
  my $url = join q{/}, ($self->_gkurl, $STATE_CHANGE_PATH);

  my $state_change_element = {};
  $state_change_element->{'target_state'} = $EXHAUSTED_STATE;
  $state_change_element->{'user'}         = $user;
  $state_change_element->{'target'}       = $meta->{'asset_uuid'};

  $self->_gkrequest->post($url, to_json( {'state_change' => $state_change_element} ));

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::tag_plate::service

=head1 SYNOPSIS

  my $gk = wtsi_clarity::tag_plate::service->new(barcode => $plate_barcode);
  $gk->validate(); #error if the plate is not valid
  $gk->get_layout();
  $gk->mark_as_used();

=head1 DESCRIPTION

  Accesses the 'Gatekeeper' tag plate micro-service to validate tag plates,
  marks them as used and gets the layout of tag sequences on these plates.

=head1 SUBROUTINES/METHODS

=head2 validate

  Checks if the tag plate is usable.

=head2 get_layout

  Returns a hash representation of plate layout.

=head2 mark_as_used

  Markes the plate as exhausted (used).

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::util::error_reporter

=item JSON

=item Readonly

=item wtsi_clarity::util::request

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
