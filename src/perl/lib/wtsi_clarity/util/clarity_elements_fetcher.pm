package wtsi_clarity::util::clarity_elements_fetcher;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use DateTime;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

has '_targets' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy => 1,
  default => sub { {} },
);

override 'run' => sub {
  my $self= shift;
  super();

  $self->_fetch_and_update_targets($self->process_doc);

  $self->_put_changes();

  return 1;
};

# Finding the targets....

sub fetch_targets_hash {
  # start the recursive search for targets.
  my ($self, @list_of_xpath) = @_;

  my @output =  $self->_find_xml_recursively($self->process_doc->getDocumentElement(), @list_of_xpath);

  my %hash =  map { $_->getValue() => $self->fetch_and_parse($_->value) } @output;
  return \%hash;
}

sub _fetch_targets_hash {
  my ($self) = @_;
  my $hash = $self->fetch_targets_hash($self->_get_targets_uri());

  return $hash;
}

sub _find_xml_recursively {
  my ($self,$xml, @xpaths) = @_;
  my $first = shift @xpaths;

  my @nodeList = $xml->findnodes($first)->get_nodelist();
  my @found_targets = ();

  if (scalar @xpaths != 0)
  {
    foreach my $element (@nodeList)
    {
      my $partial_xml = $self->fetch_and_parse($element->getValue());
      my @new_targets   = $self->_find_xml_recursively($partial_xml->getDocumentElement() , @xpaths);
      push @found_targets, @new_targets;
    }
    return @found_targets;
  }
  else
  {
    return @nodeList;
  }
}

# core methods ....

sub _fetch_and_update_targets {
  my ($self, $doc, $data) = @_;

  my $targets = $self->_fetch_targets_hash();

  while (my ($targetURI, $targetDoc) = each %{$targets} ) {
    if (!exists $self->_targets->{$targetURI}) {
      $self->_targets->{$targetURI} =
          $self->_update_one_target_data($targetDoc, $targetURI, $self->_get_data($targetDoc, $targetURI));
    }
  }

  return 1;
}

sub _put_changes {
  my ($self) = @_;
  foreach my $targetURI (keys %{$self->_targets})
  {
    # $self->request->put($targetURI, $self->_targets->{$targetURI})
  }
  return;
}

# stubs to be implemented by derived class...

sub _get_targets_uri {
  return;
}

sub _update_one_target_data {
  return;
}

sub _get_data {
  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_elements_fetcher

=head1 SYNOPSIS

  Readonly::Scalar my $OUTPUT_PATH          => q(/prc:process/input-output-map/output/@uri);
  Readonly::Scalar my $CONTAINER_PATH       => q(/art:artifact/location/container/@uri);
  Readonly::Scalar my $PROCESS_PURPOSE_PATH => q(/prc:process/udf:field[@name="Plate Purpose"]);
  Readonly::Scalar my $TARGET_NAME          => q(WTSI Container Purpose Name);
  ## use critic

  extends 'wtsi_clarity::util::clarity_elements_fetcher';

  our $VERSION = '0.0';

  override '_get_targets_uri' => sub {
    return ( $OUTPUT_PATH, $CONTAINER_PATH );
  };

  override '_update_one_target_data' => sub {
    my ($self, $targetDoc, $targetURI, $value) = @_;

    $self->set_udf_element_if_absent($targetDoc, $TARGET_NAME, $value);

    return $targetDoc->toString();
  };

  override '_get_data' => sub {
    my ($self,$targetDoc, $targetURI) = @_;
    return $self->process_doc->findvalue($PROCESS_PURPOSE_PATH);
  };


=head1 DESCRIPTION

  Offers a generic way to find and update resources (called 'targets' in this
  context) in XML files, using XPath to find the files.

  _get_targets_uri(),
  _update_one_target_data(), and
  _get_data()
  have to be overriden.

  _get_targets_uri() must return an array of XPaths used to fetch the resources
  to updates. In the given example, the resources are the containers found
  inside the output artifacts of the process:

  _get_data() will be called to find the

  _update_one_target_data() is the core of the update mechanism. It updates each
  target with a given value. It will be applied to every target, and has to return
  the serialised version of the updated xml.


=head1 SUBROUTINES/METHODS

=head2 run - callback for the fluidigm_request_volume action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=item JSON

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Benoit Mangili

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
