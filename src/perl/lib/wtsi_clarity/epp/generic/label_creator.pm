package wtsi_clarity::epp::generic::label_creator;

use Moose;
use Carp;
use Readonly;
use DateTime;
use namespace::autoclean;
use List::MoreUtils qw/uniq any/;

use wtsi_clarity::util::signature;

extends 'wtsi_clarity::epp';
with qw{wtsi_clarity::util::clarity_elements
        wtsi_clarity::util::print
        wtsi_clarity::util::label
        wtsi_clarity::epp::generic::roles::barcode_common
        wtsi_clarity::epp::isc::pooling::pooling_common};

our $VERSION = '0.0';

##no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PRINTER_PATH             => q{ /prc:process/udf:field[contains(@name, 'Printer')] };
Readonly::Scalar my $NUM_COPIES_PATH          => q{ /prc:process/udf:field[@name='Barcode Copies'] };
Readonly::Scalar my $DEFAULT_NUM_COPIES       => 1;

Readonly::Scalar my $PLATE_PURPOSE_PATH       => q{ /prc:process/udf:field[@name='Plate Purpose'] };
Readonly::Scalar my $CONTAINER_PURPOSE_PATH   => q{ /con:container/udf:field[@name='WTSI Container Purpose Name'] };

Readonly::Scalar my $IO_MAP_PATH              => q{ /prc:process/input-output-map};
Readonly::Scalar my $IO_MAP_PATH_ANALYTE_OUTPUT => $IO_MAP_PATH . q{[output[@output-type='Analyte' or @output-type='Pool']] };
Readonly::Scalar my $CONTAINER_PATH           => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $SAMPLE_PATH              => q{ /art:artifact/sample/@limsid };
Readonly::Scalar my $SAMPLE_URI_PATH          => q{ /art:artifact/sample[1]/@uri };
Readonly::Scalar my $CONTROL_PATH             => q{ /art:artifact/control-type };

Readonly::Scalar my $CONTAINER_LIMSID_PATH    => q{ /con:container/@limsid };
Readonly::Scalar my $SUPPLIER_CONTAINER_NAME_PATH =>
  q{ /con:container/udf:field[@name='Supplier Container Name'] };
Readonly::Scalar my $CONTAINER_NAME_PATH      => q{ /con:container/name };
Readonly::Scalar my $INPUT_ANALYTES_PATH      => q{./input/@uri};
Readonly::Scalar my $TUBE_LOCATION_PATH       => q{ /art:artifact/location/value};
Readonly::Scalar my $BAIT_LIBRARY_NAME_PATH   => q{ /smp:sample/udf:field[@name='WTSI Bait Library Name']/text()};
##use critic

Readonly::Scalar my $SIGNATURE_LENGTH         => 5;
Readonly::Scalar my $DEFAULT_CONTAINER_TYPE   => 'plate';
Readonly::Scalar my $CHILD_ERROR_SHIFT        => 8;

Readonly::Scalar my $DEFAULT_BARCODE_LOWEST   => 1_000_000;
Readonly::Scalar my $DEFAULT_BARCODE_RANGE    => 1_000_000;

Readonly::Array  my @TUBELIKE                 => qw{ tube };
Readonly::Scalar my $BARCODE_START            => 4;
Readonly::Scalar my $BARCODE_LENGTH           => 6;

has 'source_plate' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
);

has 'temp_barcode' => (
  isa => 'Bool',
  is  => 'ro',
  required => 0,
  default  => 0,
);

has 'container_type' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  default    => $DEFAULT_CONTAINER_TYPE,
);

has 'increment_purpose' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
);

has 'printer' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_printer {
  my $self = shift;

  my @nodes = $self->process_doc->findnodes($PRINTER_PATH);
  if (!@nodes) {
    croak 'Printer udf field should be defined for the process';
  }
  if (scalar @nodes > 1) {
    croak 'Multiple printer udf fields are defined for the process';
  }

  my $printer = $self->trim_value($nodes[0]->textContent);
  if (!$printer) {
    croak 'Printer name should be defined';
  }
  return $printer;
}

has 'user' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build_user {
  my $self = shift;

  my $technician_node = $self->process_doc->find(q(prc:process/technician))->[0];
  my $user = q[];

  if($technician_node) {
    $user = $technician_node->find(q(./first-name))->[0]->textContent;
    if ($user) {
      $user = substr $user, 0, 1;
      $user .= q[.];
    }
    my $sn = $technician_node->find(q(./last-name))->[0]->textContent;
    if ($sn) {
      $user .= " $sn";
    }
  }
  return $user;
}

