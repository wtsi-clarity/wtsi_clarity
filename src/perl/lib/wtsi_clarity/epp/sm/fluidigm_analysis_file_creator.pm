package wtsi_clarity::epp::sm::fluidigm_analysis_file_creator;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::genotyping::fluidigm_analysis;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar our $ARTIFACT_BY_SAMPLE_VALUE => q{/art:details/art:artifact[location/value="%s"]};
Readonly::Scalar our $SAMPLE_LIMSID            => q{./sample/@limsid};
Readonly::Scalar our $CONTAINER_TYPE_URI       => q{/con:container/type/@uri};
Readonly::Scalar our $CONTAINER_X_SIZE         => q{/ctp:container-type/x-dimension/size};
Readonly::Scalar our $CONTAINER_Y_SIZE         => q{/ctp:container-type/y-dimension/size};
Readonly::Scalar our $STA_PROCESS_NAME         => q{Fluidigm STA Plate Creation (SM)};
Readonly::Scalar our $NO_TEMPLATE_CONTROL      => q{NTC};

has 'filename' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

override 'run' => sub {
  my $self = shift;
  super();

  my $fluidigm_analysis_file = wtsi_clarity::genotyping::fluidigm_analysis->new(
    sample_plate => $self->_sample_plate,
    barcode      => $self->_barcode,
    samples      => $self->_samples,
  );

  $fluidigm_analysis_file->saveas(q{./} . $self->filename);

  return;
};

has '_sta_plate_creation_process' => (
  is => 'ro',
  isa => 'wtsi_clarity::clarity::process',
  required => 0,
  lazy_build => 1,
);

sub _build__sta_plate_creation_process {
  my $self = shift;

  my $processes = $self->process_doc->find_parent($STA_PROCESS_NAME, $self->process_url);

  if (scalar @{$processes} == 0) {
    croak "Can not find STA Plate";
  }

  my $process_xml = $self->fetch_and_parse($processes->[0]);

  return wtsi_clarity::clarity::process->new(xml => $process_xml, parent => $self);
}

has ['_sample_plate', '_barcode'] => (
  is         => 'ro',
  isa        => 'Str',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build__sample_plate {
  my $self = shift;
  return $self->_sta_plate_creation_process->plate_io_map_barcodes->[0]->{'source_plate'};
}

sub _build__barcode {
  my $self = shift;
  return $self->process_doc->plate_io_map_barcodes->[0]->{'source_plate'};
}

has '_samples' => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  init_arg => undef,
  lazy_build => 1,
);

sub _build__samples {
  my $self = shift;
  my @samples = ();

  my $chr_num = ord('A') + $self->_container_size->{'y_dimension'} - 1;
  my $big_row = chr $chr_num;

  for (1..$self->_container_size->{'x_dimension'}) {
    foreach my $column ('A'..$big_row) {

      my $clarity_well = join q{:}, $column, $_;
      my $fluidigm_well = $column . sprintf '%02d', $_;

      my %sample = ();

      my $artifact_list = $self->_sta_plate_creation_process
                          ->input_artifacts
                          ->findnodes(sprintf $ARTIFACT_BY_SAMPLE_VALUE, $clarity_well);

      $sample{'well_location'} = $fluidigm_well;

      if ($artifact_list->size == 0) {
        $sample{'sample_name'} = '[ Empty ]';

        # H12 is always 'NTC', cause that's what the Fluidigm software wants
        if ($sample{'well_location'} eq 'H12') {
          $sample{'sample_type'} = $NO_TEMPLATE_CONTROL;
        }
      } elsif ($artifact_list->size == 1) {
        $sample{'sample_name'} = $artifact_list->pop->findvalue($SAMPLE_LIMSID);
      } else {
        croak "STA Plate has " . $artifact_list->size . " wells at " . $clarity_well;
      }

      push @samples, \%sample;
    }
  }

  return \@samples;
}

has '_container_size' => (
  is         => 'ro',
  isa        => 'HashRef',
  init_arg   => undef,
  lazy_build => 1,
);
sub _build__container_size {
  my $self = shift;

  my $container_limsid = $self->_sta_plate_creation_process->plate_io_map->[0]->{'source_plate'};
  my $container = $self->fetch_and_parse(join q{/}, $self->config->clarity_api->{'base_uri'}, 'containers', $container_limsid);
  my $container_type = $self->fetch_and_parse($container->findvalue($CONTAINER_TYPE_URI));

  my %container_size = (
    'x_dimension' => $container_type->findvalue($CONTAINER_X_SIZE),
    'y_dimension' => $container_type->findvalue($CONTAINER_Y_SIZE),
  );

  return \%container_size;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::fluidigm_analysis_file_creator

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::fluidigm_analysis_file_creator->new(
    process_url => 'http://my.com/processes/3345',
    filename    => '123456789.csv'
  )->run();

=head1 DESCRIPTION

  Extracts data from a process and generates a CSV file for use with the Fluidigm software

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::genotyping::fluidigm_analysis;

=item wtsi_clarity::epp

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
