package wtsi_clarity::epp::generic::default_next_step;
use Moose;
use Carp;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $CONFIGURATION_URI => q(/stp:step/configuration/@uri);
Readonly::Scalar my $ACTIONS_URL       => q(/stp:step/actions/@uri);
Readonly::Scalar my $NEXT_STEP_URI     => q(/protstepcnf:step/transitions/transition[@name='%s']/@next-step-uri);
Readonly::Scalar my $NEXT_ACTIONS_PATH => q(/stp:actions/next-actions/next-action);
## use critic

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
    my $self = shift;
    super();

    $self->set_next_step();

    return;
  };

has 'next_step' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
  );

has 'actions_uri' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
  );
sub _build_actions_uri {
  my ($self) = @_;

  return $self->step_doc->findvalue($ACTIONS_URL);
}

sub get_action_doc {
  my ($self) = @_;

  return $self->fetch_and_parse($self->actions_uri);
}

has 'next_step_uri' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
  );
sub _build_next_step_uri {
  my ($self) = @_;

  my $configuration = $self->fetch_and_parse($self->step_doc->findvalue($CONFIGURATION_URI));
  my $uri = $configuration->findvalue(sprintf $NEXT_STEP_URI, $self->next_step);

  if (!$uri) {
    croak q{No next step called '}.$self->next_step.q{' found.};
  }
  return $uri;
}

sub edit_actions_doc {
  my ($self) = @_;

  my $xml = $self->get_action_doc;

  my @nodes = $xml->findnodes($NEXT_ACTIONS_PATH);
  for my $node (@nodes) {
    $node->setAttribute('action', 'nextstep');
    $node->setAttribute('step-uri', $self->next_step_uri);
  }

  return $xml;
}

sub set_next_step {
  my ($self) = @_;

  $self->request->put($self->actions_uri, $self->edit_actions_doc->toString);

  return 1;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::default_next_step

=head1 SYNOPSIS

  my $epp = wtsi_clarity::epp::generic::default_next_step->new(
    process_url => http://process/1234,
    next_step   => 'Volume Check (SM)',
  );

=head1 DESCRIPTION

  Updates all the analytes in the step to have the given step as their default next step

=head1 SUBROUTINES/METHODS

=head2 get_action_doc
  Get the current next steps xml

=head2 edit_actions_doc
  Return the next steps xml with the updated information

=head2 set_next_step
  Post the edited next steps xml to the server

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Ronan Forman E<lt>rf9@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Genome Research Ltd.

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