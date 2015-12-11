package wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator;

use Moose;
use Carp;
use Readonly;
use POSIX qw/strftime/;
use List::MoreUtils qw/any/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_BY_WELL => qq{art:details/art:artifact[location/value='%s']};
Readonly::Scalar my $AVERAGE_MOLARITY_UDF => q{./udf:field[@name="Average Molarity"]};
Readonly::Scalar my $THREE_THOUSAND => 3000;
Readonly::Scalar my $MAX_VOLUME => 180;
Readonly::Scalar my $FILE_NAME => q{%s_rearray_to_hyb_%s_%s.csv};
Readonly::Scalar my $MAX_SMALL_TIP_VOLUME => 50;
## use critic

extends 'wtsi_clarity::epp';

with qw/
        wtsi_clarity::epp::isc::beckman_file_generator
        wtsi_clarity::util::clarity_elements
        wtsi_clarity::epp::generic::roles::stamper_common
       /;

override 'run' => sub {
  my $self= shift;
  super();

  $self->_beckman_file->saveas(q{./} . $self->beckman_file_name);

  return;
};

sub _build_internal_csv_output {
  my $self = shift;
  my $row_number = 1;
  my @rows = map { $self->row($_->{'well'}, $_, $row_number++) } @{$self->_sorted_input_analytes};
  return \@rows;
};

sub build_beckman_file_name {
  my $self = shift;
  return sprintf $FILE_NAME, $self->_output_container_signature, $self->_tip_size, $self->_formatted_date;
}

sub _sorted_input_analytes {
  my $self = shift;
  my @analytes = ();

  foreach my $well (@{$self->init_96_well_location_values}) {
    my $analyte = $self->process_doc->input_artifacts
                                    ->findnodes(sprintf $ARTIFACT_BY_WELL, $well)->pop;
    next if !defined $analyte;

    my $molarity = $analyte->findvalue($AVERAGE_MOLARITY_UDF);
    push @analytes, { 'well' => $well, 'molarity' => $molarity };
  }

  return \@analytes;
}

## no critic(Subroutines::ProhibitUnusedPrivateSubroutines)
# Source well and destination well are the same
sub _get_source_well {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $self->_well($analyte_data);
}

sub _get_destination_well {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  return $self->_well($analyte_data);
}
## use critic

sub _well {
  my ($self, $analyte_data) = @_;
  my $well = $analyte_data->{'well'};
  $well =~ s/://sxmg;
  return $well;
}

has '_well_volumes' => (
  is => 'ro',
  isa => 'ArrayRef',
  traits => ['Array'],
  default => sub {[]},
  handles => { '_add_volume' => 'push' },
);

sub _get_source_volume {
  my ($self, $dest_well, $analyte_data, $sample_nr) = @_;
  my $volume = $THREE_THOUSAND / $analyte_data->{'molarity'};
  $self->_add_volume($volume = ($volume > $MAX_VOLUME) ? $MAX_VOLUME : $volume);
  return $volume;
}

sub _output_container_signature {
  my $self = shift;
  my $output_container_limsid = $self->process_doc->plate_io_map->[0]->{'dest_plate'};
  return $self->process_doc->get_container_signature_by_limsid($output_container_limsid);
}

sub _tip_size {
  my $self = shift;
  return (any { $_ >= $MAX_SMALL_TIP_VOLUME } @{$self->_well_volumes}) ? 'p250' : 'p50';
}

sub _formatted_date {
  return strftime("%d%m%g", localtime);
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::rearray_to_hyb_beckman_creator->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a Beckman NX8 robot driver file and uploads it on the server as an output for the step.

=head1 SUBROUTINES/METHODS

=head2 build_beckman_file_name

  Creates the name to save the file as

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item POSIX

=item List::MoreUtils

=item wtsi_clarity::epp

=item wtsi_clarity::epp::isc::beckman_file_generator

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::epp::generic::roles::stamper_common

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
