package wtsi_clarity::util::artifact_reader;

use Moose;
use XML::LibXML;

with qw/wtsi_clarity::util::configurable MooseX::Getopt wtsi_clarity::util::roles::clarity_request/;

our $VERSION = '0.0';

has 'lims_id' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'resource_type' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_artifact_url' => (
  isa => 'Str',
  is  => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build__artifact_url {
  my $self = shift;
  return join q{/}, $self->config->clarity_api->{'base_uri'}, $self->resource_type, $self->lims_id;
}

has 'get_xml' => (
  isa             => 'XML::LibXML::Document',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);
sub _build_get_xml {
  my $self = shift;

  return $self->fetch_and_parse($self->_artifact_url);
}

1;

__END__

=head1 NAME
wtsi_clarity::util::artifact_reader
=head1 SYNOPSIS
  my $lims_id = '1234';
  my $resource_type = 'sample';
  my $artifact_reader = wtsi_clarity::util::artifact_reader->new(
    resource_type => $resource_type,
    lims_id       => $lims_id)
  $artifact_reader->get_xml();
=head1 DESCRIPTION
 Reading the specific required resource and returns it as an XML document.
 Required parameters are the resource type and its lims id.
=head1 SUBROUTINES/METHODS
=head2 get_xml
  Returns the required artifact XML.
=head1 CONFIGURATION AND ENVIRONMENT
=head1 DEPENDENCIES
=over
=item Moose
=item XML::LibXML
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