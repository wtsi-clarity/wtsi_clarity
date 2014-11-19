package wtsi_clarity::epp::isc::pool_beckman_creator;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use wtsi_clarity::util::textfile;
use wtsi_clarity::util::beckman;

our $VERSION = '0.0';

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_ID_PATH            => q(/prc:process/@limsid);
Readonly::Scalar my $DEFAULT_PLATE_NAME_PREFIX  => q(PCRXP);
Readonly::Scalar my $DEFAULT_SOURCE_EAN13       => q(1234567890123);
Readonly::Scalar my $DEFAULT_SOURCE_BARCODE     => q(DN367818);
Readonly::Scalar my $DEFAULT_SOURCE_STOCK       => q(DN365894);
Readonly::Scalar my $DEFAULT_DEST_EAN13         => q(1234567890124);
Readonly::Scalar my $DEFAULT_DEST_BARCODE       => q(DN369421);
## use critic

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
  my $files = [];
  return $self->_beckman->get_file($self->internal_csv_output);
}

has 'internal_csv_output' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 0,
  lazy_build => 1,
);
sub _build_internal_csv_output {
  my $self = shift;

  my ($pool_calculator_result, $warnings) = $self->_get_result_from_pool_calculator;

  my @plate_names = keys %{$pool_calculator_result};
  my $sample_nr = 1;
  my @rows;

  foreach my $plate_name (@plate_names) {
    my @dest_wells = keys $pool_calculator_result->{$plate_name};
    while ( my ($dest_well, $analytes) = each $pool_calculator_result->{$plate_name}) {
      foreach my $analyte_data (@{$analytes}) {
        my @row_content = c->new(@{$self->_beckman->headers})
                          ->reduce( sub {
                            my $method = $self->_get_method_from_header($b);
                            my $value = $self->$method($dest_well, $analyte_data, $sample_nr);
                            $a->{$b} = $value;
                            $a;
                          }, {});
        push @rows, @row_content;
        $sample_nr++;
      }
    }
  }

  return \@rows;
}

has '_file_path' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__file_path {
  my $self = shift;
  my $process_id  = $self->find_elements_first_value($self->process_doc, $PROCESS_ID_PATH);
  my $path = join q{/}, $self->config->robot_file_dir->{'pre_capture_lib_pooling'}, $process_id;
  my $ext  = '.csv';
  return $path . $ext;
}

override 'run' => sub {
  my $self= shift;
  super();

  $self->_beckman_file->saveas(q{./}.$self->_file_path);

  return;
};

sub _get_method_from_header {
  my ($self,$header) = @_;
  my $name = _get_method_name_from_header($header);
  if ($self->can($name)) {
    return $name;
  }
  return q{_get_not_implemented_yet};
}

sub _get_method_name_from_header {
  my ($header) = @_;
  $header =~ s/^\s+|\s+$//gxms; # trim
  $header =~ s/\s/_/gxms;       # replace space with underscore
  return q{_get_} . lc $header; # lower case
}

sub _get_result_from_pool_calculator {
  my $self = shift;

  return wtsi_clarity::epp::isc::pool_calculator->new(
      process_url => $self->process_url
    )
    ->get_volume_calculations_and_warnings();
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

sub _get_source_well {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $analyte_data->{'source_well'};
}

sub _get_destination_ean13 {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_DEST_EAN13;
}

sub _get_destination_barcode {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $DEFAULT_DEST_BARCODE;
}

sub _get_destination_well {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $dest_well;
}

sub _get_source_volume {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $analyte_data->{'Volume'};
}

sub _get_not_implemented_yet {
  my ($self, $sample_id) = @_;
  return qq{*} ; #qq{Not implemented yet};
}
## use critic

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pool_beckman_creator

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::pool_beckman_creator->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a Beckman NX8 robot driver file and upload it on the server as an output for the step.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item Mojo::Collection

=item wtsi_clarity::util::textfile

=item wtsi_clarity::util::beckman

=back

=head1 AUTHOR

Author: Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
