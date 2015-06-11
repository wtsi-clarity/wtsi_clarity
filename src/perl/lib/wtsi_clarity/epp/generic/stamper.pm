package wtsi_clarity::epp::generic::stamper;

use Moose;
use namespace::autoclean;
use Readonly;
use Carp;
use URI::Escape;
use XML::LibXML;
use Mojo::Collection 'c';
use Try::Tiny;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $IO_MAP_PATH              => q{ /prc:process/input-output-map[output[@output-type='Analyte']]};
Readonly::Scalar my $OUTPUT_IDS_PATH          => q{ /prc:process/input-output-map/output[@output-type='Analyte']/@limsid};
Readonly::Scalar my $CONTAINER_PATH           => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $BATCH_CONTAINER_PATH     => q{ /art:details/art:artifact/location/container/@limsid };
Readonly::Scalar my $WELL_PATH                => q{ /art:artifact/location/value };
Readonly::Scalar my $CONTAINER_TYPE_NAME_PATH => q{ /con:container/type/@name[1] };
Readonly::Scalar my $CONTAINER_NAME_PATH      => q{ /con:container/name/text() };
Readonly::Scalar my $CONTROL_PATH             => q{ /art:artifact/control-type };
##use critic

our $VERSION = '0.0';

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  $self->epp_log('Step url is ' . $self->step_url);

  $self->_check_options();

  $self->_create_containers();
  my $doc = $self->_create_placements_doc;

  if ($self->copy_on_target) {
    # in terms of wells, one well (e.g. A1) will be transfered to several wells (hence the 'copy') on the output plates
    $doc = $self->_stamping($doc, \&_stamp_with_copy, \&_direct_well_calculation);
  } elsif ($self->group) {
    $doc = $self->_stamping($doc, \&_group_inputs_by_container_stamp);
  } else {
    # in terms of wells, one well (e.g. A1) will be transfered to only one well on the output plate
    $doc = $self->_stamping($doc, \&_direct_stamp, \&_direct_well_calculation);
  }

  $self->request->post($self->step_url . '/placements', $doc->toString);

  if ($self->shadow_plate) {
    $self->_transfer_plate_name();
  }

  return;
};

sub _check_options {
  my $self = shift;

  if ($self->shadow_plate && $self->copy_on_target ) {
    croak qq{One cannot use the shadow plate stamping with the copy_on_target option!};
  }

  if ($self->shadow_plate && $self->has_container_type_name) {
    $self->epp_log(q{Argument container_type_name should not be provided when shadow stamping. Output container type(s) will match input container type(s)});
    $self->clear_container_type_name;
  }

  if ($self->group && $self->copy_on_target) {
    croak q{One can not use the group stamping with the copy_on_target option!};
  }

  ##no critic ValuesAndExpressions::ProhibitMagicNumbers
  if ($self->group && $self->process_doc->input_artifacts->findnodes('/art:details/art:artifact')->size() > 96) {
    croak q{Can not do a group stamp for more than 96 inputs!};
  }
  ##use critic

  return 1;
}

##

has 'controls' => (
  isa       => 'Bool',
  is        => 'rw',
  required  => 0,
  default   => 1,
  predicate => 'has_controls',
  writer    => 'set_controls',
);

has 'group' => (
  isa      => 'Bool',
  is       => 'ro',
  required => 0,
  default  => 0,
);

has 'copy_on_target' => (
  isa      => 'Bool',
  is       => 'ro',
  required => 0,
  default  => 0,
);

has 'container_type_name' => (
  isa        => 'ArrayRef[Str]',
  is         => 'ro',
  required   => 0,
  predicate  => 'has_container_type_name',
  clearer    => 'clear_container_type_name',
  lazy_build => 1,
);
sub _build_container_type_name {
  my $self = shift;
  my @container_urls = keys %{$self->_analytes};
  my $doc = $self->_analytes->{$container_urls[0]}->{'doc'};
  $self->_set_validate_container_type(0);
  return [$doc->findvalue($CONTAINER_TYPE_NAME_PATH)];
}

has 'shadow_plate' => (
  isa      => 'Bool',
  is       => 'ro',
  required => 0,
  default  => 0,
  trigger  => \&_set_controls,
);

