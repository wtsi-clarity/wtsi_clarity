package wtsi_clarity::mq::me::charging::charging_common;

use Moose::Role;
use Readonly;

use wtsi_clarity::dao::study_dao;
use wtsi_clarity::util::uuid_generator qw/new_uuid/;

with 'wtsi_clarity::mq::message_enhancer';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

Readonly::Scalar my $EVENT_TYPE                 => q{billing};
Readonly::Scalar my $CLARITY_PROJECT_ROLE_TYPE  => q{clarity_charge_project};
Readonly::Scalar my $PROJECT_SUBJECT_TYPE       => q{clarity_project};
Readonly::Scalar my $PIPELINE                   => q{SM};
Readonly::Scalar my $RESEARCHER_EMAIL           => q{res:researcher/email};

sub type {
  return 'event'
};

sub _build__lims_ids {
  # It has not got any lims_id.
  return 1;
};

# @Override
sub prepare_messages {
  my $self = shift;

  my %message = ();
  $message{$self->type} = $self->_get_event_message();
  $message{'lims'}      = $self->config->clarity_mq->{'id_lims'};

  return [\%message];
}

sub _get_event_message {
  my $self = shift;

  my %event_message = ();
  $event_message{'uuid'}            = $self->_get_uuid;
  $event_message{'event_type'}      = $EVENT_TYPE;
  $event_message{'occured_at'}      = $self->timestamp;
  $event_message{'user_identifier'} = $self->_user_identifier;
  $event_message{'subjects'}        = $self->_subjects;
  $event_message{'metadata'}        = $self->_metadata;

  return \%event_message;
}

sub _get_uuid {
  my $self = shift;

  return new_uuid();
}

has '_study_dao' => (
  isa => 'wtsi_clarity::dao::study_dao',
  is  => 'ro',
  lazy_build  => 1,
);
sub _build__study_dao {
  my $self = shift;
  return wtsi_clarity::dao::study_dao->new(lims_id => $self->process->study_limsid);
}

sub _user_identifier {
  my $self = shift;

  return $self->process->technician_doc->findvalue($RESEARCHER_EMAIL);
}

sub _cost_code {
  my $self = shift;

  return $self->_study_dao->cost_code;
}

sub _project_name {
  my $self = shift;

  return $self->_study_dao->name;
}

sub _number_of_samples {
  my $self = shift;

  return $self->process->number_of_input_artifacts;
}

sub _subjects {
  my $self = shift;

  my @subjects = ();
  my %clarity_project_subject = ();
  $clarity_project_subject{'role_type'}     = $CLARITY_PROJECT_ROLE_TYPE;
  $clarity_project_subject{'subject_type'}  = $PROJECT_SUBJECT_TYPE;
  $clarity_project_subject{'friendly_name'} = $self->_project_name;
  $clarity_project_subject{'uuid'}          = $self->_project_uuid;

  push @subjects, \%clarity_project_subject;
  return \@subjects;
}

sub _project_uuid {
  my $self = shift;

  my $project_uuid = $self->_study_dao->study_uuid;

  if (!$project_uuid) {
    $project_uuid = $self->_get_uuid;
    $self->add_udf_element(
      $self->_study_dao->artifact_xml, q{WTSI Project UUID}, $project_uuid);
    $self->request->put($self->_study_dao->uri, $self->_study_dao->artifact_xml->toString());
  }

  return $project_uuid;
}

sub _metadata {
  my $self = shift;

  my %metadata = ();
  $metadata{'product_type'}       = $self->product_type;
  $metadata{'pipeline'}           = $PIPELINE;
  $metadata{'cost_code'}          = $self->_cost_code;
  $metadata{'number_of_samples'}  = $self->_number_of_samples;

  return \%metadata;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::charging::charging_common

=head1 SYNOPSIS

  with 'wtsi_clarity::mq::me::charging::charging_common';

  my $me = wtsi_clarity::mq::me::charging::secondary_qc
             ->new(
               process_url => 'http://process',
               step_url    => 'http://step',
               timestamp   => '123456789',
             )->prepare_messages;

=head1 DESCRIPTION

  Gathers the data for preparing a charging message to be sent to the event warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  @Override
  Creates the message for the charging event.

=head2 type

  Returns the type of the message.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item wtsi_clarity::dao::study_dao

=item wtsi_clarity::util::uuid_generator

=item wtsi_clarity::mq::message_enhancer

=item wtsi_clarity::util::clarity_elements

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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