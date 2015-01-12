package wtsi_clarity::util::roles::clarity_process_base;

use Moose::Role;
use Readonly;
use List::MoreUtils qw/uniq/;

with qw/MooseX::Getopt wtsi_clarity::util::roles::clarity_request/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_ARTIFACT_URIS_PATH => q{/prc:process/input-output-map/input/@uri};
## use critic

has 'process_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'process_doc'  => (
  isa             => 'XML::LibXML::Document',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
  handles         => {'findnodes' => 'findnodes'},
);

sub _build_process_doc {
  my ($self) = @_;
  return $self->fetch_and_parse($self->process_url);
}

has '_input_artifacts' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__input_artifacts {
  my $self = shift;

  my $input_node_list = $self->findnodes($INPUT_ARTIFACT_URIS_PATH);
  my $input_uris = $self->_get_values_from_nodelist('getValue', $input_node_list);

  return $self->request->batch_retrieve('artifacts', $input_uris);
}

sub _get_values_from_nodelist {
  my ($self, $function, $nodelist) = @_;
  my @values = uniq( map { $_->$function } $nodelist->get_nodelist());

  return \@values;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::roles::clarity_process_base

=head1 SYNOPSIS

  with 'wtsi_clarity::util::roles::clarity_process_base';
  $self->fetch_and_parse('http://test.com/test/234');

=head1 DESCRIPTION

  Role that describes the base Clarity process tasks.

=head1 SUBROUTINES/METHODS

=head2 fetch_and_parse - given url, fetches XML document and returns its XML dom representation

  my $dom = $self->fetch_and_parse($url);

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Readonly

=item List::MoreUtils

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL

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
