package wtsi_clarity::epp::sm::create_label;

use Moose;
use English qw(-no_match_vars);
use Carp;
use Readonly;
use JSON;
use DateTime;

use wtsi_clarity::util::barcode;
use wtsi_clarity::util::signature;
extends 'wtsi_clarity::epp';

#########################
# TODO
# in case of multiple output containers
# increment the purpose (append A, B, etc)
#
# have short project name on the label?
#
# have plate purpose on the label
#
# have date on the label
#

our $VERSION = '0.0';

Readonly::Scalar my $PRINTER_PATH         => q{ /prc:process/udf:field[contains(@name, 'Printer')] };
Readonly::Scalar my $NUM_COPIES_PATH      => q{ /prc:process/udf:field[@name='Barcode Copies'] };
Readonly::Scalar my $DEFAULT_NUM_COPIES   => 1;

Readonly::Scalar my $PLATE_PURPOSE_PATH   => q{ /prc:process/udf:field[@name='Plate Purpose'] };
Readonly::Scalar my $CONTAINER_PURPOSE_PATH   => q{ /prc:process/udf:field[@name='WTSI Container Purpose Name'] };

Readonly::Scalar my $IO_MAP_PATH          => q{ /prc:process/input-output-map};
Readonly::Scalar my $CONTAINER_PATH       => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $SAMPLE_PATH          => q{ /art:artifact/sample/@limsid };
Readonly::Scalar my $DEFAULT_SM_BARCODE_PREFIX   => 'SM';
Readonly::Scalar my $BARCODE_PREFIX_PATH         =>
  q{ /prc:process/udf:field(@name, 'Barcode Prefix') };

Readonly::Scalar my $CONTAINER_LIMSID_PATH  => q{ /con:container/@limsid };
Readonly::Scalar my $SUPPLIER_CONTAINER_NAME_PATH =>
  q{ /con:container/udf:field/[has(name = 'Supplier Container Name')] };
Readonly::Scalar my $CONTAINER_NAME_PATH  => q{ /con:container/name };

has 'source_plate' => (
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
  my $printer =  $nodes[0]->textContent;
  if ($printer) {
    $printer =~ s/^\s+|\s+$//g;
  }
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
    my $last = $technician_node->find(q(./last-name))->[0]->textContent;
    if ($last) {
      $user .= " $last";
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
  my $output;
  my $printer = $self->printer;
  my $p;
  my $cmd = qq[curl -H 'Accept: application/json' -H 'Content-Type: application/json' $url];
  eval {
    $output = `$cmd`;
  };
  if ($CHILD_ERROR) {
    croak qq[Failed to get info about a printer $printer from $url,\n $output\n ERROR: ] . $CHILD_ERROR >> 8;
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
    my $plate_purpose = $nodes[0]->textContent;
    if ($plate_purpose) {
      $plate_purpose =~ s/^\s+|\s+$//g;
    }
    return $plate_purpose;
  }
  return;
}

#has '_barcode_prefix' {
#  isa        => 'Str',
#  is         => 'ro',
#  required   => 0,
#  lazy_build => 1,  
#};
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
    my $url = $anode->findvalue(q{./} . $path . q{/@uri});

    my $analyte_dom = $self->fetch_and_parse($url);
    my $container_url = $analyte_dom->findvalue($CONTAINER_PATH);
    if (!$container_url) {
      croak qq[Container not defined for $url];
    }

    my $sample_lims_id = $analyte_dom->findvalue($SAMPLE_PATH);
    if (!$sample_lims_id) {
      croak qq[Sample lims id not defined for $url];
    }
    if (!exists $containers->{$container_url}) {
      $containers->{$container_url}->{'doc'} = $self->fetch_and_parse($container_url); 
    }
    push @{$containers->{$container_url}->{'samples'}}, $sample_lims_id; 
  }
  if (scalar keys %{$containers} == 0) {
    croak q[Failed to get containers for process ] . $self->process_url;
  }
  return $containers;
}

has '_date' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  default    => { return DateTime->now()->strftime('%a %b %d %T %Y') },
);

sub _generate_barcode {
  my ($container_id) = @_;
  my (@bcd)       = split(/\-/, $container_id);
  return Calculatebarcode($bcd[0],$bcd[1],'1');
}

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  $self->_set_container_data();
  $self->_update_container();
  $self->_format_label();
  my $template = $self->_generate_label();
  $self->_print_label($template);
  return 1;
};

