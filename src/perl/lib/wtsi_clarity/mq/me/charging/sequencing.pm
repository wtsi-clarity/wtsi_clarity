package wtsi_clarity::mq::me::charging::sequencing;

use Moose;
use Readonly;

use wtsi_clarity::epp::isc::pooling::bait_library_mapper;

our $VERSION = '0.0';

has 'product_type' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{GCLP ISC},
);

has 'pipeline' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{IHTP},
);

with 'wtsi_clarity::mq::me::charging::charging_common';

Readonly::Scalar my $PRE_CAPTURE_LIB_POOLING_STEP_NAME  => q{Pre Capture Lib Pooling};
Readonly::Scalar my $SEQUENCING_VERSION                 => q{1};
Readonly::Scalar my $SEQUENCING_PLATFORM                => q{2500};
Readonly::Scalar my $RUN_TYPE                           => q{PE};

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_SAMPLE_URI                => q{art:artifact/sample/@uri};
Readonly::Scalar my $PROJECT_LIMSID                     => q{project/@limsid};
Readonly::Scalar my $SAMPLE_PATH                        => q{smp:details/smp:sample};
## use critic

sub get_metadata {
  my ($self, $samples) = @_;

  my $metadata = $self->get_common_metadata($samples);
  $metadata->{'version'}          = $SEQUENCING_VERSION;
  $metadata->{'platform'}         = $SEQUENCING_PLATFORM;
  $metadata->{'run_type'}         = $RUN_TYPE;
  $metadata->{'read_length'}      = $self->_get_read_length($samples);
  $metadata->{'plex_level'}       = $self->get_plex_level($samples);
  $metadata->{'number_of_lanes'}  = scalar @{$samples};

  return $metadata;
}

sub _get_read_length {
  my ($self, $samples) = @_;

  my $study = wtsi_clarity::dao::study_dao->new(lims_id => $samples->[0]->findvalue($PROJECT_LIMSID));

  return $study->read_length;
}

# @Override
sub samples {
  my ($self) = @_;

  my $input_analyte_doc = $self->get_process->first_input_analyte_doc;

  my @sample_uris = $input_analyte_doc->findnodes($ARTIFACT_SAMPLE_URI)->to_literal_list;
  my $sample_doc = $self->request->batch_retrieve('samples', \@sample_uris);

  return $sample_doc->findnodes($SAMPLE_PATH);
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::charging::sequencing

=head1 SYNOPSIS

  my $me = wtsi_clarity::mq::me::charging::sequencing
             ->new(
               process_url => 'http://process',
               step_url    => 'http://step',
               timestamp   => '123456789',
             )->prepare_messages;

=head1 DESCRIPTION

  Gathers the data to prepare a charging message for Sequencing to be sent to the event warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 samples

  Returns an ArrayRef of samples

=head2 get_metadata

  Returns the matadata part of the event message.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item wtsi_clarity::mq::me::charging::charging_common

=item wtsi_clarity::epp::isc::pooling::bait_library_mapper

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
