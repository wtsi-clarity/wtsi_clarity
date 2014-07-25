package wtsi_clarity::epp::sm::attach_dtx_file;

use Moose;
use Carp;
use Readonly;
use File::Copy;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $FIRST_INPUT_URI_PATH => q(/prc:process/input-output-map[1]/input/@uri);
Readonly::Scalar my $CONTAINER_URI_PATH => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $RAW_DATA_NAME => q(_ Pico-green assay run_AllRawData*);
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';

our $VERSION = '0.0';

has 'new_pico_assay_file_name' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

has 'new_standard_file_name' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

has '_standard_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__standard_barcode {
  my $self = shift;

  my $standard_barcode = $self->find_udf_element($self->process_doc, 'Standard Barcode');

  croak 'Standard barcode has not been set' if (!defined $standard_barcode);

  return $standard_barcode->textContent;
}

has '_container_barcode' => (
  isa => 'Str',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__container_barcode {
  my $self = shift;

  my $container_hash = $self->fetch_targets_hash($FIRST_INPUT_URI_PATH, $CONTAINER_URI_PATH);
  my $container_doc = (values %{$container_hash})[0];
  my $container_barcode = $container_doc->findvalue('/con:container/name');

  croak 'Container barcode is not set' if ($container_barcode eq q{});

  return $container_barcode;
}

has '_file_prefix' => (
  isa => 'Str',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__file_prefix {
  my $self = shift;

  my $file_prefix = join q{-}, $self->_standard_barcode, $self->_container_barcode;

  return $file_prefix;
}

has '_dtx_file_path' => (
  isa => 'Str',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__dtx_file_path {
  my $self = shift;
  my $dir = $self->config->robot_file_dir->{'sm_pico_green'};

  my $file_name =  $self->_file_prefix . $RAW_DATA_NAME;

  return qq{"$dir/$file_name"};
}

has '_standard_file_path' => (
  isa => 'Str',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__standard_file_path {
  my $self = shift;
  my $dir = $self->config->robot_file_dir->{'sm_pico_green'};

  my $file_name =  $self->_standard_barcode . $RAW_DATA_NAME;

  return qq{"$dir/$file_name"};
};

sub _get_file_path {
  my $self = shift;
  my $file_path_pattern = shift;

  my @file_list = glob $file_path_pattern;

  if (scalar @file_list > 1) {
    croak 'Multiple files are available for ' . $file_path_pattern;
  }

  if (scalar @file_list == 0) {
    croak 'Could not find file ' . $file_path_pattern;
  }

  my $file = shift @file_list;

  return $file;
}

sub _get_files {
  my $self = shift;
  return ($self->_get_file_path($self->_dtx_file_path), $self->_get_file_path($self->_standard_file_path));
}

sub attach_files_to_process {
  my $self = shift;
  my ($dtx_file, $standard_file) = $self->_get_files();

  copy ($dtx_file, q{./} . $self->new_pico_assay_file_name)
    or croak sprintf 'Failed to copy %s', $dtx_file;

  copy ($standard_file, q{./} . $self->new_standard_file_name)
    or croak sprintf 'Failed to copy %s', $standard_file;

  return;
}

override 'run' => sub {
  my $self = shift;
  super();

  $self->attach_files_to_process();

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::attach_dtx_file

=head1 SYNOPSIS

  use wtsi_clarity::epp::sm::attach_dtx_file;
  wtsi_clarity::epp::sm::attach_dtx_file->new(process_url => 'http://some.com/process/1234XM')->run();

=head1 DESCRIPTION

 Finds the DTX data file for a Pico Assay plate

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback

=head2 attach_files_to_process
  Copies the dtx file and the standard plate file to the current directory

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item File::Copy

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::util::clarity_elements_fetcher_role_util

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