# If it's a shadow_plate and controls haven't been set, we always want to stamp controls too,
# so we set controls to 1
sub _set_controls {
  my $self = shift;
  my $shadow_plate = shift;

  if (!$self->has_controls && $shadow_plate == 1) {
    $self->set_controls(1);
  }

  return;
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
      my $url   = $self->config->clarity_api->{'base_uri'} . q{/containertypes?name=} . $ename;
      my $doc   = $self->fetch_and_parse($url);
      my @nodes = $doc->findnodes(q{/ctp:container-types/container-type});
      if (!@nodes) {
        croak qq[Did not find container type entry at $url];
      }
      my $xml = $nodes[0]->toString();
      $xml =~ s/container-type/type/xms;
      push @types, $xml;
    }
  } else {
    my @container_urls = keys %{$self->_analytes};
    my $doc   = $self->_analytes->{$container_urls[0]}->{'doc'};
    my @nodes = $doc->findnodes(q{ /con:container/type });
    push @types, $nodes[0]->toString();
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
    my $analyte_dom   = $self->fetch_and_parse($url);
    my $container_url = $analyte_dom->findvalue($CONTAINER_PATH);

    if (!$container_url) {
      croak qq[Container not defined for $url];
    }

    my @control_flag = $analyte_dom->findnodes($CONTROL_PATH);

    # By default we do not want to stamp controls
    if (@control_flag && !$self->controls) {
      next;
    }

    if (!exists $containers->{$container_url}) {
      my $container_doc = $self->fetch_and_parse($container_url);
      $containers->{$container_url}->{'doc'} = $container_doc;
    }

    my $well = $analyte_dom->findvalue($WELL_PATH);

    if (!$well) {
      croak 'Well not defined';
    }

    $containers->{$container_url}->{$url}->{'well'} = $well;
    ##no critic (RequireInterpolationOfMetachars)
    my $uri = $anode->findvalue(q{./output/@uri}); # ideally, we have to check that this output is
                                                   # of type 'Analyte'
    ##use critic
    if (!$uri) {
      croak qq[Target analyte uri not defined for container $container_url input analyte $url];
    }
    ($uri) = $uri =~ /\A([^?]*)/smx; #drop part of the uri starting with ? (state)
    push @{$containers->{$container_url}->{$url}->{'target_analyte_uri'}}, $uri;
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get input containers for process ] . $self->process_url;
  }
  return $containers;
}

has '_output_container_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__output_container_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my $output_ids = $self->grab_values($self->process_doc->xml, $OUTPUT_IDS_PATH);
  my @output_uris = c ->new(@{$output_ids})
                      ->uniq()
                      ->map( sub {
                          return $base_url.'/artifacts/'.$_;
                        } )
                      ->each;
  my $output_details = $self->request->batch_retrieve('artifacts', \@output_uris );

  my $container_ids = $self->grab_values($output_details, $BATCH_CONTAINER_PATH);
  my @container_uris = c->new(@{$container_ids})
                        ->uniq()
                        ->map( sub {
                            return $base_url.'/containers/'.$_;
                          } )
                        ->each;
  return $self->request->batch_retrieve('containers', \@container_uris );
};

sub _transfer_plate_name {
  my $self = shift;
  $self ->_update_plate_name_with_previous_name();

  return $self->request->batch_update('containers', $self->_output_container_details);
}

sub _update_plate_name_with_previous_name {
  my $self = shift;

  while (my ($in_container_uri, $in_container_map) = each %{$self->_analytes} ) {
    my $names = $self->grab_values($in_container_map->{'doc'}, $CONTAINER_NAME_PATH);

    if ( @{$names} < 1 ) {
      croak qq{One input container ($in_container_uri) has no name!};
    }

    my @output_containers = @{$in_container_map->{'output_containers'}};

    if ( @output_containers < 1 ) {
      croak qq{There is no output container for this input ($in_container_uri)! The shadow stamping cannot be applied!};
    }
    if ( @output_containers > 1 ) {
      croak qq{There are more than one output container for this input ($in_container_uri)! The shadow stamping cannot be applied!};
    }

    my $output_container_id = $output_containers[0]->{'limsid'};

    my @containers = c->new($self->_output_container_details->findnodes( qq{/con:details/con:container[\@limsid="$output_container_id"]/name} )->get_nodelist())
                      ->each(sub{
                          $self->update_text($_, @{$names}[0] );
                        } ) ;
  }

  return $self->_output_container_details;
}

sub _create_containers {
  my $self = shift;

  if ((scalar @{$self->container_type_name} > 1) &&
      (scalar keys %{$self->_analytes} > 1)) {
    croak 'Multiple container type names are not compatible with multiple input containers';
  }

  # If grouping we only need one output container...
  if ($self->group) {
    my $container_doc = $self->_create_container($self->_container_type->[0]);

    foreach my $input_container ( keys %{$self->_analytes} ) {
      push@{$self->_analytes->{$input_container}->{'output_containers'}}, $self->_build_container_info($container_doc);
    }

    return;
  }

  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $output_container_type_xml (@{$self->_container_type}) {

      my $container_doc = $self->_create_container($output_container_type_xml);
      push @{$self->_analytes->{$input_container}->{'output_containers'}}, $self->_build_container_info($container_doc);
    }
  }
  return;
}

