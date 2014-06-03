package wtsi_clarity::epp::mapper;

use Moose;
use Carp;
use Readonly;
use Getopt::Long qw(:config pass_through);

with 'MooseX::Getopt';

our $VERSION = '0.0';

Readonly::Hash my %ACTION2MODULE => (
    'volume_check' => 'sm::volume_check',
    'create_label' => 'sm::create_label',
    'stamp'        => 'stamp',
    'sample_received' => 'sm::sample_received',
    'qc_complete' => 'sm::qc_complete',
    'fluidigm_request_volume' => 'sm::fluidigm_request_volume',
    'cherrypick_volume' => 'sm::cherrypick_volume',
    'plate_purpose' => 'sm::plate_purpose',
	'bed_verification' => 'sm::bed_verification',
);

has 'action'  => (
    isa             => 'Str',
    is              => 'ro',
    required        => 1,
);

sub package_name {
  my $self = shift;
  if (!exists $ACTION2MODULE{$self->action}) {
    croak q[No callback for action ] . $self->action;
  }
  return 'wtsi_clarity::epp::' .  $ACTION2MODULE{$self->action};
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::mapper

=head1 SYNOPSIS

  #!/usr/bin/env perl
  use wtsi_clarity::epp::mapper;
  # to get the package that handles the action
  my $package = wtsi_clarity::epp::mapper->new_with_options();

=head1 DESCRIPTION

 Maps actions as supplied on the epp script command line to modules
 implementing callbacks for these actions

=head1 SUBROUTINES/METHODS

=head2 action - required attribute

=head2 package_name - returns teh package that implement a callback for
 this action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Getopt

=item Getopt::Long

=item Carp

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
