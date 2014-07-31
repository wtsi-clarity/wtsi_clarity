package wtsi_clarity::util::batch;

use Moose::Role;
use Carp;
use XML::LibXML;
use Readonly;

requires 'request';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Array my @BATCHABLES => qw/artifacts containers files samples/;
## use critic

our $VERSION = '0.0';

sub batch_retrieve {
  my ($self, $batchable, $links) = @_;

  $self->_check_batchable($batchable);

  # Build request
  my $links_elem = XML::LibXML::Element->new('links');
  $links_elem->setNamespace('http://genologics.com/ri', 'ri');

  foreach my $link (@{$links}) {
    my $link_elem = XML::LibXML::Element->new('link');
    $link_elem->setAttribute('uri', $link);
    $link_elem->setAttribute('rel', $batchable);

    $links_elem->addChild($link_elem);
  }

  return $self->_send_request('retrieve', $batchable, $links_elem);
}

sub batch_update {
  my ($self, $batchable, $xml) = @_;
  $self->_check_batchable($batchable);
  return $self->_send_request('update', $batchable, $xml);
}

sub _check_batchable {
  my ($self, $batchable) = @_;

  if (!($batchable ~~ @BATCHABLES)) {
    croak "$batchable cant not be retrieved with a batch request";
  }

  return 1;
}

sub _send_request {
  my ($self, $type, $batchable, $payload) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . "/$batchable/batch/$type";

  my $response = $self->request->post($uri, $payload->toString());

  return $self->xml_parser->parse_string($response);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::batch

=head1 SYNOPSIS

  with 'wtsi_clarity::util::batch';

  my $artifacts = $self->batch_retrieve('artifacts', $artifact_uris);

=head1 DESCRIPTION

  Moose role for matching requests in batches

=head1 SUBROUTINES/METHODS

=head2 batch_retrieve
  Takes the name of the batchable and a array reference of links.

  Batchable can only be one of artifacts, containers, files, samples

  Builds a batch request from the links and returns the response xml

  Note, the elements don't necessarily come back in the order requested

=head2 batch_update
  takes the name of the batchable and the xml payload (as an XML::Element, not as a string) as
  arguments. Creates a batch POST and returns the response XML

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

=item XML::LibXML

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
