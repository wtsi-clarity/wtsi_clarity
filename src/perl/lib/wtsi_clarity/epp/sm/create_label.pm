package wtsi_clarity::epp::sm::create_label;

use Moose;
use English qw(-no_match_vars);
use Carp;
use Readonly;
use JSON;
use DateTime;
use namespace::autoclean;

use wtsi_clarity::util::barcode qw/calculateBarcode/;
use wtsi_clarity::util::signature;
extends 'wtsi_clarity::epp';

#########################
# TODO
#
# have short project name on the label?
#

our $VERSION = '0.0';

##no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PRINTER_PATH         => q{ /prc:process/udf:field[contains(@name, 'Printer')] };
Readonly::Scalar my $NUM_COPIES_PATH      => q{ /prc:process/udf:field[@name='Barcode Copies'] };
Readonly::Scalar my $DEFAULT_NUM_COPIES   => 1;

Readonly::Scalar my $PLATE_PURPOSE_PATH   => q{ /prc:process/udf:field[@name='Plate Purpose'] };
Readonly::Scalar my $CONTAINER_PURPOSE_PATH   => q{ /con:container/udf:field[@name='WTSI Container Purpose Name'] };

Readonly::Scalar my $IO_MAP_PATH          => q{ /prc:process/input-output-map};
Readonly::Scalar my $CONTAINER_PATH       => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $SAMPLE_PATH          => q{ /art:artifact/sample/@limsid };
Readonly::Scalar my $CONTROL_PATH         => q{ /art:artifact/control-type };
Readonly::Scalar my $DEFAULT_BARCODE_PREFIX   => 'SM';
Readonly::Scalar my $BARCODE_PREFIX_PATH         =>
  q{ /prc:process/udf:field(@name, 'Barcode Prefix') };

Readonly::Scalar my $CONTAINER_LIMSID_PATH  => q{ /con:container/@limsid };
Readonly::Scalar my $SUPPLIER_CONTAINER_NAME_PATH =>
  q{ /con:container/udf:field[@name='Supplier Container Name'] };
Readonly::Scalar my $CONTAINER_NAME_PATH  => q{ /con:container/name };
##use critic

Readonly::Scalar my  $SIGNATURE_LENGTH => 5;
Readonly::Scalar my  $USER_NAME_LENGTH => 12;
Readonly::Scalar my  $DEFAULT_CONTAINER_TYPE => 'plate';
Readonly::Scalar my  $CHILD_ERROR_SHIFT => 8;

has 'source_plate' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
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

  my $printer = _trim_value($nodes[0]->textContent);
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

has '_printer_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__printer_url {
  my $self = shift;

  my $print_service = $self->config->printing->{'service_url'};
  if (!$print_service) {
    croak q[service_url entry should be defined in the printing section of the configuration file];
  }
  my $url =  "$print_service/label_printers/page\=1";
  my $printer = $self->printer;
  my $p;
  my $cmd = qq[curl -H 'Accept: application/json' -H 'Content-Type: application/json' $url];
  ##no critic (ProhibitBacktickOperators)
  my $output = `$cmd`;
  ##use critic
  if ($CHILD_ERROR) {
    croak qq[Failed to get info about a printer $printer from $url,\n $output\n ERROR: ] . $CHILD_ERROR >> $CHILD_ERROR_SHIFT;
  }

  my $text = decode_json($output);
  foreach my $t ( @{$text->{'label_printers'}} ){
    if ($t->{'name'} && $t->{'name'} eq $printer){
      if (!$t->{'uuid'}) {
        croak qq[No uuid for printer $printer]
      }
      $p = join q[/], $print_service, $t->{'uuid'};
    }
  }
  if (!$p) {
    croak qq[Failed to get printer $printer details from $url]
  }
  return $p;
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
    return _trim_value($nodes[0]->textContent);
  }
  return;
}

has '_barcode_prefix' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  default    => $DEFAULT_BARCODE_PREFIX,
);
#sub _build__barcode_prefix {
#  my $self = shift;
#  my @nodes = $self->process_doc->findnodes($BARCODE_PREFIX_PATH);
#  if (scalar @nodes > 1) {
#    croak 'Multiple barcode prefix udf fields are defined for the process';
#  }
#  my $barcode_prefix;
#  if (@nodes) {
#    $barcode_prefix = $nodes[0]->textContent;
#    if ($barcode_prefix) {
#      $barcode_prefix =~ s/^\s+|\s+$//g;
#    }
#  }
#  return $barcode_prefix || $DEFAULT_SM_BARCODE_PREFIX;
#}

has '_container' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__container {
  my $self = shift;

  my @nodes = $self->process_doc->findnodes($IO_MAP_PATH);
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
      my $sample_lims_id = $analyte_dom->findvalue($SAMPLE_PATH);
      if (!$sample_lims_id) {
        croak qq[Sample lims id not defined for $url];
      }
      push @{$containers->{$container_url}->{'samples'}}, $sample_lims_id;
    }
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get containers for process ] . $self->process_url;
  }
  return $containers;
}

has '_date' => (
  isa        => 'DateTime',
  is         => 'ro',
  required   => 0,
  default    => sub { return DateTime->now(); },
);

has '_plate_purpose_suffix' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  default    => sub { my @a = ('A'..'Z'); return \@a; },
);

