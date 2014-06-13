package wtsi_clarity::epp::sm::qc_complete;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use DateTime;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_PATH => q( prc:process/input-output-map/input/@post-process-uri );
Readonly::Scalar my $SAMPLE_PATH   => q ( /art:artifact/sample/@uri );
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

has '_samples' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy => 1,
  default => sub { {} },
);

override 'run' => sub {
  my $self= shift;
  super();

  $self->_fetch_and_update_samples($self->process_doc, _today() );

  $self->_put_changes();

  return 1;
};

sub _fetch_and_update_samples {
  my ($self, $doc, $date) = @_;

  foreach my $artifactURI ($doc->findnodes($ARTIFACT_PATH)) {
    my $artifactDoc = $self->fetch_and_parse($artifactURI->getValue());
    my $sampleURI = $self->_extract_sample_uri($artifactDoc);
    my $sampleDoc = $self->fetch_and_parse($sampleURI);

    if (!exists $self->_samples->{$sampleURI}) {
      $self->_samples->{$sampleURI} =
          $self->_update_one_sample_completion_date($sampleDoc, $sampleURI, $date);
    }
  }

  return 1;
}

sub _extract_sample_uri {
  my ($self, $artifactDoc) = @_;
  my $uri = $artifactDoc->findvalue($SAMPLE_PATH);
  return $uri;
}

sub _update_one_sample_completion_date {
  my ($self, $sampleDoc, $sampleURI, $date) = @_;
  $self->set_element_if_absent($sampleDoc, 'qc_complete', $date);
  return $sampleDoc->toString();
}

sub _put_changes {
  my ($self) = @_;
  foreach my $containerURI (keys %{$self->_samples})
  {
    $self->request->put($containerURI, $self->_samples->{$containerURI})
  }
  return;
}

sub _today {
  return DateTime->now->strftime('%Y-%m-%d');
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::qc_complete

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::qc_complete->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'QC Complete' field of all samples in the process to the current date.

=head1 SUBROUTINES/METHODS

=head2 run - callback for the qc_complete action

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
