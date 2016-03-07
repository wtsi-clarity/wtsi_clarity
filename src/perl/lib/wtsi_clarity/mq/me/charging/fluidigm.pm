package wtsi_clarity::mq::me::charging::fluidigm;

use Moose;

our $VERSION = '0.0';

has 'product_type' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{Human QC 96:96},
);

has 'pipeline' => (
  isa     => 'Str',
  is      => 'ro',
  default => q{SM},
);

with 'wtsi_clarity::mq::me::charging::charging_common';

sub get_metadata {
  my ($self, $samples) = @_;

  my $metadata = $self->get_common_metadata($samples);
  $metadata->{'number_of_samples'}  = scalar @{$samples};

  return $metadata;
}

1;

__END__

=head1 NAME

wtsi_clarity::mq::me::charging::fluidigm

=head1 SYNOPSIS

  my $me = wtsi_clarity::mq::me::charging::fluidigm
             ->new(
               process_url => 'http://process',
               step_url    => 'http://step',
               timestamp   => '123456789',
             )->prepare_messages;

=head1 DESCRIPTION

  Gathers the data to prepare a charging message for fluidigm to be sent to the event warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 get_metadata

  Returns the matadata part of the event message.

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
