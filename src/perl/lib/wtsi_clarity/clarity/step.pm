package wtsi_clarity::clarity::step;

use Moose;
use Readonly;
use Carp;
use URI::Escape;
use wtsi_clarity::util::request;
use wtsi_clarity::clarity::step::programstatus;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PLACEMENTS_URI_PATH      => q( /stp:step/placements/@uri );
Readonly::Scalar my $SELECTED_CONTAINERS_PATH => q( /stp:placements/selected-containers/container/@uri );
Readonly::Scalar my $PLACEMENT_URIS           => q( /con:details/con:container/placement/@uri );
## use critic

has 'programstatus' => (
  is      => 'ro',
  isa     => 'wtsi_clarity::clarity::step::programstatus',
  lazy    => 1,
  builder => '_build_programstatus',
  handles => [qw/send_warning send_error send_ok/],
);
sub _build_programstatus {
  my $self = shift;
  return wtsi_clarity::clarity::step::programstatus->new(step => $self);
}

has 'parent' => (
  is => 'ro',
  isa => 'HasRequestAndConfig',
  required => 1,
  init_arg => 'parent',
);

has 'request' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::request',
  required => 0,
  init_arg => undef,
  lazy_build => 1,
);
sub _build_request {
  my $self = shift;
  return $self->parent->request;
}

has 'xml' => (
  is => 'rw',
  isa => 'XML::LibXML::Document',
  required => 1,
  init_arg => 'xml',
  handles => {
    find               => 'find',
    findvalue          => 'findvalue',
    findnodes          => 'findnodes',
    toString           => 'toString',
    getDocumentElement => 'getDocumentElement',
    createElementNS    => 'createElementNS',
  },
);

has '_placement_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);
sub _build__placement_doc {
  my $self = shift;

  my $placement_uri = $self->xml->findvalue($PLACEMENTS_URI_PATH);
  return $self->parent->fetch_and_parse($placement_uri);
}

has 'output_containers' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);

sub _build_output_containers {
  my $self = shift;
  my @output_container_uris = $self->_placement_doc->findnodes($SELECTED_CONTAINERS_PATH)->to_literal_list;
  return $self->request->batch_retrieve('containers', \@output_container_uris);
}

sub _output_containers_uri {
  my $self = shift;

  my @uris = $self->_placement_doc->findnodes($SELECTED_CONTAINERS_PATH)->to_literal_list;

  return \@uris;
}

has 'output_container_count' => (
  is => 'ro',
  isa => 'Int',
  lazy_build => 1,
);
sub _build_output_container_count {
  my $self = shift;

  return scalar @{$self->_output_containers_uri};
}

has 'output_artifacts' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
  lazy_build => 1,
);
sub _build_output_artifacts {
  my $self = shift;

  my @uris = $self->output_containers->findnodes($PLACEMENT_URIS)->to_literal_list;
  my $artifacts = $self->request->batch_retrieve('artifacts', \@uris);

  return $artifacts;
}

1;

__END__

=head1 NAME

wtsi_clarity::clarity::step

=head1 SYNOPSIS

  use wtsi_clarity::clarity::step;
  wtsi_clarity::clarity::step->new(parent => $self, xml => $xml_doc);

=head1 DESCRIPTION

  Class to wrap a step XML from Clarity with some convinient attributes and methods

=head1 SUBROUTINES/METHODS

=head2 output_container_count
  Returns the number of the output containers.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item Carp

=item List::Util

=item List::MoreUtils

=item URI::Escape

=item wtsi_clarity::util::types

=item wtsi_clarity::util::request

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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