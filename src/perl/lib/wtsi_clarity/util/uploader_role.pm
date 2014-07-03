package wtsi_clarity::util::uploader_role;

use Moose::Role;
use Carp;
use XML::LibXML;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

our $VERSION = '0.0';


sub _get_storage_request {
  my ($destination_uri, $filename) = @_;

  my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
  my $root = $doc->createElementNS('http://genologics.com/ri/file', 'file:file');

  my %tags = (
      'attached-to'       => $destination_uri,
      'content-location'  => $filename,
      'original-location' => $filename,
  );

  for my $name (keys %tags) {
      my $tag = $doc->createElement($name);
      my $value = $tags{$name};
      $tag->appendTextNode($value);
      $root->appendChild($tag);
  }
  $doc->setDocumentElement($root);
  return $doc;
}

sub _extract_locations {
  my ($url) = @_;
  return $url =~ /sftp:\/\/([^\/]+)\/(.*)\/([^\/]+[.].+)/smx;
}

sub addfile_to_resource {
  my ($self, $destination_uri, $filename) = @_;

  my $storage_request = _get_storage_request($destination_uri, $filename)
    or croak qq[Could not request storage for file $filename.\n $!];

  my $storage_raw = $self->request->post(($self->base_url).'glsstorage', $storage_request->toString());
  if (!$storage_raw) {
    croak qq[Impossible to retrieve the destination path for uploading $filename.\n $!];
  }
  my $storage = XML::LibXML->load_xml(string => $storage_raw);

  my $content_location = ($self->find_elements($storage,    q{/file:file/content-location}      ) )[0] ->textContent;

  my ($server, $remote_directory, $newfilename) = _extract_locations ($content_location);
  if (!$remote_directory) {
      croak qq[Cannot get base url from $content_location.\n $!];
  }

  $self->request->upload_file($server, $remote_directory, $filename, $newfilename )
    or croak qq[Could not upload the file > $filename as $remote_directory // $newfilename on the server.\n $!];

  return $self->request->post($self->base_url.'files', $storage_raw);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::uploader_role

=head1 SYNOPSIS

  with 'wtsi_clarity::util::uploader_role';

=head1 DESCRIPTION

  Utility role for wtsi_clarity::util::uploader_role

=head1 SUBROUTINES/METHODS

=head2 addfile_to_resource
  Takes a resource URI and file path on the local server, and attach the file to the given resource.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

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
