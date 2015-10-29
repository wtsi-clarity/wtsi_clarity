package wtsi_clarity::epp::generic::workflow_assigner;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use Mojo::Collection 'c';

use wtsi_clarity::util::request;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $INPUT_PATH         => q( /prc:process/input-output-map/input/@post-process-uri );
Readonly::Scalar my $INPUT_IDS_PATH     => q{ /prc:process/input-output-map/input/@limsid };
Readonly::Scalar my $WORKFLOW_NAME_PATH => q{/wkfcnf:workflows/workflow/@name};
## use critic

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

# properties needed to configure the script

has 'new_wf' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
  trigger => \&_set_current_workflow,
);

sub _set_current_workflow {
  my ($self, $new_wf, $old_wf) = @_;

  $self->new_filtered_wf($self->_get_current_workflow_by_name($self->new_wf));

  return;
}

sub _get_workflow_names {
  my ($self) = @_;

  my @workflow_names = map {
    $_->getValue
  } $self->_all_workflows_details->findnodes($WORKFLOW_NAME_PATH);

  return \@workflow_names;
}

sub _get_current_workflow_by_name {
  my ($self, $given_workflow_name) = @_;

  my $workflow_names = $self->_get_workflow_names;

  my @filtered_wf_names = grep {
    /\Q$given_workflow_name\E/sxm
  } @{$workflow_names};

  my $current_workflow_name = q{};

  my $size_of_filtered_names = scalar @filtered_wf_names;

  if ($size_of_filtered_names > 1) {
    my @sorted_workflow_names = sort @filtered_wf_names;
    $current_workflow_name = $sorted_workflow_names[scalar @sorted_workflow_names - 1];
  } elsif ($size_of_filtered_names == 1) {
    $current_workflow_name = $filtered_wf_names[0];
  } else {
    croak qq{The given workflow '$given_workflow_name' is not exist.};
  }

  return $current_workflow_name;
}

has 'new_filtered_wf' => (
  isa        => 'Str',
  is         => 'rw',
  required   => 1,
  lazy_build => 1,
);

has 'new_step' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
);

has 'new_protocol' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
);

# main methods

override 'run' => sub {
  my $self = shift;
  super();
  my $response = $self->_main_method();
};


sub _main_method {
  my $self = shift;

  my $post_uri = $self->config->clarity_api->{'base_uri'}.'/route/artifacts';

  my $req_doc = $self->_make_request();
  my $response = $self->request->post($post_uri, $req_doc) or croak qq{Could not send successful request for rerouting. ($post_uri)};
  return $response;
};


sub _make_request {
  my $self = shift;
  my $req_doc;
  if (defined $self->new_step && defined $self->new_protocol) {
    my $new_uri = $self->_new_step_uri;
    $req_doc = make_step_rerouting_request($new_uri, $self->_input_uris())->toString();
  }
  else {
    my $new_workflow_id = _get_id_from_uri($self->_new_workflow_uri);
    my $new_uri = $self->_workflow_base_uri . q{/} . $new_workflow_id;

    $req_doc = make_workflow_rerouting_request($new_uri, $self->_input_uris())->toString();
  }
  return $req_doc;
}


sub _get_workflow_uri {
  # returns the uri of the workflow
  my ($workflow_name, $workflows) = @_;
  my @workflows_nodes = $workflows->findnodes( qq{ /wkfcnf:workflows/workflow[\@name='$workflow_name'] } )->get_nodelist();
  if (scalar @workflows_nodes <= 0) {
    croak qq{Workflow '$workflow_name' not found!};
  }
  return ($workflows_nodes[0])->getAttribute('uri');
}

sub _get_id_from_uri {
  my ($uri) = @_;

  if ($uri =~ /^.*\/([^\/]*)/xms) {
    return $1;
  }
  croak qq{Cannot find an id from the uri $uri};
}

sub get_step_uri {
  # returns the uri of the step searched for, going through the protocol specified by the user.
  my ($self, $step_name) = @_;

  if (!defined $self->new_step) {
    croak qq{One cannot search for a step if the its name has not been defined!};
  }
  if (!defined $self->new_protocol) {
    croak qq{One cannot search for a step if the protocol name has not been defined!};
  }
  if (!defined $self->_new_workflow_details) {
    croak qq{The 'workflows details' object cannot be null!};
  }

  # my $step_name = $self->new_step;
  my $step_uri = c->new($self->_new_workflow_details->findnodes(qq{/wkfcnf:workflow/stages/stage[\@name="$step_name"]/\@uri})->get_nodelist())
    ->map( sub {
    $_->getValue();
  })
    ->first( sub {
    $self->_is_step_in_correct_protocol($_, $self->_new_protocol_uri);
  });
  if (!defined $step_uri) {
    croak qq{Step '$step_name' not found!};
  }
  return $step_uri;
}

sub _is_step_in_correct_protocol {
  # checks if the step specified is part of the protocol specified by its uri.
  my ($self, $stage_uri, $protocol_uri) = @_;

  my $stage_raw = $self->request->get($stage_uri) or croak qq{Could not get this stage. ($stage_uri)};
  my $stage_details = XML::LibXML->load_xml(string => $stage_raw );

  return c->new($stage_details->findnodes(qq{/stg:stage/protocol[\@uri="$protocol_uri"]})->get_nodelist())
    ->size();
}

