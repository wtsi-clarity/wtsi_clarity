package wtsi_clarity::epp::generic::plate_storer;

use Moose;
use Carp;
use Readonly;
use List::MoreUtils qw/uniq/;
use Mojo::Collection 'c';
use Data::Dumper;


extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_ARTIFACTS_IDS_PATH               => q(/prc:process/input-output-map/input/@limsid);
Readonly::Scalar my $ARTEFACTS_ARTEFACT_CONTAINTER_IDS_PATH => q{/art:details/art:artifact/location/container/@limsid};

Readonly::Scalar my $FREEZER_XPATH              => q{/prc:process/udf:field[@name="Freezer Barcode"]/text()};
Readonly::Scalar my $SHELF_XPATH                => q{/prc:process/udf:field[@name="Shelf"]/text()};
Readonly::Scalar my $TRAY_XPATH                 => q{/prc:process/udf:field[@name="Tray"]/text()};
Readonly::Scalar my $RACK_XPATH                 => q{/prc:process/udf:field[@name="Rack"]/text()};
## use critic


our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();
  $self->_main_method();
  return;
};

sub _main_method {
  my $self= shift;
  $self->_update_container_details();
  $self->request->batch_update('containers', $self->_input_container_details);
  return;
}

has '_freezer_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__freezer_barcode {
  my ($self) = @_;
  my $v = $self->_get_process_udf(qq{Freezer barcode}, $FREEZER_XPATH);
  if ($v eq q{}) {
    croak qq{The freezer barcode is missing!};
  }
  return $v;
}

has '_tray_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__tray_barcode {
  my ($self) = @_;
  return $self->_get_process_udf(qq{Tray}, $TRAY_XPATH);
}

has '_shelf_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__shelf_barcode {
  my ($self) = @_;
  return $self->_get_process_udf(qq{Shelf}, $SHELF_XPATH);
}

has '_rack_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__rack_barcode {
  my ($self) = @_;
  return $self->_get_process_udf(qq{Rack}, $RACK_XPATH);
}

sub _get_process_udf {
  my ($self, $name, $xpath) = @_;
  my $v = $self->grab_values($self->process_doc, $xpath);
  if (@{$v} > 1) {
    confess qq{Too many values for the $name!};
  }
  if (@{$v} < 1) {
    return q{};
  }
  return @{$v}[0];
}

has '_input_artifacts_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifacts_ids {
  my ($self) = @_;
  return $self->grab_values($self->process_doc, $INPUT_ARTIFACTS_IDS_PATH);
}

has '_input_artifacts_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifacts_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris = c->new(@{$self->_input_artifacts_ids})
              ->map( sub {
                  return $base_url.'/artifacts/'.$_;
                } )
              ->each;
  return $self->request->batch_retrieve('artifacts', \@uris );
};

has '_input_container_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_container_ids {
  my $self = shift;
  return $self->grab_values($self->_input_artifacts_details, $ARTEFACTS_ARTEFACT_CONTAINTER_IDS_PATH);
}

has '_input_container_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_container_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris =  c->new(@{$self->_input_container_ids})
              ->uniq()
              ->map( sub { $base_url . '/containers/' . $_; } )
              ->each();
  return $self->request->batch_retrieve('containers', \@uris );
};


sub _update_container_details {
  my $self = shift;

# udf:field type="String" name="WTSI Freezer">123456789</udf:f
  $self->update_nodes(document => $self->_input_container_details,
                      xpath    => qq{/con:details/con:container},
                      type     => qq{Text},
                      udf_name => qq{WTSI Freezer},
                      value    => $self->_freezer_barcode);
  $self->update_nodes(document => $self->_input_container_details,
                      xpath    => qq{/con:details/con:container},
                      type     => qq{Text},
                      udf_name => qq{WTSI Tray},
                      value    => $self->_tray_barcode);
  $self->update_nodes(document => $self->_input_container_details,
                      xpath    => qq{/con:details/con:container},
                      type     => qq{Text},
                      udf_name => qq{WTSI Rack},
                      value    => $self->_rack_barcode);
  $self->update_nodes(document => $self->_input_container_details,
                      xpath    => qq{/con:details/con:container},
                      type     => qq{Text},
                      udf_name => qq{WTSI Shelf},
                      value    => $self->_shelf_barcode);
  return $self->_input_container_details;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::plate_storer

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::plate_storer->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  records the location information about the current plate

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