sub _set_container_data {
  my $self = shift;

  foreach my $container_url (keys %{$self->containers}) {
    my $container = $self->containers->{$container_url};
    my $doc = $container->{'doc'};
    my $lims_id = $doc->findvalue($CONTAINER_LIMSID_PATH);
    if (!$lims_id) {
      croak qq[No limsid for $container_url];
    }
    $container->{'limsid'} = $lims_id;

    if (!$self->source_plate) {  # SM first step only
      $self->_copy_supplier_container_name($doc);
    }
    $self->_copy_purpose($doc);

    my ($barcode, $num) = _generate_barcode($lims_id);
    $container->{'barcode'} = $barcode;
    $container->{'num'} = $num;

    $self->_copy_barcode2container($doc, $barcode);

    my $container_type = $doc->find(q(/con:container/type))->[0]->findvalue(q(@name));
    if (!$container_type) {
      croak qq[Container type not defined for $container_url];
    }
    $container->{'type'} = $container_type =~ /plate/smx ? 'plate' : 'tube';
    $container->{'signature'} =
      wtsi_clarity::util::signature->new()->encode(sort @{$container->{'samples'}});
  }
  return;
}

sub _update_container {
  my $self = shift;
  foreach my $container_url (keys %{$self->containers}) {
    my $doc = $self->containers->{$container_url}->{'doc'};
    $self->request->put($container_url, $doc->toString);
  }
  return;
}

sub _format_label {
  my $self = shift;

  foreach my $container_url (keys %{$self->containers}) {
    my $c = $self->containers->{$container_url};
    my $type = $c->{'type'};
    if ($type eq 'plate') {
      $c->{'label'} = {'template'  => 'tube_rack',
                       'tube_rack' => { 'ean13'      => $c->{'barcode'},
                                        'sanger'     => $c->{'lims_id'},
                                        'label_text' =>
                      {'role' => $self->user, 'text5' => $c->{'num'}, 'text6' => $c->{'signature'},}
                                      }};
      $c->{'label'} = {'template'  => 'tube_and_tube',
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
  my $h = {};
  $h->{'label_printer'}->{'header_text'} =
    {'header_text1' => "header by $user",'header_text2' => $self->_date,};
  $h->{'label_printer'}->{'footer_text'} =
    {'footer_text1' => "footer by $user",'footer_text2' => $self->_date,};

  my @labels = ();
  foreach my $container_url (keys %{$self->containers}) {
    my $count = 0;
    while ($count < $self->num_copies) {
      push @labels, $self->containers->{$container_url}->{'label'};
      $count++;
    }
  }
  $h->{'label_printer'}->{'labels'} = \@labels;

  return $h;
}

sub _print_label {
  my ($self, $template) = @_;

  my $cmd = qq(curl -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d);
  $cmd .= q[ '] . encode_json($template)  . q[' ] . $self->_printer_url;
  my $output = `$cmd`;
  if ($CHILD_ERROR) {
    croak qq[Barcode printing failed\n $output \n: ] . $CHILD_ERROR >> 8;
  }
  return;
}

sub _copy_purpose {
  my ($self, $doc) = @_;
  #copy $self->plate_purpose to 'WTSI Container Purpose Name' udf of the container
  my $nodes = $doc->findnodes($CONTAINER_PURPOSE_PATH);
  if ($nodes->size > 1) {
    croak 'Only one container purpose udf node is possible';
  }

  if ($nodes->size() == 0) {
    _create_udf_node($doc,q[WTSI Container Purpose Name], $self->_plate_purpose);
  } else {
    _update_udf_node($nodes, $self->_plate_purpose);
  }
  return;
}

sub _create_node {
  my ($doc, $udf_name, $value) = @_;

  my $node = XML::LibXML::Element->new('udf:field');
  $node->setAttribute('name', $udf_name);
  $node->appendTextNode($value);
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

  if (!@supplier_nodes) {
    my @nodes = $doc->findnodes($CONTAINER_NAME_PATH);
    if (!@nodes || scalar @nodes > 1) {
      croak 'Only one container name node is possible';
    }
    my $name = $nodes[0]->getData();
    if ($name) {
      $name =~ s/^\s+|\s+$//g;
    }
    _create_node($doc, 'Supplier Container Name', $name);
  }
  return;
}

sub _copy_barcode2container {
  my ($self, $doc, $barcode) = @_;

  my @nodes = $doc->findnodes($CONTAINER_NAME_PATH);
  if (!@nodes || scalar @nodes > 1) {
    croak 'Only one container name node is possible';
  }
  my $node = $nodes[0];
  if ($node->hasChildNodes()) {
    $node->firstChild()->setData($barcode);
  } else {
    croak q[No child node];
  }
  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::create_label

=head1 SYNOPSIS
  
  wtsi_clarity::epp:sm::create_label->new(process_url => 'http://my.com/processes/3345')->run();
  
=head1 DESCRIPTION

  Creates a barcode and sets it for the containers (if required), formats the label  and prints it.

=head1 SUBROUTINES/METHODS

=head2 process_url - Clarity process url, required.

=head2 printer - printer name (as known to the print service), an optional attribute.

=head2 source_plate - a boolean flag indicating whether source or target plates have to be considered
  false by default, meaning that target plates should be considered bt default, an optional attribute.

=head2 run - callback for the create_label action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

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