sub _build_container_info {
  my ($self, $container_doc) = @_;

  ##no critic (RequireInterpolationOfMetachars)
  return { 'limsid' => $container_doc->findvalue(q{ /con:container/@limsid }),
           'uri'    => $container_doc->findvalue(q{ /con:container/@uri    }),
           'doc'    => $container_doc,                                     };
}

sub _create_container {
  my ($self, $output_container_type_xml) = @_;

  my $xml_header = '<?xml version="1.0" encoding="UTF-8"?>';
  $xml_header   .= '<con:container xmlns:con="http://genologics.com/ri/container">';
  my $xml_footer = '</con:container>';

  my $xml = $xml_header;
  $xml   .= $output_container_type_xml;
  $xml   .= $xml_footer;

  my $url = $self->config->clarity_api->{'base_uri'} . '/containers';
  my $container_doc = XML::LibXML->load_xml(string => $self->request->post($url, $xml));

  return $container_doc;
}

sub _create_placements_doc {
  my $self = shift;

  my $pXML = '<?xml version="1.0" encoding="UTF-8"?>';
  $pXML   .= '<stp:placements xmlns:stp="http://genologics.com/ri/step" uri="' . $self->process_url . '/placements">';
  $pXML   .= '<step uri="' . $self->step_url . '"/>';
  $pXML   .= '<selected-containers>';

  my %containers = ();

  foreach my $input_container ( keys %{$self->_analytes}) {
    foreach my $output_container (@{$self->_analytes->{$input_container}->{'output_containers'}}) {
      my $container_url = $output_container->{'uri'} ;

      if (exists $containers{$container_url}) {
        next;
      }

      $containers{$container_url} = 1;

      $pXML .= '<container uri="' . $container_url . '"/>';
    }
  }
  $pXML .= '</selected-containers>';
  $pXML .= '<output-placements/></stp:placements>';

  return XML::LibXML->load_xml(string => $pXML);
}

sub _stamping {
  my ($self, $doc, $stamping_callback, $well_callback) = @_;

  my @wells = (); # Ordered list of wells
  my $well;
  if (!defined $well_callback) {
    ##no critic ValuesAndExpressions::ProhibitMagicNumbers
    for (1..12) {
      foreach my $column ('A'..'H') {
        push @wells, $column . ':' . $_;
      }
    }
    ##use critic
  }

  my @placements = $doc->findnodes(q{ /stp:placements/output-placements });

  if (!@placements) {
    croak 'Placements element not found';
  }

  foreach my $input_container (keys %{$self->_analytes}) {
    foreach my $input_analyte ( keys %{$self->_analytes->{$input_container} } ) {
      if ( $input_analyte eq 'output_containers' || $input_analyte eq 'doc' ) {
        next;
      }
      if (defined $well_callback) {
        $well = $well_callback->($self, $input_container, $input_analyte);
      } else {
        $well = shift @wells;
      }
      ($doc, my @new_placements) = $stamping_callback->($self, $doc, $input_container, $input_analyte, $well);
      foreach my $placement (@new_placements) {
        $placements[0]->addChild($placement);
      }
    }
  }

  return $doc;
}

sub _direct_well_calculation {
  my ($self, $input_container, $input_analyte) = @_;

  return $self->_analytes->{$input_container}->{$input_analyte}->{'well'};
}

sub _direct_stamp {
  my ($self, $doc, $input_container, $input_analyte, $well) = @_;

  my @new_placements = ();
  my $container_index = 0;
  foreach my $output_container ( @{$self->_analytes->{$input_container}->{'output_containers'}} ) {
    my $uri = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'}->[$container_index];
    if (!$uri) {
      croak qq[No target analyte uri for container index $container_index];
    }

    my $placement = $self->_create_placement($doc, $uri, $output_container, $well);
    push @new_placements, $placement;

    $container_index++;
  }

  return ($doc, @new_placements);
}

sub _stamp_with_copy {
  my ($self, $doc, $input_container, $input_analyte, $well) = @_;

  my @new_placements = ();
  my ($destination_well_1, $destination_well_2) = $self->calculate_destination_wells($well);
  my $output_container = @{$self->_analytes->{$input_container}->{'output_containers'}}[0]; # Always just 1 here

  my $output_artifact_uris = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'};

  my $placement = $self->_create_placement($doc, $output_artifact_uris->[0], $output_container, $destination_well_1);
  push @new_placements, $placement;

  $placement = $self->_create_placement($doc, $output_artifact_uris->[1], $output_container, $destination_well_2);
  push @new_placements, $placement;

  return ($doc, @new_placements);
}