sub _generate_barcode {
  my ($self, $container_id) = @_;
  if (!$container_id) {
    croak 'Container id is not given';
  }
  $container_id =~ s/-//smxg;
  return calculateBarcode($self->_barcode_prefix, $container_id);
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  $self->_set_container_data();
  $self->_update_container();
  $self->_format_label();
  my $template = $self->_generate_label();
  $self->_print_label($template);
  return;
};

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

    my ($barcode, $num) = $self->_generate_barcode($lims_id);
    $container->{'barcode'} = $barcode;
    $container->{'num'} = $num;

    $self->_copy_barcode2container($doc, $barcode);

    $container->{'signature'} =
      wtsi_clarity::util::signature->new(sig_length => $SIGNATURE_LENGTH)->encode(sort @{$container->{'samples'}});

    $count++;
  }

  return;
}

sub _update_container {
  my $self = shift;
  foreach my $container_url (keys %{$self->_container}) {
    my $doc = $self->_container->{$container_url}->{'doc'};
    $self->request->put($container_url, $doc->toString);
  }
  return;
}

sub _format_label {
  my $self = shift;

  my $type = $self->container_type;
  foreach my $container_url (keys %{$self->_container}) {
    my $c = $self->_container->{$container_url};

    my $date = $self->_date->strftime('%d-%b-%Y');
    my $user = $self->source_plate ? q[] : $self->user; #no user for sample management stock plates
    if ($user && length $user > $USER_NAME_LENGTH) {
      $user = substr $user, 0, $USER_NAME_LENGTH;
    }
    if ($type eq 'plate') {
      $c->{'label'} = {'template'  => 'plate',
                       'plate' => { 'ean13'      => $c->{'barcode'},
                                    'sanger' => join(q[ ], $date, $user),
                                    'label_text' =>
                      {'role' => $c->{'purpose'}, 'text5' => $c->{'num'}, 'text6' => $c->{'signature'}}
                                      }};
    } elsif ($type eq 'tube') { #tube labels have not been tested yet
      $c->{'label'} = {'template'  => 'tube',
                       'tube'      => { 'ean13'      => $c->{'barcode'},
                                        'sanger'     => $c->{'lims_id'},
                                        'label_text' => {'role' => $self->user,},
                                      }};
    } else {
      croak qq[Unknown container type $type, known types: tube, plate];
    }
  }
  return;
}

sub _generate_label {
  my $self = shift;
  my $user = $self->user;
  my $date = $self->_date->strftime('%a %b %d %T %Y');
  my $h = {};
  $h->{'label_printer'}->{'header_text'} =
    {'header_text1' => "header by $user",'header_text2' => $date,};
  $h->{'label_printer'}->{'footer_text'} =
    {'footer_text1' => "footer by $user",'footer_text2' => $date,};

  my @labels = ();
  foreach my $container_url (keys %{$self->_container}) {
    my $count = 0;
    while ($count < $self->_num_copies) {
      push @labels, $self->_container->{$container_url}->{'label'};
      $count++;
    }
  }
  $h->{'label_printer'}->{'labels'} = \@labels;

  return $h;
}

sub _print_label {
  my ($self, $template) = @_;

  ##no critic (ProhibitInterpolationOfLiterals)
  my $cmd = qq(curl -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d);
  ##use critic
  $cmd .= q[ '] . encode_json($template)  . q[' ] . $self->_printer_url;

  ##no critic (ProhibitBacktickOperators)
  my $output = `$cmd`;
  ##use critic
  if ($CHILD_ERROR) {
    croak qq[Barcode printing failed\n $output \n: ] . $CHILD_ERROR >> $CHILD_ERROR_SHIFT;
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
    _create_node($doc,q[WTSI Container Purpose Name], $purpose);
  }

  return $purpose;
}

sub _create_node {
  my ($doc, $udf_name, $value) = @_;

  my $node = $doc->createElement('udf:field');
  $node->setAttribute('name', $udf_name);
  my $text = $doc->createTextNode($value);
  $node->appendChild($text);
  $doc->documentElement()->appendChild($node);
  return;
}

sub _update_node {
  my ($nodes, $value) = @_;

  my $node = $nodes->pop();
  if ($node->hasChildNodes()) {
    $node->firstChild()->setData($value);
  } else {
    $node->addChild($node->createTextNode($value));
  }
  return;
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
      $name = _trim_value($name);
    }
    if (!$name) {
      croak 'Container name undefined';
    }
    _create_node($doc, 'Supplier Container Name', $name);
  }
  return;
}

sub _copy_barcode2container {
  my ($self, $doc, $barcode) = @_;

  my $nodes = $doc->findnodes($CONTAINER_NAME_PATH);
  if ($nodes->size == 0 || $nodes->size > 1) {
    croak 'Multiple or none container name nodes';
  }
  _update_node($nodes, $barcode);
  return;
}

sub _trim_value {
  my $v = shift;
  if ($v) {
    $v =~ s/^\s+|\s+$//smxg;
  }
  return $v;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::create_label

=head1 SYNOPSIS
  
  wtsi_clarity::epp:sm::create_label->new(process_url => 'http://my.com/processes/3345')->run();
  
=head1 DESCRIPTION

  Creates a barcode and sets it for the containers (if required), formats the label  and prints it.

=head1 SUBROUTINES/METHODS

=head2 run

  Method executing the epp callback

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

=head2 run - callback for the create_label action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=item English

=item Readonly

=item JSON

=item DateTime

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
