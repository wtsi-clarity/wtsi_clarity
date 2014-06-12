package wtsi_clarity::epp::stamp;

use Moose;
use namespace::autoclean;
use Readonly;
use Carp;
use URI::Escape;
use XML::LibXML;

extends 'wtsi_clarity::epp';

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $IO_MAP_PATH    => q{ /prc:process/input-output-map[output[@output-type='Analyte']]};
Readonly::Scalar my $CONTAINER_PATH => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $WELL_PATH      => q{ /art:artifact/location/value };
Readonly::Scalar my $CONTAINER_TYPE_NAME_PATH => q{ /con:container/type/@name };
Readonly::Scalar my $CONTROL_PATH   => q{ /art:artifact/control-type };
##use critic

our $VERSION = '0.0';

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
);

has 'container_type_name' => (
  isa        => 'ArrayRef[Str]',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_container_type_name {
  my $self = shift;
  my @container_urls = keys %{$self->_analytes};
  my $doc = $self->_analytes->{$container_urls[0]}->{'doc'};
  $self->_set_validate_container_type(0);
  return [$doc->findvalue($CONTAINER_TYPE_NAME_PATH)];
}

has '_validate_container_type' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 1,
  writer     => '_set_validate_container_type',
);

has '_container_type' => (
  isa        => 'ArrayRef[Str]',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container_type {
  my $self = shift;
  my $names = $self->container_type_name;
  my @types = ();
  if ($self->_validate_container_type) {
    foreach my $name (@{$names}) {
      my $ename = uri_escape($name);
      my $url = $self->base_url . q{containertypes?name=} . $ename;
      my $doc = $self->fetch_and_parse($url);
      my @nodes =  $doc->findnodes(q{/ctp:container-types/container-type});
      if (!@nodes) {
        croak qq[Did not find container type entry at $url];
      }
      my $xml = $nodes[0]->toString();
      $xml =~ s/container-type/type/xms;
      push @types, $xml;
    }
  } else {
    my @container_urls = keys %{$self->_analytes};
    my $doc = $self->_analytes->{$container_urls[0]}->{'doc'};
    my @nodes =  $doc->findnodes(q{ /con:container/type });
    push @types, $nodes[0]->toString();;
  }
  return \@types;
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
    my @control_flag = $analyte_dom->findnodes($CONTROL_PATH);
    if (@control_flag) {
      next;
    }
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
    my $uri = $anode->findvalue(q{./output/@uri});
    ##use critic
    if (!$uri) {
      croak qq[Target analyte uri not defined for container $container_url input analyte $url];
    }
    ($uri) = $uri =~ /\A([^?]*)/smx; #drop part of the uri starting with ? (state)
    $containers->{$container_url}->{$url}->{'target_analyte_uri'} = $uri;
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get input containers for process ] . $self->process_url;
  }
  return $containers;
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  $self->epp_log('Step url is ' . $self->step_url);
  $self->_create_containers();
  my $doc = $self->_create_placements_doc;
  $doc = $self->_create_output_placements($doc);
  $self->request->post($self->step_url . '/placements', $doc->toString);
  return;
};

sub _create_containers {
  my $self = shift;

  my $xml_header = '<?xml version="1.0" encoding="UTF-8"?>';
  $xml_header .= '<con:container xmlns:con="http://genologics.com/ri/container">';
  my $xml_footer = '</con:container>';

  if ((scalar @{$self->container_type_name} > 1) && 
      (scalar keys %{$self->_analytes} > 1)) {
    croak 'Multiple container type names are not compatible with multiple input containers';
  }

  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $output_container_type (@{$self->container_type_name}) {
      my $xml = $xml_header;
      $xml .= $output_container_type;
      $xml .= $xml_footer;
      my $url = $self->base_url . 'containers';
      my $container_doc = XML::LibXML->load_xml(string => $self->request->post($url, $xml));
      ##no critic (RequireInterpolationOfMetachars)
      my $h = { 'limsid' => $container_doc->findvalue(q{ /con:container/@limsid }),
              'uri'    => $container_doc->findvalue(q{ /con:container/@uri }) };
      ##use critic
      push @{$self->_analytes->{$input_container}->{'output_containers'}}, $h;
    }
  }
  return;
}

sub _create_placements_doc {
  my $self = shift;

  my $pXML = '<?xml version="1.0" encoding="UTF-8"?>';
  $pXML .= '<stp:placements xmlns:stp="http://genologics.com/ri/step" uri="' . $self->process_url . '/placements">';
  $pXML .= '<step uri="' . $self->step_url . '"/>';
  $pXML .= '<selected-containers>';
  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $output_container (@{$self->_analytes->{$input_container}->{'output_containers'}}) {
      my $container_url = $output_container->{'uri'} ;
      $pXML .= '<container uri="' . $container_url . '"/>';
    }
  }
  $pXML .= '</selected-containers>';
  $pXML .= '<output-placements/></stp:placements>';

  return XML::LibXML->load_xml(string => $pXML);
}

sub _create_output_placements {
  my ($self, $doc) = @_;

  my @placements = $doc->findnodes(q{ /stp:placements/output-placements });
  if (!@placements) {
    croak 'Placements element not found';
  }

  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $input_analyte ( keys %{$self->_analytes->{$input_container} } ) {
      if ( $input_analyte eq 'output_containers' || $input_analyte eq 'doc' ) {
        next;
      }
      my $uri = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'};
      my $well = $self->_analytes->{$input_container}->{$input_analyte}->{'well'};

      foreach my $output_container ( @{$self->_analytes->{$input_container}->{'output_containers'}} ) {
        my $placement = $doc->createElement('output-placement');
        $placement->setAttribute( 'uri', $uri );
        my $location = $doc->createElement('location');
        $placement->addChild($location);
        my $container = $doc->createElement('container');
        $location->addChild($container);
        $container->setAttribute( 'uri', $output_container->{'uri'} );
        $container->setAttribute( 'limsid', $output_container->{'limsid'} );
        $location->appendTextChild('value', $well);
        $placements[0]->addChild($placement);
      }
    }
  }

  return $doc;
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

=head2 step_url

  Clarity step url, required.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=item Readonly

=item URI::Escape

=item XML::LibXML

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