has '_num_copies' => (
  isa        => 'Int',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__num_copies {
  my $self = shift;
  my @nodes = $self->process_doc->findnodes($NUM_COPIES_PATH);
  if (!@nodes ) {
    return $DEFAULT_NUM_COPIES ;
  }
  if (scalar @nodes > 1) {
    croak 'Multiple barcode copies udf fields are defined for the process';
  }
  return $nodes[0]->textContent || $DEFAULT_NUM_COPIES;
}

has '_plate_purpose' => (
  isa        => 'Maybe[Str]',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__plate_purpose {
  my $self = shift;
  my @nodes = $self->process_doc->findnodes($PLATE_PURPOSE_PATH);
  if (scalar @nodes > 1) {
    croak 'Multiple plate purpose udf fields are defined for the process';
  }
  if (@nodes) {
    return $self->trim_value($nodes[0]->textContent);
  }
  return;
}

has '_container' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container {
  my $self = shift;

  # Probably need to find a better way to do this...
  if ($self->temp_barcode) {
    return $self->_generate_temp_container();
  }

  my $iopath = $self->source_plate ? $IO_MAP_PATH : $IO_MAP_PATH_ANALYTE_OUTPUT;
  my @nodes = $self->process_doc->findnodes($iopath);
  if (!@nodes) {
    croak 'No analytes registered';
  }

  my $containers = {};
  foreach my $anode (@nodes) {
    my $path = $self->source_plate ? q[input] : q[output];
    ##no critic (RequireInterpolationOfMetachars)
    my $url = $anode->findvalue(q{./} . $path . q{/@uri});
    ##use critic
    my $analyte_dom = $self->fetch_and_parse($url);
    my $container_url = $analyte_dom->findvalue($CONTAINER_PATH);
    if (!$container_url) {
      croak qq[Container not defined for $url];
    }

    if (!exists $containers->{$container_url}) {
      $containers->{$container_url}->{'doc'} = $self->fetch_and_parse($container_url);
    }
    my @control_flag = $analyte_dom->findnodes($CONTROL_PATH);
    if (!@control_flag) { # Sample list should not contain controls
      my @sample_lims_ids = $analyte_dom->findnodes($SAMPLE_PATH)->to_literal_list;
      if (!@sample_lims_ids) {
        croak qq[Sample lims id not defined for $url];
      }
      push @{$containers->{$container_url}->{'samples'}}, @sample_lims_ids;
    }

    if ((any {$_ eq $self->container_type } @TUBELIKE)  && !exists $containers->{$container_url}->{'parent_barcode_with_pooling_range'}) {
      $containers->{$container_url}->{'parent_barcode_with_pooling_range'} = $self->_parent_barcode_with_pooling_range($anode);
    }
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get containers for process ] . $self->process_url;
  }

  return $containers;
}

sub _parent_barcode_with_pooling_range {
  my ($self, $analyte_node) = @_;

  my $input_analyte_dom = $self->fetch_and_parse($analyte_node->findvalue($INPUT_ANALYTES_PATH));
  my $input_container_dom = $self->fetch_and_parse($input_analyte_dom->findvalue($CONTAINER_PATH));
  my $location = $self->_get_tube_location($input_analyte_dom);

  my $full_plate_name = $input_container_dom->findvalue($CONTAINER_NAME_PATH);

  return substr($full_plate_name, $BARCODE_START, $BARCODE_LENGTH) . $self->_pooling_range($input_analyte_dom);
}

sub _get_tube_location {
  my ($self, $input_analyte_dom) = @_;

  return $input_analyte_dom->findvalue($TUBE_LOCATION_PATH);
}

sub _bait_library_name_by_sample {
  my ($self, $sample_dom) = @_;

  return $sample_dom->findvalue($BAIT_LIBRARY_NAME_PATH);
}

has '_bait_library' => (
  isa             => 'Str',
  is              => 'ro',
  writer          => '_set_bait_library',
);

sub _plexing_strategy_by_bait_library {
  my ($self, $bait_library_name) = @_;

  $self->_set_bait_library($bait_library_name);

  return $self->pooling_strategy;
}

sub _pooling_range {
  my ($self, $input_analyte_dom) = @_;

  my $destination_well_name = $self->_get_tube_location($input_analyte_dom);
  my $sample_dom = $self->fetch_and_parse($input_analyte_dom->findvalue($SAMPLE_URI_PATH));
  my $bait_library_name = $self->_bait_library_name_by_sample($sample_dom);

  return $self->_plexing_strategy_by_bait_library($bait_library_name)->get_pool_name($destination_well_name);
}


has '_plate_purpose_suffix' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  default    => sub { my @a = ('A'..'Z'); return \@a; },
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  if (!$self->temp_barcode) {
    $self->_set_container_data();
    $self->_update_container();
  }

  my $template = $self->_generate_labels();
  $self->print_labels($self->printer, $template);

  return;
};

sub _generate_labels {
  my $self = shift;

  return $self->generateLabels({
      'number'       => $self->_num_copies,
      'type'         => $self->container_type,
      'user'         => $self->user,
      'containers'   => $self->_container,
      'source_plate' => $self->source_plate,
    });
}

