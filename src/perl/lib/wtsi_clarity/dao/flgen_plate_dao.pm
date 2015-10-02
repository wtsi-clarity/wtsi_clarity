package wtsi_clarity::dao::flgen_plate_dao;

use strict;
use warnings;
use Moose;
use Readonly;
use Carp;
use POSIX qw(strftime);

use wtsi_clarity::dao::containertypes_dao;
use wtsi_clarity::dao::sample_dao;
use wtsi_clarity::dao::study_dao;
use wtsi_clarity::util::clarity_validation qw/flgen_bc/;

with 'wtsi_clarity::dao::base_dao';

# In the ATTRIBUTES hash: an element's key is the attribute name
# and the element's value is the XPATH to get the attribute's value

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash  my %ATTRIBUTES  => {
  id_flgen_plate_lims => q{/con:container/@limsid},
  plate_barcode_lims  => q{/con:container/name},
  plate_barcode       => q{/con:container/name},
};

Readonly::Scalar my $TYPE_URI_PATH => q{/con:container/type/@uri};
Readonly::Scalar my $ARTIFACT_PATH      => q{/con:container/placement/@limsid};
Readonly::Scalar my $ARTIFACT_LOCATION  => q{/art:artifact/location/value};
Readonly::Scalar my $SAMPLE_LIMSID_PATH => q{/art:artifact/sample/@limsid};

Readonly::Scalar my $LITTLE_PLATE       => 96;
Readonly::Scalar my $BIG_PLATE          => 192;
## use critic

our $VERSION = '0.0';

has '+resource_type' => (
  default     => 'containers',
);

has '+attributes' => (
  default     => sub {
    return \%ATTRIBUTES;
  },
);

has 'type' => (
  traits     => [ 'DoNotSerialize' ],
  is         => 'ro',
  isa        => 'wtsi_clarity::dao::containertypes_dao',
  lazy_build => 1,
);

sub _build_type {
  my $self = shift;
  my $type_uri = $self->findvalue($TYPE_URI_PATH);
  my $type_limsid;

  if ($type_uri =~ /containertypes\/(\d+)$/sxm) {
    $type_limsid = $1;
  } else {
    croak 'Containertype does not have an id';
  }

  return wtsi_clarity::dao::containertypes_dao->new(lims_id => $type_limsid);
}

has 'plate_size' => (
  is => 'ro',
  isa => 'Int',
  lazy_build => 1,
);

sub _build_plate_size {
  my $self = shift;
  return $self->type->plate_size;
}

sub flgen_well_position {
  my ($self, $loc, $nb_rows, $nb_cols) = @_;

  if (!$loc) {
    croak 'Well address should be given';
  }

  my ($letter, $number) = $loc =~ /^([A-P]+):(\d{1,2})$/xms;

  if (!$letter || !$number) {
    croak "Well location format '$loc' is not recognised";
  }

  if ($number > $nb_cols) {
    croak "Invalid column address '$number' for $nb_rows:$nb_cols layout";
  }

  ## no critic(CodeLayout::ProhibitParensWithBuiltins)
  my $letter_as_number = ord( uc ($letter) ) - ord('A');
  ## use critic

  if ($letter_as_number > $nb_rows) {
    croak "Invalid row address '$letter' for $nb_rows:$nb_cols layout";
  }

  my %well_formats = (
    $LITTLE_PLATE => "%02d",
    $BIG_PLATE    => "%03d",
  );

  my $format = $well_formats{$self->plate_size}
    or croak "Unknown well format for " . $self->plate_size . " size plate";

  return 'S' . sprintf $format, ($letter_as_number * $nb_cols) + $number;
}

has 'wells' => (
  is => 'ro',
  isa => 'ArrayRef',
  lazy_build => 1,
);

sub _build_wells {
  my $self = shift;
  my @artifact_ids = $self->findnodes($ARTIFACT_PATH)->to_literal_list();
  my @wells = map {
    $self->_build_well($_)
  } @artifact_ids;
  return \@wells;
}

sub _build_well {
  my ($self, $limsid) = @_;
  my %well = ();
  my $artifact_doc = $self->_get_artifact($limsid);

  $well{'last_updated'} = strftime('%Y-%m-%Od %H:%M:%S', localtime);

  # well_label
  my $location = $artifact_doc->findvalue($ARTIFACT_LOCATION);
  $well{'well_label'} = $self->flgen_well_position($location, $self->type->y_dimension_size, $self->type->x_dimension_size);

  # cost_code and sample_uuid
  my $sample_limsid = $artifact_doc->findvalue($SAMPLE_LIMSID_PATH);
  my $sample = $self->_get_sample($sample_limsid);
  $well{'sample_uuid'} = $sample->name;

  # study
  my $study = $self->_get_study($sample->project_limsid);
  $well{'study_id'} = $study->id;
  $well{'cost_code'} = $study->cost_code;

  return \%well;
}

sub _get_artifact {
  my ($self, $limsid) = @_;
  return $self->_get_xml('artifacts', $limsid);
}

sub _get_sample {
  my ($self, $limsid) = @_;
  return wtsi_clarity::dao::sample_dao->new(lims_id => $limsid);
}

sub _get_study {
  my ($self, $limsid) = @_;
  return wtsi_clarity::dao::study_dao->new(lims_id => $limsid);
}

has 'plate_size_occupied' => (
  is => 'ro',
  isa => 'Int',
  lazy_build => 1,
);

sub _build_plate_size_occupied {
  my $self = shift;
  return scalar @{$self->wells};
}

sub _validate_plate_barcode {
  my ($self, $plate_bc) = @_;

  my $validation = flgen_bc($plate_bc);

  if ($validation->failed) {
    croak $validation->error_message;
  }

  return;
}

around 'init' => sub {
  my $next = shift;
  my $self = shift;

  $self->$next();
  $self->wells;
  $self->plate_size;
  $self->plate_size_occupied;

  $self->_validate_plate_barcode($self->plate_barcode);

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::dao::flgen_plate_dao

=head1 SYNOPSIS
  my $flgen_plate_dao = wtsi_clarity::dao::flgen_plate_dao->new(lims_id => "1234");
  $flgen_plate_dao->to_message();

=head1 DESCRIPTION
 A data object representing a container.
 Its data coming from the container XML file returned from Clarity API.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose;

=item Readonly;

=item Carp;

=item wtsi_clarity::dao::containertypes_dao;

=item wtsi_clarity::dao::sample_dao;

=item wtsi_clarity::dao::study_dao;

=item wtsi_clarity::dao::base_dao;

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
