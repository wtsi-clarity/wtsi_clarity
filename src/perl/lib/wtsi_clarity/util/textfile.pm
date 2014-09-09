package wtsi_clarity::util::textfile;

use Moose;
use Carp;

our $VERSION = '0.0';

has 'content' => (
  is => 'rw',
  isa => 'ArrayRef',
);

sub saveas {
  my ($self, $path) = @_;

  open my $fh, '>', $path
    or croak qq{Could not create/open file '$path'.};
  foreach my $line (@{$self->content})
  {
      ## no critic(InputOutput::RequireCheckedSyscalls)
      print {$fh} qq{$line\n}; # Print each entry in our array to the file
      ## use critic
  }
  close $fh
    or croak qq{ Unable to close $path.};

  return $path;
};


sub read_content {
  my ($self, $path) = @_;

  open my $fh, '<', $path
    or croak qq{Could not open file '$path'.};

  my @array = <$fh>;

  close $fh
    or croak qq{ Unable to close $path.};

  $self->content(\@array);

  return \@array;
};

1;

__END__

=head1 NAME

wtsi_clarity::util::textfile

=head1 SYNOPSIS

  use wtsi_clarity::util::textfile;

  ...

  my $textfile = wtsi_clarity::util::textfile->new(content => $data);
  $textfile->saveas("filename.txt");

  my $other_textfile = wtsi_clarity::util::textfile->new();
  $other_textfile->read_content("filename.txt");
  $data = $other_textfile->content;

=head1 DESCRIPTION

  Represents a file and encapsulate the FS interactions.

=head1 SUBROUTINES/METHODS

=head2 saveas

  Dump the internal content in an actual file on the filesystem, with a given name.

=head2 read_content

  read the content of an actual file on the filesystem, with a given name, and load it into
  the textfile instance.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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