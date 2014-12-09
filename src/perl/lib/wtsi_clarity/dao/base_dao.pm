package wtsi_clarity::dao::base_dao;

use Moose::Role;
use MooseX::Storage;
use MooseX::Aliases;
use XML::LibXML;

use wtsi_clarity::util::artifact_reader;

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

our $VERSION = '0.0';

has 'resource_type' => (
  isa         => 'Str',
  is          => 'ro',
  required    => 0,
);

has 'lims_id' => (
  isa         => 'Str',
  is          => 'ro',
  required    => 1,
  alias       => 'id',
);

has '_artifact_xml' => (
  traits          => [ 'DoNotSerialize' ],
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
  handles         => {'findvalue' => 'findvalue'},
);
sub _build__artifact_xml {
  my $self = shift;

  my $artifact_reader = wtsi_clarity::util::artifact_reader->new(
    resource_type => $self->resource_type,
    lims_id       => $self->lims_id);
  return $artifact_reader->get_xml;
}

has 'attributes' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
);

sub BUILD {
  my $self = shift;

  foreach my $attribute_name ( keys $self->attributes ) {
    $self->meta->add_attribute($attribute_name => (
      isa             => 'Str',
      is              => 'rw',
      required        => 0,
      lazy_build      => 1,
    ));

    my $build_method = '_build_' . $attribute_name;
    ##no critic (TestingAndDebugging::ProhibitNoStrict TestingAndDebugging::ProhibitNoWarnings)
    no strict 'refs';
    no warnings 'redefine';
    $self->meta->add_method($build_method => sub {
        my $self = shift;
        return $self->findvalue($self->attributes->{$attribute_name});
    });
  }

  return;
}

sub init {
  my $self = shift;

  foreach my $attribute_name ( keys %{$self->attributes} ) {
    $self->$attribute_name;
  }

  return;
}

sub to_message {
  my $self = shift;

  $self->init;
  return $self->freeze();
}

1;

__END__

=head1 NAME

wtsi_clarity::dao::base_dao

=head1 SYNOPSIS
  with wtsi_clarity::dao::base_dao;

=head1 DESCRIPTION

 The common attributes and methods related to data objects.
 Their data coming from the various artifact (XML file).

=head1 SUBROUTINES/METHODS

=head2 to_message
  Convert the sample data to a message format which will be published onto a RabbitMQ message bus.

=head2 init
  Initialize the data object with its data.

=head2 BUILD
  Adds the attributes of the resource and their value's builder dynamically.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL
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
