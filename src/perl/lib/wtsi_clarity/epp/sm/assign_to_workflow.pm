package wtsi_clarity::epp::sm::assign_to_workflow;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

use wtsi_clarity::util::request;
# use wtsi_clarity::util::clarity_elements;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_PATH => q( /prc:process/input-output-map/input/@post-process-uri );
## use critic

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

has 'new_wf' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
);

override 'run' => sub {
  my $self= shift;
  super();

  my @nodes = $self->process_doc->getDocumentElement()->findnodes($INPUT_PATH)->get_nodelist();
  my @uris = map { $_->getValue() } @nodes;

  my $workflows_raw = $self->request->get($self->base_url.'configuration/workflows')
    or croak q{Could not get the list of workflows.};
  my $workflows = XML::LibXML->load_xml(string => $workflows_raw );

  my $workflow_uri = _get_workflow_url($self->new_wf, $workflows);

  my $req = _make_rerouting_request($workflow_uri, \@uris)->toString();

  my $response = $self->request->post($self->base_url.'route/artifacts', $req)
    or croak q{Could not send successful request for rerouting.};

  return $response;
};

sub _get_workflow_url {
  my ($workflow_name, $workflows) = @_;
  my @workflows_nodes = $workflows->findnodes( qq{ /wkfcnf:workflows/workflow[\@name='$workflow_name'] } )->get_nodelist();
  return ($workflows_nodes[0])->getAttribute('uri');
}

sub _make_rerouting_request {
  my ($workflow_uri, $uris) = @_;

  my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
  my $root = $doc->createElementNS('http://genologics.com/ri/routing', 'rt:routing');

  my $assign_tag = $doc->createElement("assign");
  $assign_tag->setAttribute("workflow-uri", $workflow_uri);
  $root->appendChild($assign_tag);

  for my $uri (@{$uris}) {
    my $tag = $doc->createElement("artifact");
    $tag->setAttribute("uri", $uri);
    $assign_tag->appendChild($tag);
  }

  $doc->setDocumentElement($root);
  return $doc;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::assign_to_workflow

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::assign_to_workflow->new(
    process_url => 'http://my.com/processes/3345'
    new_wf      => 'Fluidigm'                     )->run();

=head1 DESCRIPTION

  Assign the artifact of a given process to another workflow (Does not unassign them from the current workflow).

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

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
