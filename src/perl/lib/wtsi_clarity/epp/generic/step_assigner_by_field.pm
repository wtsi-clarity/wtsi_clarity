package wtsi_clarity::epp::generic::step_assigner_by_field;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

Readonly::Scalar my $NEXT_STEP_ACTION           => q{nextstep};
Readonly::Scalar my $REMOVE_ACTION              => q{remove};

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $CONFIGURATION_URI_PATH     => q( /stp:actions/configuration/@uri );
Readonly::Scalar my $TRANSITION_URI_PATH        => q( /protstepcnf:step/transitions/transition );
Readonly::Scalar my $NEXT_ACTION_PATH           => q(/stp:actions/next-actions/next-action);
Readonly::Scalar my $SAMPLE_URI_PATH            => q{/art:artifact/sample/@uri};
Readonly::Scalar my $FIELD_NAME_PATH            => q{/smp:sample/udf:field[@name="%s"]};
## use critic

Readonly::Array my @PROCEED_VALUES => qw{Y YES};

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

# properties needed to configure the script

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'field_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'next_step_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

sub _next_action_uri {
  my ($self) = @_;

  return join q{/}, ($self->step_url, 'actions');
}

has '_nextActionsList' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__nextActionsList {
  my $self = shift;

  return $self->fetch_and_parse($self->_next_action_uri);
}

has '_current_protocol_step' => (
  isa             => 'XML::LibXML::Document',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__current_protocol_step {
  my $self = shift;

  return $self->fetch_and_parse($self->_nextActionsList->findvalue($CONFIGURATION_URI_PATH));
}

has '_transition_step_uri_by_step_name' => (
  isa             => 'HashRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__transition_step_uri_by_step_name {
  my $self = shift;

  my $transitions = ();
  $transitions->{'current_step'} = $self->_nextActionsList->findvalue($CONFIGURATION_URI_PATH);

  my @transition_nodes = $self->_current_protocol_step->findnodes($TRANSITION_URI_PATH)->get_nodelist();

  foreach my $transition_node (@transition_nodes) {
    if ($transition_node->getAttribute(q{name}) eq $self->next_step_name) {
      $transitions->{$self->next_step_name} = $transition_node->getAttribute(q{next-step-uri});
    }
  }

  return $transitions;
}

sub _get_artifact_by_uri {
  my ($self, $artifact_uri) = @_;

  return $self->fetch_and_parse($artifact_uri);
}

sub _get_sample_by_uri {
  my ($self, $sample_uri) = @_;

  return $self->fetch_and_parse($sample_uri);
}

sub _set_next_actions {
  my $self = shift;

  my @next_action_nodes = $self->_nextActionsList->findnodes($NEXT_ACTION_PATH)->get_nodelist();

  foreach my $next_action_node (@next_action_nodes) {
    my $artifact_xml = $self->_get_artifact_by_uri($next_action_node->getAttribute(q{artifact-uri}));
    my $sample_xml = $self->_get_sample_by_uri($artifact_xml->findvalue($SAMPLE_URI_PATH));
    my $is_proceed_to_sequencing = $sample_xml->findvalue(sprintf $FIELD_NAME_PATH, $self->field_name);

    if (uc($is_proceed_to_sequencing) ~~ @PROCEED_VALUES) {
      $next_action_node->setAttribute('action', $NEXT_STEP_ACTION);
      $next_action_node->setAttribute('step-uri', $self->_transition_step_uri_by_step_name->{$self->next_step_name});
    } else {
      $next_action_node->setAttribute('action', $REMOVE_ACTION);
      $next_action_node->removeAttribute('step-uri');
    }
  }

  return;
}

sub _update_next_actions {
  my $self = shift;

  $self->request->put($self->_next_action_uri, $self->_nextActionsList->toString);

  return;
}

# main methods

override 'run' => sub {
  my $self= shift;
  super();

  $self->_set_next_actions;

  $self->_update_next_actions;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::step_assigner_by_field

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::step_assigner_by_field->new(
    process_url       => 'http://my.com/processes/3345',
    step_url          => 'http://my.com/steps/3345',
    next_step_name    => 'Cherrypick Worksheet & Barcode(SM)',
    field_name        => 'WTSI Proceed To Sequencing?')->run();

=head1 DESCRIPTION

  Assign the the selected artifacts automatically to its next step.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
