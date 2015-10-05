package wtsi_clarity::epp::isc::analytes_unattacher;
use strict;
use warnings FATAL => 'all';use Moose;
use Carp;

use wtsi_clarity::epp::generic::workflow_assigner;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;

  super();
  $self->_unattach();
};

sub _unattach {
  my $self = shift;

  my $workflow_uri = $self->process_doc->get_current_workflow_uri();
  if (!$workflow_uri) {
    croak "No analytes found in progress in step."
  }
  my $artifact_output_uri_ref = $self->process_doc->input_uris();

  my $doc = wtsi_clarity::epp::generic::workflow_assigner::make_workflow_unassign_request($workflow_uri, $artifact_output_uri_ref);

  my $post_uri = $self->config->clarity_api->{'base_uri'}.'/route/artifacts';
  return $self->request->post($post_uri, $doc->toString()) or croak qq{Could not send successful request for rerouting. ($post_uri)};
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::analytes_unattacher

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::analytes_unattacher->new(
    process_url => 'http://my.com/processes/24-64187'
    )->run();

=head1 DESCRIPTION

  Unattach all analytes currently in progress in the given workflow

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Ronan Forman E<lt>rf9@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Genome Research Ltd.

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
