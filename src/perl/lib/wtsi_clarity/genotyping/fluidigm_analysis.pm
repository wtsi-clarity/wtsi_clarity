package wtsi_clarity::genotyping::fluidigm_analysis;

use Moose;
use Carp;
use wtsi_clarity::util::csv::factory;

our $VERSION = '0.0';

### Constructor args ...

has 'file_format' => (
  is => 'ro',
  isa => 'Str',
  required => 0,
  default => sub { return q{BioMark Sample Format V1.0}},
);

has 'sample_plate' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has 'barcode' => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has 'description' => (
  is         => 'ro',
  isa        => 'Str',
  required   => 0,
  lazy_build => 1,
);

# If the description has not been set via a constructor arg,
# use the same value as the sample_plate
sub _build_description {
  my $self = shift;
  return $self->sample_plate;
}

has 'plate_type' => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
  default  => sub { return 'SBS96' },
);

has 'samples' => (
  is       => 'ro',
  isa      => 'ArrayRef[HashRef]',
  required => 1,
);

### Post Constructor...

sub BUILD {
  my $self = shift;

  if (!$self->_validSamples()) {
    croak 'Samples passed to Fluidigm Analysis are not valid';
  }
}

sub _validSamples {
  my $self = shift;

  foreach my $sample (@{$self->samples}) {
    if (!exists $sample->{'well_location'} || !exists $sample->{'sample_name'}) {
      return 0;
    }
  }

  return 1;
}

### File generation and data munging...

has '_textfile' => (
  is         => 'ro',
  isa        => 'wtsi_clarity::util::textfile',
  init_arg   => undef,
  lazy_build => 1,
  handles    => {
    'saveas' => 'saveas',
    'content' => 'content',
  },
);
sub _build__textfile {
  my $self = shift;

  my $textfile = wtsi_clarity::util::csv::factory
    ->new
    ->create(
      type    => 'fluidigm_writer',
      headers => $self->_headers,
      data    => $self->_data,
    );

  # Unshift the file meta data so it's above the table
  unshift @{$textfile->content}, @{$self->_file_metadata};

  return $textfile;
}

has '_file_metadata' => (
  is         => 'ro',
  isa        => 'ArrayRef[Str]',
  init_arg   => 1,
  lazy_build => 1,
);
sub _build__file_metadata {
  my $self = shift;
  return [
    'File Format, '  . $self->file_format  . ', , ',
    'Sample Plate, ' . $self->sample_plate . ', , ',
    'Barcode ID, '   . $self->barcode      . ', , ',
    'Description, '  . $self->description  . ', , ',
    'Plate Type, '   . $self->plate_type   . ', , ',
    ' , , , ',
  ];
}

has '_headers' => (
  is       => 'ro',
  isa      => 'ArrayRef',
  init_arg => undef,
  default  => sub { return ['Well Location', 'Sample Name', 'Sample Concentration', 'Sample Type'] },
);

has '_data' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  init_arg => undef,
  lazy_build => 1,
);
sub _build__data {
  my $self = shift;
  my @_data = map { $self->_format_row($_) } @{$self->samples};
  return \@_data;
}

sub _format_row {
  my ($self, $row) = @_;
  my $concentration = $row->{'sample_concentration'} || q{};
  my $sample_type   = $row->{'sample_type'} || 'Unknown';

  my %row = (
    'Well Location' => $row->{'well_location'},
    'Sample Name'   => $row->{'sample_name'},
    'Sample Concentration' => $concentration,
    'Sample Type' => $sample_type,
  );

  return \%row;
}

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm_analysis

=head1 SYNOPSIS

  my $file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => 'DN382334Q',
    barcode      => 123456789,
    description  => 'Just a great plate' # Defaults to sample_plate if not present
    plate_type   => 'SBS96' # not required
    samples      => [{
      well_location => 'A01',
      sample_name   => '272222DY78988098',
      sample_concentration => '', # Left blank if not present
      sample_type   => ''         # Unknown if not present
    }]
  );

  $file->saveas('monkey.csv');

=head1 DESCRIPTION

  Generates a csv file using the CSV factory for loading into the Fluidigm analysis software

=head1 SUBROUTINES/METHODS

=head2 BUILD

  Runs validation on the samples that have passed in after object initialisation

=head2 saveas

  Pass it a file location and it will write the file there

=head2 content

  RW content of the file

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::util::csv::factory;

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Genome Research Ltd.

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
