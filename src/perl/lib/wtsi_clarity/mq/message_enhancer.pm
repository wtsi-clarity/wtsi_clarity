package wtsi_clarity::mq::message_enhancer;

use Moose::Role;
use XML::LibXML;
use Readonly;

with qw/wtsi_clarity::util::roles::clarity_process_base wtsi_clarity::util::configurable/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_LIMS_ID_PATH  => q{/art:details/art:artifact/sample/@limsid};
## use critic

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'timestamp' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_lims_ids' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);

requires qw/ type _build__lims_ids/;

sub prepare_messages {
  my $self = shift;

  my @messages = ();

  foreach my $model_limsid (@{$self->_lims_ids}) {
    my $model_msg = $self->_format_message($self->_get_model_message($model_limsid));
    push @messages, $model_msg;
  }

  return \@messages;
}

sub _get_model_message {
  my ($self, $model_limsid) = @_;

  my $dao_type = q[wtsi_clarity::dao::] . $self->type . q[_dao];

  my $model_dao = $dao_type->new(lims_id => $model_limsid);
  return $model_dao->to_message;
}

sub _format_message {
  my ($self, $msg) = @_;

  my $formatted_msg = {};
  $formatted_msg->{$self->type} = $msg;
  $formatted_msg->{'lims'} = $self->config->clarity_mq->{'id_lims'};

  return $formatted_msg;
}

sub sample_limsid_node_list {
  my $self = shift;

  return $self->_input_artifacts->findnodes($SAMPLE_LIMS_ID_PATH);
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::message_enhancer

=head1 SYNOPSIS

  my $message_enhancer = wtsi_clarity::mq::message_enhancer->new();
  $message_enhancer->publish('message');

=head1 DESCRIPTION

 Base class of the message producers, which are publishing messages to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  Using the model's module populating a model related message with the model's data.

=head2 sample_limsid_node_list

  Getting the sample nodes list from the input artifacts.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

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
