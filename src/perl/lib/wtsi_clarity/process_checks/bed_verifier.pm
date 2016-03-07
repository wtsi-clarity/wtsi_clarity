package wtsi_clarity::process_checks::bed_verifier;

use Moose;
use Carp;
use Readonly;
use List::MoreUtils qw/all/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ROBOT_BARCODE_PATH => q[ /prc:process/udf:field[@name="Robot ID"] ];
Readonly::Scalar my $INPUT_ONLY_ERROR => q[Expected source plate %s];
Readonly::Scalar my $INPUT_OUTPUT_ERROR => q[Expected source plate %s to be paired with destination plate %s];
Readonly::Scalar my $BED_FIELDS => q{/prc:process/udf:field[starts-with(@name, "Bed") and contains(@name, "Plate")]};
Readonly::Scalar my $PLATE_FIELDS => q{/prc:process/udf:field[starts-with(@name, "Input Plate") or starts-with(@name, "Output Plate")]};
## use critic

has 'config' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
  );

has '_input_only' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 0,
    init_arg => 'input_only',
    default  => 0,
  );

has 'epp' => (
    isa      => 'wtsi_clarity::epp',
    is       => 'ro',
    required => 0,
  );

sub verify {
  my ($self) = @_;

  $self->_verify_barcodes_filled_out();

  $self->_verify_static_barcodes();
  $self->_verify_plate_mapping($self->_plate_mapping);

  return 1;
}

# The verification entry for this process type.
has '_step_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build__step_config',
  );
sub _build__step_config {
  my ($self) = @_;

  my $step_name = $self->epp->step_name;

  if (!exists ($self->config->{$step_name})) {
    croak qq/Bed verification config can not be found for process $step_name/;
  } else {
    return $self->config->{$step_name};
  }
}

# The verification entry for this robot
has '_robot_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build__robot_config',
  );
sub _build__robot_config {
  my ($self) = @_;

  my $robot_bc = $self->epp->process_doc->findvalue($ROBOT_BARCODE_PATH);

  if ($robot_bc eq q{}) {
    croak qq[Robot barcode must be set for bed verification];
  }

  if (!exists $self->_step_config->{$robot_bc}) {
    croak qq[Robot $robot_bc has not been configured for step ].$self->epp->step_name;
  } else {
    return $self->_step_config->{$robot_bc};
  }
}

has 'beds' => (
    is         => 'ro',
    isa        => 'WtsiClarityProcessBeds',
    lazy_build => 1,
    coerce     => 1,
  );
sub _build_beds {
  my $self = shift;
  return $self->epp->findnodes($BED_FIELDS);
}

has 'plates' => (
    is         => 'ro',
    isa        => 'WtsiClarityPlates',
    lazy_build => 1,
    coerce     => 1,
  );
sub _build_plates {
  my $self = shift;
  return $self->epp->findnodes($PLATE_FIELDS);
}

# List of plates that are mentioned in fields starting with "Bed"
has '_bed_plate_names' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    lazy    => 1,
    builder => '_build__bed_plate_names',
  );
sub _build__bed_plate_names {
  my ($self) = @_;

  my @plates = map {
    $_->plate_name;
  } @{$self->beds};

  return \@plates;
}

sub _verify_barcodes_filled_out {
  my ($self) = @_;

  # Verify that all plate fields are mentioned in at least one bed field name
  my %plate_names = map { $_->plate_full_name => 1 } @{$self->plates};

  my @unfilled_plates = grep {
    !exists $plate_names{$_}
  } @{$self->_bed_plate_names};

  if (scalar @unfilled_plates) {
    croak 'Not all plate barcodes have been filled out.';
  }

  # Verify that each plate has a bed mentioning it
  my %bed_plates = map { $_ => 1 } @{$self->_bed_plate_names};

  my @unfilled_beds = grep {
    !exists($bed_plates{$_->plate_full_name})
  } @{$self->plates};

  if (scalar @unfilled_beds) {
    croak 'Not all bed barcodes have been filled out.';
  }
}