sub _generate_temp_container {
  my $self = shift;

  my $random_number = $self->_generate_random_number();
  my ($barcode, $num) = $self->generate_barcode($random_number);

  return {
    'tmp' => {
      'barcode' => $barcode,
      'num'     => $num,
      'purpose' => 'AssayPlate',
      'signature' => 'n/a'
    }
  }
}

sub _generate_random_number {
  return int(rand $DEFAULT_BARCODE_RANGE ) + $DEFAULT_BARCODE_LOWEST;
}

sub _set_container_data {
  my $self = shift;

  my $count = 0;
  my @urls = keys %{$self->_container};

  foreach my $container_url ( @urls ) {
    my $container = $self->_container->{$container_url};
    my $doc = $container->{'doc'};
    my $lims_id = $doc->findvalue($CONTAINER_LIMSID_PATH);
    if (!$lims_id) {
      croak qq[No limsid for $container_url];
    }
    $container->{'limsid'} = $lims_id;
    if ($self->source_plate) {  # SM first step only
      $self->_copy_supplier_container_name($doc);
    }

    my $suffix = ( scalar @urls == 1 || !$self->increment_purpose ) ?
                 q[] : $self->_plate_purpose_suffix->[$count];
    $container->{'purpose'} = $self->_copy_purpose($doc, $suffix);

    my ($barcode, $num) = $self->generate_barcode($lims_id);
    $container->{'barcode'} = $barcode;
    $container->{'num'} = $num;

    $self->_copy_barcode2container($doc, $barcode);

    $container->{'signature'} = ($container->{'samples'}) ? $self->_get_signature($container->{'samples'}) : q{};

    $count++;
  }

  return;
}

sub _get_signature {
  my ($self, $samples) = @_;
  my @uniq_samples = uniq(@{$samples});
  return wtsi_clarity::util::signature->new(sig_length => $SIGNATURE_LENGTH)->encode(sort @uniq_samples);
}

sub _update_container {
  my $self = shift;
  foreach my $container_url (keys %{$self->_container}) {
    my $doc = $self->_container->{$container_url}->{'doc'};
    $self->request->put($container_url, $doc->toString);
  }
  return;
}

sub _copy_purpose {
  my ($self, $doc, $suffix) = @_;

  my $nodes = $doc->findnodes($CONTAINER_PURPOSE_PATH);
  if ($nodes->size > 1) {
    croak 'Only one container purpose node is possible';
  }

  my $purpose;
  if ($nodes->size == 1) { # At cherry-picking stage purpose is preset
    $purpose = $nodes->pop()->textContent();
    if (!$purpose) {
      croak qq[No purpose in $CONTAINER_PURPOSE_PATH];
    }
  } else {
    $purpose = $self->_plate_purpose;
    if ($suffix) {
      $purpose .= " $suffix";
    }
    $self->add_udf_element($doc,q[WTSI Container Purpose Name], $purpose);
  }

  return $purpose;
}

sub _copy_supplier_container_name {
  my ($self, $doc) = @_;

  my @supplier_nodes = $doc->findnodes($SUPPLIER_CONTAINER_NAME_PATH);

  if (!@supplier_nodes) { # Copy only if does not exists,
                          # otherwise we might overwrite the value.
    my @nodes = $doc->findnodes($CONTAINER_NAME_PATH);
    if (!@nodes || scalar @nodes > 1) {
      croak 'Only one container name node is possible';
    }
    my $name = $nodes[0]->textContent();
    if ($name) {
      $name = $self->trim_value($name);
    }
    if (!$name) {
      croak 'Container name undefined';
    }
    $self->add_udf_element($doc, 'Supplier Container Name', $name);
  }
  return;
}

sub _copy_barcode2container {
  my ($self, $doc, $barcode) = @_;

  my $nodes = $doc->findnodes($CONTAINER_NAME_PATH);
  if ($nodes->size == 0 || $nodes->size > 1) {
    croak 'Multiple or none container name nodes';
  }
  $self->update_text($nodes->pop(), $barcode);
  return;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::label_creator

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::label_creator->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a barcode and sets it for the containers (if required), formats the label  and prints it.

=head1 SUBROUTINES/METHODS

=head2 process_url

  Clarity process url, required.

=head2 printer

  Printer name (as known to the print service), an optional attribute.

=head2 user

  User name as it appears on a label, an optional attribute.

=head2 source_plate

  A boolean flag indicating whether source or target plates have to be considered
  false by default, meaning that target plates should be considered bt default, an optional attribute.

=head2 increment_purpose

  A boolean flag indicating whether container purpose has to be incremented in
  case of multiple outputs, defaults to false, an optional attribute.

=head2 run

  Callback for the label_creator action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=item Readonly

=item DateTime

=item List::MoreUtils

=item wtsi_clarity::util::barcode

=item wtsi_clarity::util::signature

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::util::print

=item wtsi_clarity::util::label

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
