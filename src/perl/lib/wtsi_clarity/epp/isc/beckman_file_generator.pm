package wtsi_clarity::epp::isc::beckman_file_generator;

use Moose::Role;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use wtsi_clarity::util::textfile;
use wtsi_clarity::util::beckman;

our $VERSION = '0.0';

Readonly::Scalar my $DEFAULT_PLATE_NAME_PREFIX  => q(PCRXP);
Readonly::Scalar my $DEFAULT_SOURCE_EAN13       => q(Not used);
Readonly::Scalar my $DEFAULT_SOURCE_BARCODE     => q(Not used);
Readonly::Scalar my $DEFAULT_SOURCE_STOCK       => q(Not used);
Readonly::Scalar my $DEFAULT_DEST_EAN13         => q(Not used);
Readonly::Scalar my $DEFAULT_DEST_BARCODE       => q(Not used);

with qw/wtsi_clarity::util::csv::report_common/;

has 'beckman_file_name' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
  lazy     => 1,
  builder  => 'build_beckman_file_name',
);

has '_beckman' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::beckman',
  required => 0,
  lazy_build => 1,
);
sub _build__beckman {
  my $self = shift;
  return wtsi_clarity::util::beckman->new();
}

has '_beckman_file' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::textfile',
  required => 0,
  lazy_build => 1,
);
sub _build__beckman_file {
  my $self = shift;
  return $self->_beckman->get_file($self->internal_csv_output);
}

has 'internal_csv_output' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 0,
  lazy_build => 1,
);

sub row {
  my ($self, $dest_well, $analyte_data, $sample_num) = @_;
  return c->new(@{$self->_beckman->headers})
    ->reduce( sub {
      my $method = $self->get_method_from_header($b);
      my $value = $self->$method($dest_well, $analyte_data, $sample_num);
      $a->{$b} = $value;
      $a;
    }, {});
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutines)
sub _get_sample {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $sample_nr;
}

sub _get_name {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_PLATE_NAME_PREFIX . q{1};
}

sub _get_source_ean13 {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_SOURCE_EAN13;
}

sub _get_source_barcode {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_SOURCE_BARCODE;
}

sub _get_source_stock {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_SOURCE_STOCK;
}

sub _get_destination_barcode {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_DEST_BARCODE;
}

sub _get_source_well {
  my ($self) = @_;
  return $self->_get_not_implemented_yet;
}

sub _get_destination_ean13 {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_DEST_EAN13;
}

sub _get_destination_well {
  my ($self) = @_;
  return $self->_get_not_implemented_yet;
}

sub _get_source_volume {
  my ($self) = @_;
  return $self->_get_not_implemented_yet;
}

sub _get_not_implemented_yet {
  my ($self, $sample_id) = @_;
  return qq{*} ; #qq{Not implemented yet};
}
## use critic

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::beckman_file_generator

=head1 SYNOPSIS

  package wtsi_clarity::epp::isc::some_process_that_needs_to_generate_a_beckman_robot_file
  with 'wtsi_clarity::epp::isc::beckman_file_generator'


=head1 DESCRIPTION

  Moose role that can help build a Beckman file

=head1 SUBROUTINES/METHODS

=head2 row
  Goes through each header in the Beckman file and calls a '_get_{header}' for each of the columns

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::textfile

=item wtsi_clarity::util::beckman

=item wtsi_clarity::util::csv::report_common

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
