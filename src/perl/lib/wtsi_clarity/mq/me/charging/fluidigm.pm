package wtsi_clarity::mq::me::charging::fluidigm;

use Moose;
use Readonly;
use POSIX qw(strftime);

use wtsi_clarity::dao::study_dao;
use wtsi_clarity::util::uuid_generator qw/new_uuid/;

with qw/ wtsi_clarity::mq::message_enhancer /;

our $VERSION = '0.0';

Readonly::Scalar my $EVENT_TYPE                 => q{billing};
Readonly::Scalar my $CLARITY_PROJECT_ROLE_TYPE  => q{Clarity_charge_project};
Readonly::Scalar my $PROJECT_SUBJECT_TYPE       => q{Clarity_project};
Readonly::Scalar my $PRODUCT_TYPE               => q{Human QC 96:96};
Readonly::Scalar my $PIPELINE                   => q{SM};
Readonly::Scalar my $RESEARCHER_EMAIL           => q{res:researcher/email};

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROJECT_LIMSID             => q{prj:project/@limsid};
## use critic

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

sub _study_limsid {
  my $self = shift;

  return $self->process->project_doc->findvalue($PROJECT_LIMSID);
}

has '_study_dao' => (
  isa => 'wtsi_clarity::dao::study_dao',
  is  => 'ro',
  lazy_build  => 1,
);
sub _build__study_dao {
  my $self = shift;
  return wtsi_clarity::dao::study_dao->new(lims_id => $self->_study_limsid);
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
  $clarity_project_subject{'uuid'}          = $self->_get_uuid;

  push @subjects, \%clarity_project_subject;
  return \@subjects;
}

sub _metadata {
  my $self = shift;

  my %metadata = ();
  $metadata{'product_type'}       = $PRODUCT_TYPE;
  $metadata{'pipeline'}           = $PIPELINE;
  $metadata{'cost_code'}          = $self->_cost_code;
  $metadata{'number_of_samples'}  = $self->_number_of_samples;

  return \%metadata;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::charging::fluidigm

=head1 SYNOPSIS



=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  @Override
  Creates the message for the fluidigm charging event.

=head2 type

  Returns the type of the message.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

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
