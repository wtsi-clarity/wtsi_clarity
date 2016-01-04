package wtsi_clarity::irods::irods_publisher;

use Moose;
use Readonly;
use Carp;
use IPC::Open3 'open3';

our $VERSION = '0.0';

Readonly::Scalar my $OVERWRITE_IF_EXISTS => 1;

has 'md5_hash' => (
  is => "rw",
);

sub publish {
  my ($self, $file, $destination, $is_overwrite, @metadata) = @_;

  $self->_put($file, $destination, $OVERWRITE_IF_EXISTS);

  $self->md5_hash($self->_save_hash($destination));

  if (@metadata) {
    $self->_add_metadata_to_file($destination, @metadata);
  }

  return 1;
}

sub remove {
  my ($self, $file) = @_;

  my $irm_command = "irm $file";

  return $self->_execute_irods_command($irm_command);
}

sub _put {
  my ($self, $file, $destination, $is_overwrite) = @_;

  my $iput_command = "iput -K -f $file $destination";

  return $self->_execute_irods_command($iput_command);
}

sub _add_metadata_to_file {
  my ($self, $file, @metadatum) = @_;
  my $exit_code;

  foreach my $metadata (@metadatum) {
    my $imeta_command = "imeta set -d $file $metadata->{'attribute'} $metadata->{'value'}";
    $exit_code = $self->_execute_irods_command($imeta_command);
  }

  return $exit_code;
}

sub _execute_irods_command {
  my ($self, $command) = @_;

  my $exit_code = system qq{$command > /dev/null 2>&1};

  if ($exit_code != 0) {
    croak qq{The following iRODS command has failed:\n$command};
  }

  return $exit_code;
}

sub _save_hash {
  my ($self, $filename) = @_;

  my $command = "ichksum $filename";

  my ($writer, $reader, $err);
  open3($writer, $reader, $err, $command);
  my $output = <$reader>;

  $output =~ /\s+\S+\s+(\w+)/smx;
  if ($output) {
    my $md5_hash = $1;

    return $md5_hash;
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::irods::irods_publisher

=head1 SYNOPSIS

  Publish a data object (file) into iRODS:

  my $publisher = wtsi_clarity::irods::irods_publisher->new();
  $publisher->publish(file, $destination, $is_overwrite, @metadata);

  Remove a data object (file) from iRODS:

  my $publisher = wtsi_clarity::irods::irods_publisher->new();
  $publisher->remove(file);


=head1 DESCRIPTION

  This module wraps around iRODS command to be able to publish file to the iRODS file system
  and also be able to add metadat to it.

=head1 SUBROUTINES/METHODS

=head2 publish
  
  Publish a file to iRODS with metadata.
  Republish any file that is already published, but whose checksum has changed.

=head2 remove

  Remove the given file from iRODS. 

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item IPC::Open3

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