sub _verify_static_barcodes {
  my ($self) = @_;

  # Check there is at least one udf field begining with "Bed" filled in.
  if (scalar @{$self->beds} == 0) {
    croak 'Could not find any bed barcodes, please scan in at least one bed udf field';
  }

  for my $bed (@{$self->beds}) {
    # Check that each field starting with "Bed" has an entry in the config
    if (!exists $self->_robot_config->{$bed->bed_name}) {
      croak $bed->bed_name.' can not be found in config for specified robot';
    }
    # Check that each field starting with "Bed" has the correct value as specified by the config
    if ($self->_robot_config->{$bed->bed_name} ne $bed->barcode) {
      croak $bed->bed_name.' barcode ('.$bed->barcode.') differs from config bed barcode ('.$self->_robot_config->{$bed->bed_name}.')';
    }
  }

  for my $plate (@{$self->plates}) {
    # Check that each plate field that has a config entry is correct
    my $plate_name = $plate->plate_full_name;
    my $config_value = $self->_robot_config->{$plate->plate_full_name};
    my $actual_value = $plate->barcode;

    if ($config_value) {
      if ($config_value ne $actual_value) {
        croak "$plate_name ($actual_value) differs from the config barcode ($config_value)";
      }
    }
  }

  return 1;
}

sub _find_plates_by_name {
  my ($self, $plate_name) = @_;

  my @plates = grep {
    $_->plate_name eq $plate_name
  } @{$self->plates};

  return \@plates;
}

# A list of source/dest plate pairs, (just source plates if _input_only is true.
has '_plate_mapping' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    lazy    => 1,
    builder => '_build__plate_mapping',
  );
sub _build__plate_mapping {
  my ($self) = @_;

  my @plate_mapping = ();

  for my $plate (@{$self->plates}) {
    if ($plate->is_input) {
      my $plate_name = $plate->plate_name;
      $plate_name =~ s/Input/Output/gsm;

      # Find the corrosonding output plate.
      my $output_plates = $self->_find_plates_by_name($plate_name);

      if (scalar @{$output_plates} > 0) {
        for my $output_plate (@{$output_plates}) {
          push @plate_mapping, {source_plate => $plate->barcode, dest_plate => $output_plate->barcode};
        }
      } else {
        push @plate_mapping, {source_plate => $plate->barcode}
      }
    }
  }
  return \@plate_mapping;
}

sub _verify_plate_mapping {
  my ($self, $plate_mapping) = @_;

  for my $plate_io (@{$self->epp->process_doc->plate_io_map_barcodes}) {
    my $matches;

    if ($self->_input_only) {
      $matches = grep {
        $_->{'source_plate'} eq $plate_io->{'source_plate'}
      } @{$plate_mapping};

      if ($matches != 1) {
        croak sprintf $INPUT_ONLY_ERROR, $plate_io->{'source_plate'};
      }

    } else {
      $matches = grep {
        $_->{'source_plate'} eq $plate_io->{'source_plate'} && $_->{'dest_plate'} eq $plate_io->{'dest_plate'}
      } @{$plate_mapping};

      if ($matches != 1) {
        croak sprintf $INPUT_OUTPUT_ERROR, $plate_io->{'source_plate'}, $plate_io->{'dest_plate'};
      }
    }
  }

  return 1;
}

1;

__END__

=head1 NAME

wtsi_clarity::process_checks::bed_verifier

=head1 SYNOPSIS

  # $config comes from a JSON file (decoded into a Perl hash)
  $c = wtsi_clarity::process_checks::bed_verifier->new(config => $config);
  $c->verify($process_name, $robot_id, $mappings);

=head1 DESCRIPTION
  Provides the verify method to determine whether beds have been scanned into
  the correct place on a machine.

=head1 SUBROUTINES/METHODS

=head2 verify($epp)

  Pass in an EPP process and it will verify the robot id, the barcodes of the beds are correct,
  and the plates in a process are in the correct bed positions.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item List::MoreUtils

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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
