package wtsi_clarity::epp::stamp;

use Moose;
use namespace::autoclean;
use Readonly;
use Carp;
use URI::Escape;

extends 'wtsi_clarity::epp';

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $IO_MAP_PATH    => q{ /prc:process/input-output-map[output[@output-type='Analyte']]};
Readonly::Scalar my $CONTAINER_PATH => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $WELL_PATH      => q{ /art:artifact/location/value };
Readonly::Scalar my $CONTAINER_TYPE_NAME_PATH => q{ /con:container/type/@name };
##use critic

our $VERSION = '0.0';

has 'container_type_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_container_type_name {
  my $self = shift;
  my @container_urls = keys %{$self->_analytes};
  my $doc = $self->_analytes->{$container_urls[0]}->{'doc'};
  $self->_set_validate_container_type(0);
  return $doc->findvalue($CONTAINER_TYPE_NAME_PATH);
}

has '_validate_container_type' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 1,
  writer     => '_set_validate_container_type',
);

has '_container_type' => (
  isa        => 'XML::LibXML::Node',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container_type {
  my $self = shift;
  my $name = $self->container_type_name;
  my @nodes;
  if ($self->_validate_container_type) {
    my $ename = uri_escape($name);
    my $doc = $self->fetch_and_parse($self->base_url . q{containertypes?name=} . $ename);
    @nodes =  $doc->findnodes(q{/ctp:container-types/container-type});
  } else {
    my @container_urls = keys %{$self->_analytes};
    my $doc = $self->_analytes->{$container_urls[0]}->{'doc'};
    @nodes =  $doc->findnodes(q{ /con:container/type });
  }
  if (scalar @nodes > 1) {
    croak q[Multiple container types for container name ] . $name;
  }
  return $nodes[0];
}

has '_analytes' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__analytes {
  my $self = shift;

  my @nodes = $self->process_doc->findnodes($IO_MAP_PATH);
  if (!@nodes) {
    croak 'No analytes registered';
  }

  my $containers = {};
  foreach my $anode (@nodes) {
    ##no critic (RequireInterpolationOfMetachars)
    my $url = $anode->findvalue(q{./input/@uri});
    ##use critic
    my $analyte_dom = $self->fetch_and_parse($url);
    my $container_url = $analyte_dom->findvalue($CONTAINER_PATH);
    if (!$container_url) {
      croak qq[Container not defined for $url];
    }

    if (!exists $containers->{$container_url}) {
      $containers->{$container_url}->{'doc'} = $self->fetch_and_parse($container_url);
    }
    my $well = $analyte_dom->findvalue($WELL_PATH);
    if (!$well) {
      croak 'Well not defined';
    }
    $containers->{$container_url}->{$url}->{'well'} = $well;
    ##no critic (RequireInterpolationOfMetachars)
    $containers->{$container_url}->{$url}->{'target_analyte_doc'} =
      $self->fetch_and_parse($anode->findvalue(q{./output/@uri}));
    ##use critic
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get input containers for process ] . $self->process_url;
  }
  return $containers;
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  $self->_create_containers();
  $self->_update_target_analytes();
  $self->_post_updates();
};

sub _create_containers {
  my $self = shift;

  my $xml = '<?xml version="1.0" encoding="UTF-8"?>';
  $xml .= '<con:container xmlns:con="http://genologics.com/ri/container">';
  $xml .= $self->_container_type->toString;
  $xml .= '</con:container>';

  foreach my $input_container ( keys %{$self->_analytes}) {
    my $url = $self->base_url . 'containers';
    my $container_doc = XML::LibXML->load_xml(string => $self->request->post($url, $xml));
    ##no critic (RequireInterpolationOfMetachars)
    my $h = { 'limsid' => $container_doc->findvalue(q{ /con:container/@limsid }),
              'uri'    => $container_doc->findvalue(q{ /con:container/@uri }) };
    ##use critic
    $self->_analytes->{$input_container}->{'output_container'} = $h;
  }
  return;
}

sub _update_target_analytes {
  my $self = shift;

  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $input_analyte ( keys %{$self->_analytes->{$input_container} } ) {
      if ( $input_analyte eq 'output_container' || $input_analyte eq 'doc' ) {
        next;
      }
      my $doc = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_doc'};
      if (!$doc) {
        croak qq[Target analyte not defined for container $input_container, input analyte $input_analyte];
      }
      ##no critic (RequireInterpolationOfMetachars)
      my $uri = $doc->findvalue(q{ /art:artifact/@uri });
      ##use critic
      if (!$uri) {
        croak q[Target uri not known'];
      }
      $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'} = $uri;
      my $location = $doc->createElement('location');
      my $container = $doc->createElement('container');
      $location->addChild($container);
      $container->setAttribute( 'uri', $self->_analytes->{$input_container}->{'output_container'}->{'uri'} );
      $container->setAttribute( 'limsid', $self->_analytes->{$input_container}->{'output_container'}->{'limsid'} );
      $location->appendTextChild('value', $self->_analytes->{$input_container}->{$input_analyte}->{'well'});
      $doc->getDocumentElement()->addChild($location);
    }
  }
  return;
}

sub _post_updates {
  my $self = shift;
  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $input_analyte ( keys %{$self->_analytes->{$input_container} }) {
      my $doc = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_doc'};
      $self->request->post($doc->toString, $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'});
    }
  }
  return;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

wtsi_clarity::epp::stamp

=head1 SYNOPSIS
  
  wtsi_clarity::epp:stamp->new(process_url => 'http://my.com/processes/3345')->run();
  
=head1 DESCRIPTION

  Stamps the content of source plates to desctination plates.
  Three scenarios are considered: 1:1, N:N (in pairs), 1:N

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

=item namespace::autoclean

=item Readonly

=item URI::Encode

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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
