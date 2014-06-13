package wtsi_clarity::epp::sm::plate_purpose;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ANALYTE_PATH => q( prc:process/input-output-map/output/@uri );
Readonly::Scalar my $PROCESS_PURPOSE_PATH => q ( prc:process/udf:field[@name="Plate Purpose"] );
Readonly::Scalar my $CONTAINER_PATH => q ( art:artifact/location/container/@uri );
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

has '_containers' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy => 1,
  default => sub { {} }
);

override 'run' => sub {
  my $self= shift;
  super();

  $self->_fetch_and_update_containers($self->process_doc);

  $self->_put_changes();

  return 1;
};

sub _fetch_and_update_containers {
  my ($self, $doc) = @_;
  my $purpose = $doc->findvalue($PROCESS_PURPOSE_PATH);
  # my $containers = {};

  foreach my $analyteURI ($doc->findnodes($ANALYTE_PATH)) {
    my $analyteDoc = $self->fetch_and_parse($analyteURI->getValue());
  	my $containerURI = $self->_extract_container_uri($analyteDoc);
    my $containerDoc = $self->fetch_and_parse($containerURI);

    if (!exists $self->_containers->{$containerURI}) {
      $self->_containers->{$containerURI} =
          $self->_update_one_container_purpose($containerDoc, $containerURI, $purpose);
    }
  }

  return 1;
}

sub _extract_container_uri {
  my ($self, $analyteDoc) = @_;
  my $uri = $analyteDoc->findvalue($CONTAINER_PATH);
  return $uri;
}


sub _update_one_container_purpose {
  my ($self, $containerDoc, $containerURI, $purpose) = @_;
  $self->set_element($containerDoc, 'plate_purpose', $purpose);

  return $containerDoc->toString();
}

sub _put_changes {
  my ($self) = @_;
  foreach my $containerURI (keys %{$self->_containers})
  {
    $self->request->put($containerURI, $self->_containers->{$containerURI})
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::plate_purpose

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::plate_purpose->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'purpose' field of all WTSI Containers in the process to the plate purpose field.

=head1 SUBROUTINES/METHODS

=head2 run - callback for the plate_purpose action

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
