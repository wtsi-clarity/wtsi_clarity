package wtsi_clarity::genotyping::fluidigm::result_set;

use Moose;
use Readonly;
use Carp;

use wtsi_clarity::util::types;

Readonly::Scalar my $DATA_DIRECTORY_NAME => q{Data};
Readonly::Scalar my $EXPECTED_TIF_TOTAL => 3;

our $VERSION = '0.0';

has 'directory' => (
  is       => 'ro',
  isa      => 'WtsiClarityDirectory',
  required => 1,
  writer   => '_directory',
);

has 'data_directory' => (
  is     => 'ro',
  isa    => 'WtsiClarityDirectory',
  writer => '_data_directory',
);

has 'export_file' => (
  is     => 'ro',
  isa    => 'WtsiClarityReadableFile',
  writer => '_export_file',
);

has 'tif_files' => (
  is     => 'ro',
  isa    => 'ArrayRef[WtsiClarityReadableFile]',
  writer => '_tif_files',
);

has 'fluidigm_barcode' => (
  is     => 'ro',
  isa    => 'Str',
  writer => '_fluidigm_barcode',
);

sub BUILD {
  my ($self) = @_;

  # find barcode (identical to directory name, by definition)
  my @terms = split /\//sxm, $self->directory;
  if ($terms[-1] eq q{}) { pop @terms; } # in case of trailing / in path
  $self->_fluidigm_barcode(pop @terms);

  $self->_data_directory($self->directory . q{/} . $DATA_DIRECTORY_NAME);

  # find .tif files
  my @tif = glob($self->data_directory.'/*\.{tif,tiff}');
  if (@tif!=$EXPECTED_TIF_TOTAL) {
    croak "Should have exactly $EXPECTED_TIF_TOTAL .tif files in " . $self->data_directory;
  }

  $self->_tif_files(\@tif);

  # look for export .csv file
  $self->_export_file($self->directory .q{/}. $self->fluidigm_barcode .'.csv');

  return;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm::result_set

=head1 SYNOPSIS

  my $result_set = wtsi_clarity::genotyping::fluidigm::result_set->new(
    directory => 'path/to/fluidigm/analysis/dir'
  );

=head1 DESCRIPTION

  Takes a directory that is a result of running Fluidigm Analysis software. Creates
  data_directory, export_file, tif_files, fluidigm_barcode if possible.

=head1 SUBROUTINES/METHODS

=head2 BUILD

  Constructor sets all attributes

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
