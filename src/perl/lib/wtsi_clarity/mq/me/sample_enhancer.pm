package wtsi_clarity::mq::me::sample_enhancer;

use Moose;
use Readonly;
use wtsi_clarity::mq::dao::sample_dao;

with 'wtsi_clarity::mq::message_enhancer';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_LIMS_ID_PATH  => q{/art:details/art:artifact/sample/@limsid};
Readonly::Scalar my $CLARITY_GCLP_ID      => q{CLARITY-GCLP};
## use critic

sub prepare_messages {
  my $self = shift;

  my @messages = ();

  foreach my $sample_limsid (@{$self->_lims_ids}) {
    my $sample_msg = $self->_format_message($self->_get_sample_message($sample_limsid));
    push @messages, $sample_msg;
  }

  return \@messages;
}

sub _get_sample_message {
  my ($self, $sample_limsid) = @_;

  my $sample_dao = wtsi_clarity::mq::dao::sample_dao->new(lims_id => $sample_limsid);
  return $sample_dao->to_message;
}

sub _format_message {
  my ($self, $msg) = @_;

  my $formatted_msg = {};
  $formatted_msg->{'sample'} = $msg;
  $formatted_msg->{'lims'} = $CLARITY_GCLP_ID;

  return $formatted_msg;
}

has '_lims_ids' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);
sub _build__lims_ids {
  my $self = shift;

  my $sample_limsid_node_list = $self->_input_artifacts->findnodes($SAMPLE_LIMS_ID_PATH);

  return $self->_get_values_from_nodelist('getValue', $sample_limsid_node_list);
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::sample_enhancer

=head1 SYNOPSIS

  my $sample_enhancer = wtsi_clarity::mq::me::sample_enhancer->new();
  $sample_enhancer->prepare_message();

=head1 DESCRIPTION

 Preparing a sample related message to publish to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  Using the `Sample` module populating a sample related message with the sample data.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
