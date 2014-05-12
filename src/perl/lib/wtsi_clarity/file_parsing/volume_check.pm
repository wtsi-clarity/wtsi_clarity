package wtsi_clarity::file_parsing::volume_check;

use Moose;
use Carp;

our $VERSION = '0.0';

has 'file_path', is => 'ro', isa => 'Str';
has 'delimiter', is => 'ro', isa => 'Str', default => q{,};

sub _format_tube_location {
  my ($self, $tube_location) = @_;

  # Add the colon after letter
  substr $tube_location, 1, 0, q{:};

  # Remove leading 0 if there is one
  $tube_location =~ s/:0/:/gmsx;

  return $tube_location;
}

sub parse {
  my $self = shift;

  open my $volume_check_file, '<', $self->file_path
    or croak 'File can not be found at ' . $self->file_path;

  my $result = $self->_parse_file($volume_check_file);

  close $volume_check_file
    or carp 'Error closing volume check file';

  return $result;
}

sub _parse_file {
  my ($self, $volume_check_file) = @_;
  my %result = ();

  # Strip the header
  my $header = <$volume_check_file>;

  while (<$volume_check_file>) {
    chomp;
    my ($rack_id, $tube_location, $volume) = split $self->delimiter, $_;

    $tube_location = $self->_format_tube_location($tube_location);

    croak "Volume already set for well $tube_location" if (exists $result{$tube_location});

    $result{$tube_location} = sprintf '%.4f', $volume;
  }

  return \%result;
}

1;

__END__

=head1 NAME

wtsi_clarity::file_parsing::volume_check

=head1 SYNOPSIS

=head1 DESCRIPTION

Class to parse volume check files

=head1 PROPERTIES

=head2 file_path

A string that contains the path to the Volume Check file

=head2 delimiter

The delimiter for a line of the file. Defaults to ","

=head1 SUBROUTINES/METHODS

=head2 parse

Opens a parses the Volume Check file. Returns a hash containing 
well locations as keys and volumes as values.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
