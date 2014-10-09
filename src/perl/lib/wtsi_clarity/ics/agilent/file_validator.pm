package wtsi_clarity::ics::agilent::file_validator;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use List::MoreUtils qw/first_index/;

use wtsi_clarity::util::well_mapper;

our $VERSION = 0.0;

Readonly::Scalar my $FILE_NAME_DELIMITER => '_';
Readonly::Scalar my $SOURCE_WELLS_PER_CHIP => 6;
Readonly::Scalar my $MAX_COLUMNS_FROM_SOURCE => 3;

sub BUILD {
  my ($self) = @_;
  $self->_validate_files();
  return;
}

has 'file_names' => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
  trigger  => \&_build_files,
);

=head2 files

  Description: A collection of file objects, sorted by start well position.
  Returntype : Mojo::Collection

=cut
has 'files' => (
  is => 'ro',
  isa => 'Mojo::Collection',
  builder => '_build_files',
  lazy => 1,
);

sub _build_files {
  my $self = shift;
  my @files = ();

  foreach my $file (@{$self->file_names}) {
    my ($barcode, $start_well, $end_well) = split $FILE_NAME_DELIMITER, $file;
    $end_well =~ s/[.]xml|[.]XML//xms;

    push @files, {
      file_name => $file,
      barcode => $barcode,
      start_well => $start_well,
      end_well => $end_well
    };
  }

  # Sort the files by start_cell... needed for validation later and is just handy...
  my $sorted_file_collection = c->new(@files)
                         ->sort(sub {
                            my $a_ = $self->_find_index($a->{'start_well'});
                            my $b_ = $self->_find_index($b->{'start_well'});

                            return $a_ <=> $b_;
                          });

  return $sorted_file_collection;
}

has 'files_by_well' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_files_by_well',
);

sub _build_files_by_well {
  my $self = shift;
  my %files_by_well = ();

  foreach my $file (@{$self->files}) {
    my $index_of_start_well = $self->_find_index($file->{'start_well'});
    my $index_of_end_well   = $self->_find_index($file->{'end_well'});

    for ($index_of_start_well..$index_of_end_well) {
      my $well = $self->_wells->[$_];
      $files_by_well{$well}->{'file_path'} = $file->{'file_name'};
      $files_by_well{$well}->{'wells'} = $self->_map_well($well);
    }
  }

  return \%files_by_well;
};

=head2 _map_well

  Example    : $self->_map_well('B3')
  Description: Maps from a 96 well plate to the two positions (because there are ALWAYS duplicates)
               on a Bioanalyser chip
  Returntype : ArrayRef

=cut
sub _map_well {
  my ($self, $plate_well) = @_;
  my $index = $self->_find_index($plate_well);

  $index = ($index % $SOURCE_WELLS_PER_CHIP) * 2;

  return [$index+1, $index+2];;
}

=head2 _wells

  Description: A column ordered array of well poisitions i.e. A1, B1, C1, D1 ... etc.
  Returntype : ArrayRef

=cut
has '_wells' => (
  is      => 'ro',
  isa     => 'ArrayRef',
  builder => '_build_wells',
  lazy    => 1,
);

sub _build_wells {
  my $self = shift;
  my @wells = ();

  for (1..$MAX_COLUMNS_FROM_SOURCE) {
    foreach my $column ('A'..'H') {
      push @wells, $column . $_;
    }
  }

  return \@wells;
}

=head2 _find_index

  Example    : $self->_find_index('B3')
  Description: Returns the index (using first_index, there should only be one!) of
               a well for _wells (see above)
  Returntype : Integer

=cut
sub _find_index {
  my ($self, $well_name) = @_;
  return first_index { $_ eq $well_name } @{$self->_wells};
}

### Validations from here...

sub _validate_files {
  my $self = shift;

  $self->_validate_barcodes_match();
  $self->_validate_wells_sequential();

  return;
}

sub _validate_barcodes_match {
  my $self = shift;

  if ($self->files->map(sub { return $_->{'barcode'} })->uniq->size > 1) {
    croak q/Barcodes on files do not match/;
  }

  return;
}

=head2 _validate_wells_sequential

  Example    : $self->_validate_wells_sequential()
  Description: Loops through each file checking that the wells are "sequential" (wells are
               column ordered from source plate)

               i.e. If File 1's "end well" is G1, File 2's "start well" should be H1
  Returntype : Undef

=cut
sub _validate_wells_sequential {
  my $self = shift;

  my $number_of_files = $self->files->size();

  # $number_of_files - 2 because we don't need to check the last file
  # (and because arrays are 0 based)
  foreach (0..($number_of_files - 2)) {
    my $current_file = $self->files->[$_];
    my $next_file    = $self->files->[$_ + 1];

    my $index_of_end_well = $self->_find_index($current_file->{'end_well'});
    my $start_well_on_next_file = $self->_wells->[$index_of_end_well + 1];

    if ($next_file->{'start_well'} ne $start_well_on_next_file) {
      croak qq/There is a problem with the sequence of wells given in the file names/;
    }
  }

  return;
}


1;

__END__

=head1 NAME

wtsi_clarity::ics::agilent::file_validator

=head1 SYNOPSIS

  my $validator = wtsi_clarity::ics::agilent::file_validator->new(file_names => $file_names);
  my $wells = $validator->files_by_well();

  $wells == {
    A1: {
      file: '12345678_A1_D2',
      wells: ['A1', 'B1']
    },
    B1: {
      ...
    }
  }

=head1 DESCRIPTION

  Takes a list of file paths that should have the structure <<Barcode>>_<<StartWell>>_<<EndWell>> e.g.
  1235678_A1_D2. The module performs a number of checks against them:

    - There are no more than 4 files

    - That the barcodes match
        e.g. (12345678_A1_D2, 12345678_E2_H3) - PASS
             (12345678_A1_D2, 87654321_E2_H3) - FAIL

    - There is no gap in the sequence of wells
        e.g. (12345678_A1_D2, 12345678_E2_H3) - PASS
             (12345678_A1_D2, 12345678_F2_H3) - FAIL

    - There is no overlap in the sequence
        e.g. (12345678_A1_D2, 12345678_E2_H3) - PASS
             (12345678_A1_D2, 12345678_B2_H3) - FAIL

=head1 SUBROUTINES/METHODS

=head2 BUILD - Constructor

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>cs24@sanger.ac.ukE<gt>

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
