package wtsi_clarity::mq::message_enhancer;

use Moose::Role;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/uniq/;
use wtsi_clarity::clarity::process;

with qw/MooseX::Getopt wtsi_clarity::util::roles::clarity_request wtsi_clarity::util::configurable/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_LIMS_ID_PATH  => q{/art:details/art:artifact/sample/@limsid};
## use critic

has 'process_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'process'  => (
  isa             => 'wtsi_clarity::clarity::process',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
);

sub _build_process {
  my ($self) = @_;
  my $xml = $self->fetch_and_parse($self->process_url);
  return wtsi_clarity::clarity::process->new(xml => $xml, parent => $self);
}

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

  return $self->process->input_artifacts->findnodes($SAMPLE_LIMS_ID_PATH);
}

sub get_values_from_nodelist {
  my ($self, $function, $nodelist) = @_;
  my @values = uniq( map { $_->$function } $nodelist->get_nodelist());

  return \@values;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::message_enhancer

=head1 SYNOPSIS

  my $message_enhancer = wtsi_clarity::mq::message_enhancer->new();
  $message_enhancer->prepare_messages;

=head1 DESCRIPTION

 Base class of the message producers, which are preparing messages
 for publishing them to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  Using the model's module populating a model related message with the model's data.

=head2 sample_limsid_node_list

  Getting the sample nodes list from the input artifacts.

=head2 get_values_from_nodelist

  Returns the values from an XML node list. It returns either the values of an attribute or the values of the tags.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item XML::LibXML

=item Readonly

=item wtsi_clarity::util::roles::clarity_process_base

=item wtsi_clarity::util::configurable

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
