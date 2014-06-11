package wtsi_clarity::util::batch;

use Moose::Role;
use Carp;
use Readonly;
use XML::LibXML;

our $VERSION = '0.0';

requires qw / request config /;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash my %RESOURCE2RETRIEVEURL => (
  'artifacts' => '/artifacts/batch/retrieve',
  'containers' => '/containers/batch/retrieve',
);
## use critic

sub batch_retrieve {
  my ($self, $resource, $links) = @_;

  if (!exists $RESOURCE2RETRIEVEURL{$resource}) {
    croak qq / Batch retrival not available for resource $resource /;
  }

  if (ref $links ne "ARRAY") {
    croak qq / Links must be passed in as an array /;
  }

  my $linksNode = XML::LibXML::Element->new("links");
  $linksNode->setNamespace("http://genologics.com/ri", "ri");

  foreach my $link (@{$links}) {
    my $childNode = XML::LibXML::Element->new("link");
    $childNode->setAttribute("uri", $link);
    $childNode->setAttribute("rel", $resource);

    $linksNode->appendChild($childNode);
  }

  my $url = $self->config->clarity_api->{'base_uri'} . $RESOURCE2RETRIEVEURL{$resource};

  my $response = $self->request->post($url, $linksNode->toString());

  return $self->xml_parser->parse_string($response);

}

1;
