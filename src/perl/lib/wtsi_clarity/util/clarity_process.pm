package wtsi_clarity::util::clarity_process;

use Moose::Role;
use Carp;
use Readonly;
use List::MoreUtils qw/uniq/;

requires 'request';
requires 'config';
requires 'fetch_and_parse';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PARENT_PROCESS_PATH => q( /prc:process/input-output-map/input/parent-process/@uri );
Readonly::Scalar my $PROCESS_TYPE => q( /prc:process/type );
Readonly::Scalar my $PROCESS_URI_PATH => q(/prc:processes/process/@uri);
## use critic

our $VERSION = '0.0';

sub find_parent {
  my ($self, $needle_process_name, $child_process_url) = @_;

  my $parent_processes = $self->_find_parent($needle_process_name, $child_process_url);

  return $parent_processes;
}

sub _find_parent {
  my ($self, $needle_process_name, $process_url, $found_processes) = @_;

  if (!defined $found_processes) {
    $found_processes = {};
  }

  my $current_process = $self->fetch_and_parse($process_url);

  my $current_process_name = $current_process->findvalue($PROCESS_TYPE);

  if ($current_process_name eq $needle_process_name) {
    $found_processes->{$process_url} = q{};
  } else {
    my $parent_uris = $current_process->findnodes($PARENT_PROCESS_PATH);

    if ($parent_uris->size() > 0) {
      my @uniq_uris = map { $_->getValue() } $parent_uris->get_nodelist();

      foreach my $uri (@uniq_uris) {
        $self->_find_parent($needle_process_name, $uri, $found_processes);
      }
    }
  }

  my @found_processes = keys %{$found_processes};

  return \@found_processes;
}

sub find_previous_process {
  my ($self, $artifact_limsid, $process_name) = @_;

  my $uri = $self->config->clarity_api->{'base_uri'} . '/processes/?inputartifactlimsid=' . $artifact_limsid;
  my $process_list_xml = $self->fetch_and_parse($uri);

  my @processes = $process_list_xml->findnodes($PROCESS_URI_PATH)->get_nodelist();

  foreach my $process_uri (@processes) {
    my $process_xml = $self->fetch_and_parse($process_uri->getValue());

    my $process_type = $process_xml->findvalue($PROCESS_TYPE);

    if ($process_type eq $process_name) {
      return $process_xml;
    }
  }

  return 0;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_process

=head1 SYNOPSIS

  with 'wtsi_clarity::util::clarity_process';

=head1 DESCRIPTION

  Utitily role for finding a specific parent process

=head1 SUBROUTINES/METHODS

=head2 find_parent
  Requires the name of the parent process being searched for, and the URL of the child process. 
  Keeps recursing up parent processes until it finds the one being searched for

=head2 find_previous_process
  Takes a artifact limsid and a process name. Tries to find the specifed process xml in that artifact's
  history (using the ?inputartifactlimsid URL parameter)

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item List::MoreUtils

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
