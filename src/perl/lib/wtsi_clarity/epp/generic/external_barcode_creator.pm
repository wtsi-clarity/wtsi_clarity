package wtsi_clarity::epp::generic::external_barcode_creator;

use Moose;
use Readonly;
use Carp;

extends 'wtsi_clarity::epp';
with qw{wtsi_clarity::epp::generic::roles::container_common
        wtsi_clarity::epp::generic::roles::barcode_common
        wtsi_clarity::util::clarity_elements
        wtsi_clarity::util::label
        wtsi_clarity::util::print};

our $VERSION = '0.0';

Readonly::Scalar my $DEFAULT_NUMBER_OF_COPIES => 1;
Readonly::Scalar my $PRINTER_NAME             => q{Select Barcode Printer};
Readonly::Scalar my $NUMBER_OF_CONTAINER      => q{Number of Containers};
Readonly::Scalar my $TYPE_OF_CONTAINER        => q{Type of Container};
Readonly::Scalar my $USERNAME                 => q{User name};
Readonly::Scalar my $MANDATORY                => 1;

has 'number_of_containers' => (
  isa        => 'Int',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_number_of_containers {
  my $self = shift;

  return $self->find_input_parameter($self->process_doc, $NUMBER_OF_CONTAINER,$MANDATORY);
}

has 'printer_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_printer_name {
  my $self = shift;

  return $self->find_input_parameter($self->process_doc, $PRINTER_NAME, $MANDATORY);
}

has 'container_type' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_container_type {
  my $self = shift;

  return $self->find_input_parameter($self->process_doc, $TYPE_OF_CONTAINER, $MANDATORY);
}

has 'user_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_user_name {
  my $self = shift;

  return $self->find_input_parameter($self->process_doc, $USERNAME);
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  $self->_update_containers_name_with_barcodes;

  $self->print_labels($self->printer_name, $self->_label_templates);
  return;
};

has '_new_containers' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__new_containers {
  my ($self) = @_;

  my @containers_limsid = ();

  for (1..$self->number_of_containers) {
    my $container_xml = $self->create_new_container($self->container_type);

    push @containers_limsid, $self->get_container_data($container_xml)->{'limsid'};
  }

  return \@containers_limsid;
}

has '_containers_data' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__containers_data {
  my ($self) = @_;

  my %containers_data = ();

  foreach my $container_limsid (@{$self->_new_containers}) {
    my ($barcode, $num) = $self->generate_barcode($container_limsid);

    my $container_data = ();
    $container_data->{'limsid'}   = $container_limsid;
    $container_data->{'barcode'}  = $barcode;
    $container_data->{'num'}      = $num;
    $container_data->{'purpose'}  = $self->get_container_purpose($self->container_type);

    my $container_uri = join q{/}, $self->config->clarity_api->{'base_uri'}, 'containers', $container_limsid;

    $containers_data{$container_uri} = $container_data;
  }

  return \%containers_data;
}

sub _update_containers_name_with_barcodes {
  my ($self) = @_;

  my @container_uris = map { $_; } keys %{$self->_containers_data};

  my $containers_xml = $self->batch_retrieve_containers_xml(\@container_uris);

  while (my ($container_uri, $container_data) = each %{$self->_containers_data}) {
    $self->update_text(
      $containers_xml->findnodes(qq{/con:details/con:container[\@limsid="$container_data->{'limsid'}"]/name})->get_nodelist(),
      $container_data->{'barcode'}
    );
  }

  $self->request->batch_update('containers', $containers_xml);

  return $containers_xml;
}

sub _label_parameters {
  my ($self) = @_;

  my %label_parameters = ();
  $label_parameters{'number'}       = $DEFAULT_NUMBER_OF_COPIES;
  $label_parameters{'type'}         = $self->label_type_by_container_name($self->container_type);
  $label_parameters{'user'}         = $self->user_name;
  $label_parameters{'containers'}   = $self->_containers_data;
  $label_parameters{'source_plate'} = 1; # we don't need a user name for the label

  return \%label_parameters;
}

has '_label_templates' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__label_templates {
  my ($self) = @_;

  return $self->generateLabels($self->_label_parameters());
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::external_barcode_creator

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::external_barcode_creator->new(
      process_url           => 'http://clarity-ap:8080/processes/3345',
      number_of_containers  => 12,
      printer_name          => 'printer_name'
  )->run();

=head1 DESCRIPTION

  Generate barcode(s) to send to an external collaborator to have labeled plates to transfer biomaterial into.

=head1 SUBROUTINES/METHODS

=head2 run

  Method executing the epp callback

=head2 process_url

  Clarity process url, required.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::epp

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
