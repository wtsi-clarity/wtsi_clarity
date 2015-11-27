package wtsi_clarity::mq::me::charging::library_construction;

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

has '_library_type' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{ISC},
);

with 'wtsi_clarity::mq::me::charging::charging_common';

Readonly::Scalar my $PRE_CAPTURE_LIB_POOLING_STEP_NAME => q{Pre Capture Lib Pooling};

sub metadata {
  my ($self) = @_;

  my $metadata = $self->common_metadata;
  $metadata->{'library_type'}         = $self->_library_type;
  $metadata->{'bait_library'}         = $self->_bait_library;
  $metadata->{'plex_level'}           = $self->_plex_level;
  $metadata->{'number_of_libraries'}  = $self->number_of_samples;

  return $metadata;
}

# @Override
sub get_process {
  my ($self) = @_;

  my $pre_capture_process_doc = $self->process->find_by_artifactlimsid_and_name(
    $self->process->first_input_analyte_limsid,
    $PRE_CAPTURE_LIB_POOLING_STEP_NAME
  );

  return wtsi_clarity::clarity::process->new(xml => $pre_capture_process_doc, parent => $self);
}

sub _bait_library {
  my ($self) = @_;

  return $self->get_process->bait_library;
}

sub _plex_level {
  my ($self) = @_;

  my $plex_level = wtsi_clarity::epp::isc::pooling::bait_library_mapper->new()
                      ->plexing_mode_by_bait_library($self->_bait_library);
  ($plex_level) = $plex_level =~ m/(\d+)/xms;

  return $plex_level;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::charging::library_construction

=head1 SYNOPSIS

  my $me = wtsi_clarity::mq::me::charging::library_construction
             ->new(
               process_url => 'http://process',
               step_url    => 'http://step',
               timestamp   => '123456789',
             )->prepare_messages;

=head1 DESCRIPTION

  Gathers the data to prepare a charging message for Library Construction to be sent to the event warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 metadata

  Returns the matadata part of the event message.

=head2 get_process

  Override from charging_common mixin.
  Sets the current process to the 'Pre Capture Lib Pooling' process related to this artifact.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::mq::me::charging::charging_common

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