sub _group_inputs_by_container_stamp {
  my ($self, $doc, $input_container, $input_analyte, $well) = @_;

  my @new_placements = ();
  my $output_container = @{$self->_analytes->{$input_container}->{'output_containers'}}[0];
  my $output_artifact_uri = $self->_analytes->{$input_container}->{$input_analyte}->{'target_analyte_uri'}[0];

  my $placement = $self->_create_placement($doc, $output_artifact_uri, $output_container, $well);
  push @new_placements, $placement;

  return ($doc, @new_placements);
}

sub calculate_destination_wells {
  my ($self, $source_well) = @_;
  my $ord_of_A = ord 'A';
  my $ord_of_H = ord 'H';

  my ($row, $column) = split /:/sxm, $source_well;

  my $ord_of_row = ord $row;

  if ($ord_of_row < $ord_of_A or $ord_of_row > $ord_of_H) {
    croak "Source plate must be a 96 well plate";
  }

  my $destination_row = (2 * $ord_of_row) - $ord_of_A;
  my $destination_column = (2 * $column) - 1;

  my $well1 = join q{:}, chr $destination_row, $destination_column;
  my $well2 = join q{:}, chr ($destination_row + 1), $destination_column;

  return ($well1, $well2);
}

sub _create_placement {
  my ($self, $doc, $output_artifact_uri, $output_container, $well) = @_;
  my $placement = $doc->createElement('output-placement');
  $placement->setAttribute( 'uri', $output_artifact_uri );

  my $location = $doc->createElement('location');
  $placement->addChild($location);

  my $container = $doc->createElement('container');

  $location->addChild($container);
  $location->appendTextChild('value', $well);

  $container->setAttribute( 'uri', $output_container->{'uri'} );
  $container->setAttribute( 'limsid', $output_container->{'limsid'} );

  return $placement;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::stamper

=head1 SYNOPSIS

  1:1 and N:N scanarios, output container type will be copied from the input
  containers:

  wtsi_clarity::epp:generic::stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
  )->run();

  1:1 and N:N scanarios, output container type will be copied from the input
  containers. Will also copy over controls:

  wtsi_clarity::epp:generic::stamper->new(
       process_url   => 'http://clarity-ap:8080/processes/3345',
       step_url      => 'http://testserver.com:1234/here/steps/24-98970',
       controls => 1,
  )->run();

  N:1-N scenario, output container analytes will be grouped by input container

  wtsi_clarity::epp::generic::stamper->new(
    process_url => 'http://clarity-ap:8080/processes/1234',
    step_url    => 'http://clarity-ap:8080/steps/5678',
    group       => 1,
  )->run();

  1:1 shadow plate scanario, output container type will be copied from the input
  containers, which will have the same barcode (name):

  wtsi_clarity::epp:generic::stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
       shadow_plate => 1,
  )->run();

  1:1 and N:N scanarios with explicit output container type name:

  wtsi_clarity::epp:generic::stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
       container_type_name => ['ABgene 0800']
  )->run();

  1:2 scenario, the same output container type names:

  wtsi_clarity::epp:generic::stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
       container_type_name => ['ABgene 0800', 'ABgene 0800']
  )->run();

  1:2 scenario, different output container type names:

  wtsi_clarity::epp:generic::stamper->new(
       process_url => 'http://clarity-ap:8080/processes/3345',
       step_url    => 'http://testserver.com:1234/here/steps/24-98970',
       container_type_name => ['ABgene 0800', 'ABgene 0765']
  )->run();

  1:1 scenario, double outputs of inputs

  wtsi_clarity::epp::generic::stamper->new(
    process_url => 'http://clarity-ap:8080/processes/3345',
    step_url    => 'http://testserver.com:1234/here/steps/24-98970',
    container_type_name => ['384 Well Plate'],
    copy_on_target => 1
  )->run();

=head1 DESCRIPTION

  Stamps the content of source plates to desctination plates.
  Three scenarios are considered: 1:1, N:N (in pairs), 1:N.

  Input controls and their containers are ignored.

  To set up stamping from one to multiple plates, container type name should be
  set explicitly by the caller as many times as the number of output containers required.

=head1 SUBROUTINES/METHODS

=head2 run

  Method executing the epp callback

=head2 process_url

  Clarity process url, required.

=head2 step_url

  Clarity step url, required.

=head2 calculate_destination_wells

  Calculates the two destination wells for a 96->384 well plate stamping

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=item Readonly

=item URI::Escape

=item XML::LibXML

=item Mojo::Collection 'c'

=item Try::Tiny

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::util::roles::clarity_process_base

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>cs24@sanger.ac.ukE<gt>

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