### creation of routing requests

=head2 make_workflow_rerouting_request()
Assign analytes to the given workflow
Input:
  $new_uri - Uri for the new workflow.
  $artifact_uris - Uris for the analytes.
Output:
  XmlDocument payload for the POST request.
=cut

sub make_workflow_rerouting_request {
  my ($new_uri, $artifact_uris) = @_;

  return _make_rerouting_request($new_uri, $artifact_uris, 'workflow-uri');
}

=head2 make_step_rerouting_request()

Assign analytes to the given step

Input:
  $new_uri - Uri for the new step.
  $artifact_uris - Uris for the analytes.

Output:
  XmlDocument payload for the POST request.

=cut

sub make_step_rerouting_request {
  my ($new_uri, $artifact_uris) = @_;

  return _make_rerouting_request($new_uri, $artifact_uris, 'stage-uri');
}

=head2 make_workflow_unassign_request()

  Unassign the given analytes from the given workflow

  Input:
  $new_uri - Uri for the workflow.
  $artifact_uris - Uris for the analytes.

Output:
  XmlDocument payload for the POST request.

=cut

sub make_workflow_unassign_request {
  my ($new_uri, $artifact_uris) = @_;

  return _make_rerouting_request($new_uri, $artifact_uris, 'workflow-uri', 1);
}

sub _make_rerouting_request {
  my ($new_uri, $artifact_uris, $uri_type, $unassign) = @_;

  my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
  my $root = $doc->createElementNS('http://genologics.com/ri/routing', 'rt:routing');

  my $assign_tag = $doc->createElement($unassign ? 'unassign' : 'assign');
  $assign_tag->setAttribute($uri_type, $new_uri);
  $root->appendChild($assign_tag);

  for my $uri (@{$artifact_uris}) {
    my $tag = $doc->createElement('artifact');
    $tag->setAttribute('uri', $uri);
    $assign_tag->appendChild($tag);
  }

  $doc->setDocumentElement($root);
  return $doc;
}

# properties used internaly

has '_input_uris' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_uris {
  my $self = shift;
  return $self->grab_values($self->process_doc->xml, $INPUT_PATH);
}

has '_workflow_base_uri' => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

sub _build__workflow_base_uri {
  my $self = shift;
  return $self->config->clarity_api->{'base_uri'}.'/configuration/workflows';
}

has '_new_workflow_uri' => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

sub _build__new_workflow_uri {
  my $self = shift;
  return _get_workflow_uri($self->new_filtered_wf, $self->_all_workflows_details());
}

has '_new_protocol_uri' => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

sub _build__new_protocol_uri {
  # gets the uri of the new protocol
  my $self = shift;
  my $protocol_name = $self->new_protocol;

  my @uris = c->new($self->_new_workflow_details->findnodes(qq{ / wkfcnf:workflow / protocols / protocol[\@name = "$protocol_name"] / \@uri})->get_nodelist())
    ->map(sub {
    return $_->getValue();
  })
    ->each();

  if (scalar @uris > 1) {
    croak q{There can only be one protocol name };
  }
  if (scalar @uris < 1) {
    croak qq{The protocol '$protocol_name' requested could not be found!};
  }
  return $uris[0];
}

has '_new_step_uri' => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);

sub _build__new_step_uri {
  my $self = shift;
  return $self->get_step_uri($self->new_step);
}

has '_all_workflows_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__all_workflows_details {
  my $self = shift;
  my $workflows_uri = $self->_workflow_base_uri;
  my $workflows_raw = $self->request->get($workflows_uri) or croak qq{Could not get the list of workflows. ($workflows_uri)};
  return XML::LibXML->load_xml(string => $workflows_raw );
}

has '_new_workflow_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__new_workflow_details {
  my $self = shift;
  my $workflows_uri = $self->_new_workflow_uri();
  my $workflows_raw = $self->request->get($workflows_uri) or croak qq{Could not get the new workflow. ($workflows_uri)};
  return XML::LibXML->load_xml(string => $workflows_raw );
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::workflow_assigner

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::workflow_assigner->new(
    process_url => 'http://my.com/processes/3345'
    new_wf      => 'Fluidigm'                     )->run();

  or

  wtsi_clarity::epp:generic::workflow_assigner->new(
    process_url => 'http://my.com/processes/3345'
    new_wf      => 'Fluidigm'
    new_protocol=> 'protocol name',
    new_step    => 'step name',                   )->run();

=head1 DESCRIPTION

  Assign the artifact of a given process to another workflow or to another step in a
  given protocol of a given workflow (Does not unassign them from the current workflow).

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head2 get_step_uri

  The input parameter is the name of a step.
  Returns the uri of the step searched for, going through the protocol specified by the user.

=head2 make_step_rerouting_request_doc

  Create an XML document for rerouting samples to be assigned to another step.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=item Mojo::Collection

=item wtsi_clarity::util::request

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
