#! /usr/bin/env perl

package sample_udf_updater;

use strict;
use warnings;
use FindBin qw($Bin);
use lib ( -d "$Bin/../lib/perl5" ? "$Bin/../lib/perl5" : "$Bin/../lib" );

use Moose;
use Carp;
use Readonly;
use XML::LibXML;
use List::MoreUtils qw/uniq/;

use wtsi_clarity::clarity::process;

use Data::Dumper;

with qw/wtsi_clarity::util::configurable
        wtsi_clarity::util::roles::clarity_request
        wtsi_clarity::util::clarity_elements/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_URI_PATH  => q{/art:details/art:artifact/sample/@uri};
## use critic
Readonly::Scalar my $SAMPLE_PATH      => q{/smp:details/smp:sample};

has 'process_url'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'process_doc'  => (
  isa             => 'wtsi_clarity::clarity::process',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
  handles         => {'findnodes' => 'findnodes'},
);
sub _build_process_doc {
  my ($self) = @_;
  my $xml = $self->fetch_and_parse($self->process_url);
  return wtsi_clarity::clarity::process->new(xml => $xml, parent => $self);
}

has 'udf_name'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'udf_value'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has '_input_artifacts' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts {
  my $self = shift;

  return $self->process_doc->input_artifacts;
}

has '_samples' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__samples {
  my $self = shift;

  my @sample_uri_node_list = $self->_input_artifacts->findnodes($SAMPLE_URI_PATH)->get_nodelist();
  my @sample_uris = map { $_->getValue } @sample_uri_node_list;

  # print Dumper @sample_uris;

  return $self->request->batch_retrieve('samples', \@sample_uris);
}

sub _update_samples_with_udfs {
  my $self = shift;

  my @sample_node_list = $self->_samples->findnodes($SAMPLE_PATH)->get_nodelist();

  foreach my $sample (@sample_node_list) {
    $self->_add_udf_to_sample($sample);
  }
}

sub _add_udf_to_sample {
  my ($self, $sample_xml) = @_;

  my $new_udf_element = XML::LibXML::Element->new('field');
  $new_udf_element->setNamespace("http://genologics.com/ri/userdefined", "udf");
  $new_udf_element->setAttribute('type', 'String');
  $new_udf_element->setAttribute('name', $self->udf_name);
  $new_udf_element->appendTextNode($self->udf_value);
  $sample_xml->addChild($new_udf_element);
}

sub _save_updated_samples {
  my ($self) = @_;

  $self->request->batch_update('samples', $self->_samples);
}

sub run {
  my $self = shift;

  $self->_update_samples_with_udfs();

  $self->_save_updated_samples();
}

my $updater = sample_udf_updater->new_with_options();
$updater->run();

1;

__END__

=head1 NAME

wtsi_clarity::script::batch_update_samples_in_process_with_udfs

=head1 SYNOPSIS

  my $sample_updater = wtsi_clarity::script::batch_update_samples_in_process_with_udfs->new(
    process_url     => $base_uri . '/processes/122-21977',
    udfs_to_update  => { 
      'name1'  => 'value1',
      'name2'  => 'value2',
    }
  );

=head1 DESCRIPTION

  This script can add UDF fields to the samples of a process.

=head2 run

  Execute the sample update in the given process with the specified UDF field and value.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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
