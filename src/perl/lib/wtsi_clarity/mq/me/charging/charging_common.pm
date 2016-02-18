package wtsi_clarity::mq::me::charging::charging_common;

use Moose::Role;
use Readonly;
use List::MoreUtils qw/ uniq /;

use wtsi_clarity::dao::study_dao;
use wtsi_clarity::util::uuid_generator qw/new_uuid/;

with 'wtsi_clarity::mq::message_enhancer';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

Readonly::Scalar my $CLARITY_PROJECT_ROLE_TYPE  => q{clarity_charge_project};
Readonly::Scalar my $PROJECT_SUBJECT_TYPE       => q{clarity_project};
Readonly::Scalar my $RESEARCHER_EMAIL           => q{res:researcher/email};
## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $BAIT_LIBRARY_PATH          => q{udf:field[@name='WTSI Bait Library Name']};
Readonly::Scalar my $PROJECT_LIMSID            => q{project/@limsid};
## use critic

requires qw{product_type pipeline get_metadata};

has 'event_type' => (
  isa       => 'Str',
  is        => 'ro',
  required  => 1,
);

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

  my @messages = ();

  my @studies = uniq map {
    $_->findvalue($PROJECT_LIMSID);
  } @{$self->samples};

  for my $study (@studies) {
    my @samples = grep {
      $_->findvalue($PROJECT_LIMSID) eq $study;
    } @{$self->samples};

    my %message = ();
    $message{$self->type} = $self->_get_event_message(\@samples);
    $message{'lims'}      = $self->config->clarity_mq->{'id_lims'};

    push @messages, \%message;
  }

  return \@messages;
}

sub _get_event_message {
  my ($self, $samples) = @_;

  my $event_message = {
    uuid            => $self->_get_uuid,
    event_type      => $self->event_type,
    occured_at      => $self->_occured_at,
    user_identifier => $self->_user_identifier,
    subjects        => $self->_get_subjects($samples),
    metadata        => $self->get_metadata($samples),
  };

  return $event_message;
}

sub _get_uuid {
  my $self = shift;

  return new_uuid();
}

sub get_process {
  my ($self) = @_;

  return $self->process;
}

sub _occured_at {
  my ($self) = @_;

  my $date_run = $self->get_process->date_run;

  if (!$date_run) {
    $date_run = $self->timestamp;
  }

  return $date_run;
}

sub _user_identifier {
  my $self = shift;

  return $self->process->technician_doc->findvalue($RESEARCHER_EMAIL);
}

sub samples {
  my $self = shift;

  return $self->get_process->samples_wo_control;
}

sub get_bait_library {
  my ($self, $samples) = @_;

  return $samples->[0]->findvalue($BAIT_LIBRARY_PATH);
}

sub get_plex_level {
  my ($self, $samples) = @_;

  my $plex_level = wtsi_clarity::epp::isc::pooling::bait_library_mapper->new()
    ->plexing_mode_by_bait_library($self->get_bait_library($samples));
  ($plex_level) = $plex_level =~ m/(\d+)/xms;

  return $plex_level;
}

sub _get_subjects {
  my ($self, $samples) = @_;

  my $study = wtsi_clarity::dao::study_dao->new(lims_id => $samples->[0]->findvalue($PROJECT_LIMSID));

  my $clarity_project_subject = {
    role_type     => $CLARITY_PROJECT_ROLE_TYPE,
    subject_type  => $PROJECT_SUBJECT_TYPE,
    friendly_name => $study->name,
    uuid          => $self->_get_study_uuid($study),
  };

  my @subjects = ();
  push @subjects, $clarity_project_subject;
  return \@subjects;
}

sub _get_study_uuid {
  my ($self, $study) = @_;

  my $project_uuid = $study->study_uuid;

  if (!$project_uuid) {
    $project_uuid = $self->_get_uuid;

    $self->add_udf_element(
      $study->artifact_xml, q{WTSI Project UUID}, $project_uuid);
    $self->request->put($study->uri, $study->artifact_xml->toString());
  }

  return $project_uuid;
}

sub get_common_metadata {
  my ($self, $samples) = @_;

  my $study = wtsi_clarity::dao::study_dao->new(lims_id => $samples->[0]->findvalue($PROJECT_LIMSID));

  my $metadata = {
    product_type => $self->product_type,
    pipeline     => $self->pipeline,
    cost_code    => $study->cost_code,
  };

  return $metadata;
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

=head2 samples

  Returns an ArrayRef of samples

=head2 get_bait_library

  Returns the applied bait library type.

=head2 get_plex_level

  Returns the plex level of the bait library.

=head2 get_common_metadata

  Gathers and returns the common meta data of the event message.

=head2 get_process

  Returns the current process.
  This method has been provided to easily change the process to another one in the implementation classes.

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
