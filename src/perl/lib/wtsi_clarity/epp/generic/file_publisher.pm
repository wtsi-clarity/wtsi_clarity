package wtsi_clarity::epp::generic::file_publisher;

use Moose;
use Carp;
use Readonly;
use List::MoreUtils qw/uniq/;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_URI_PATH => q(/prc:process/input-output-map/output/@uri);
Readonly::Scalar my $FILE_URI_PATH => q(/art:details/art:artifact/file:file/@uri);
Readonly::Scalar my $IS_PUBLISHED_PATH => q(/file:details/file:file/is-published);
## use critic


our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();

  my $output_artifacts = $self->request->batch_retrieve('artifacts', $self->_output_uris);
  my $file_uris        = $self->_extract_files($output_artifacts);
  my $files            = $self->request->batch_retrieve('files', $file_uris);

  $self->_set_files_to_published($files);
};

has '_output_uris' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__output_uris {
  my $self = shift;

  my $uri_list = $self->process_doc->findnodes($OUTPUT_URI_PATH);
  my @uris = uniq(map { $_->getValue(); } $uri_list->get_nodelist());

  return \@uris;
}

sub _extract_files {
  my ($self, $artifacts_xml) = @_;

  my $uri_list = $artifacts_xml->findnodes($FILE_URI_PATH);
  my @uris = map { $_->getValue(); } $uri_list->get_nodelist();

  return \@uris;
}

sub _set_files_to_published {
  my ($self, $files_xml) = @_;
  return $self->request->batch_update('files', $self->_set_is_published($files_xml));
}

sub _set_is_published {
  my ($self, $files_xml) = @_;

  my $is_published_nodes = $files_xml->findnodes($IS_PUBLISHED_PATH);

  foreach my $node ($is_published_nodes->get_nodelist()) {
    $self->update_text($node, 'true');
  }

  return $files_xml;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::file_publisher

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::file_publisher->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will find all the output files for a process, and set their <is-published> configuration to true

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::util::error_reporter

=item Readonly

=item List::MoreUtils;

=item wtsi_clarity::util::batch

=item wtsi_clarity::util::clarity_elements

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