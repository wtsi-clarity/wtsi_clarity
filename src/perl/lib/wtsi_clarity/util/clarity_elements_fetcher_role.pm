package wtsi_clarity::util::clarity_elements_fetcher_role;

use Moose::Role;
use XML::LibXML;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';

requires 'get_data';
requires 'get_targets_uri';
requires 'update_one_target_data';

our $VERSION = '0.0';

# core methods ....

sub fetch_and_update_targets {
  my ($self, $doc) = @_;

  my $targets = $self->_fetch_targets_hash();

  while (my ($targetURI, $targetDoc) = each %{$targets} ) {
    if (!exists $self->_targets->{$targetURI}) {
      $self->_targets->{$targetURI} =
          $self->update_one_target_data($targetDoc, $targetURI, $self->get_data($targetDoc, $targetURI));
    }
  }

  return 1;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_elements_fetcher_role

=head1 SYNOPSIS

  with 'wtsi_clarity::util::clarity_elements_fetcher_role';

=head1 DESCRIPTION

  Offers a role to find and update resources (called 'targets' in this
  context) in XML files, using XPath to find the files. It has to be used
  in conjonction with a class extending wtsi_clarity::util::clarity_elements_fetcher.

  get_targets_uri(),
  update_one_target_data(), and
  get_data()
  have to be implemented.

  get_targets_uri() must return an array of XPaths used to fetch the resources
  to updates. In the given example, the resources are the containers found
  inside the output artifacts of the process:

  get_data() will be called to find the

  update_one_target_data() is the core of the update mechanism. It updates each
  target with a given value. It will be applied to every target, and has to return
  the serialised version of the updated xml.

=head1 SUBROUTINES/METHODS

=head2 fetch_targets_hash
  Takes a list of XPaths, and use them to find the targets that will need to be
  updated, as a hash (its keys are the URI of the targets).
  Each Xpath has to point toward a URI, that will be fetched, and use to apply the next one.

=head2 fetch_and_update_targets
  Takes an XML doc to process.
  Method used by clarity_elements_fetcher to fetch the target, and update them.

=head2  put_changes
  Method used to send the update requests after having updated the targets.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item XML::LibXML

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

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
