package wtsi_clarity::mq::dao::sample_dao;

use Moose;
use Readonly;
use XML::LibXML;
use MooseX::Storage;
use wtsi_clarity::util::artifact_reader;

Readonly::Scalar my $SAMPLE_UUID_PATH => q{/smp:sample/name};

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

our $VERSION = '0.0';

has 'lims_id' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_artifact_xml' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__artifact_xml {
  my $self = shift;

  my $artifact_reader = wtsi_clarity::util::artifact_reader->new(
    resource_type => 'sample',
    lims_id       => $self->lims_id);
  return $artifact_reader->get_xml;
}

has 'uuid' => (
  isa             => 'Str',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build_uuid {
  my $self = shift;

  my $sample_limsid = $self->_artifact_xml->findvalue($SAMPLE_UUID_PATH);

  return $sample_limsid;
}

sub to_message {
  my $self = shift;

  return $self->freeze();
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::dao::sample_dao

=head1 SYNOPSIS

  my $sample_dao = wtsi_clarity::mq::dao::sample_dao->new(lims_id => "1234");
  $sample_dao->to_message();

=head1 DESCRIPTION

 A data object representing a sample.
 Its data coming from the sample artifact (XML file).

=head1 SUBROUTINES/METHODS

=head2 to_message

  Convert the sample data to a message format which will be published onto a RabbitMQ message bus.

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
