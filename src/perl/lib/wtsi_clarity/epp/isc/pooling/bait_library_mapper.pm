package wtsi_clarity::epp::isc::pooling::bait_library_mapper;

use Moose;
use Carp;
use Readonly;
use JSON;
use File::Spec::Functions;
use English qw( -no_match_vars );

use wtsi_clarity::util::config;

with qw/wtsi_clarity::util::configurable/;

our $VERSION = '0.0';

Readonly::Scalar my $BAIT_LIBRARY_CONFIG => q[bait_library.json];

has '_bait_library_config_file' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__bait_library_config_file {
  my $self = shift;
  my $file_path = catfile($self->config->dir_path, $BAIT_LIBRARY_CONFIG);
  open my $fh, '<:encoding(UTF-8)', $file_path
    or croak qq[Could not retrive the configuration file at $file_path\n];
  local $RS = undef;
  my $json_text = <$fh>;
  close $fh
    or croak qq[Could not close handle to $file_path\n];
  return decode_json($json_text);
}

sub plexing_mode_by_bait_library {
  my ($self, $bait_library_name) = @_;

  my $plexing_mode;

  while ( my ($registerted_plexing_mode, $bait_libraries) = each %{$self->_bait_library_config_file}) {
    foreach my $registered_library_name (@{$bait_libraries}) {
      if ($registered_library_name eq $bait_library_name) {
        $plexing_mode = $registerted_plexing_mode;
        last;
      }
    }
    if ($plexing_mode) {
      last;
    }
  }

  if (! defined $plexing_mode) {
    croak qq{This Bait Library is not registered: $bait_library_name};
  }

  return $plexing_mode;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pooling::bait_library_mapper

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::pooling::bait_library_mapper->new()
    ->plexing_mode_by_bait_library("valid bait library name");

=head1 DESCRIPTION

  Checks if the bait library is registered in the config file. 
  If it is registered return the plex count, otherwise throws an error message.

=head1 SUBROUTINES/METHODS

=head2 plexing_mode_by_bait_library

  Returns the plexing mode by the given bait library.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item File::Spec::Functions

=item English qw( -no_match_vars )

=item JSON

=item wtsi_clarity::util::config

=item wtsi_clarity::util::configurable

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

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
