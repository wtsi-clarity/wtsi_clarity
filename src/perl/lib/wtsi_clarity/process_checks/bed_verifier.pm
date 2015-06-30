package wtsi_clarity::process_checks::bed_verifier;

use Moose;
use Carp;
use Readonly;
use List::MoreUtils qw/all/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ROBOT_BARCODE_PATH => q[ /prc:process/udf:field[@name="Robot ID"] ];
Readonly::Scalar my $INPUT_ONLY_ERROR   => q[Expected source plate %s];
Readonly::Scalar my $INPUT_OUTPUT_ERROR => q[Expected source plate %s to be paired with destination plate %s];
## use critic

# Required
has 'config' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 1,
);

# Optional
has '_input_only' => (
  is       => 'ro',
  isa      => 'Bool',
  required => 0,
  init_arg => 'input_only',
  default  => 0,
);

sub verify {
  my ($self, $epp) = @_;

  $self->_verify_step_config($epp);
  $self->_verify_robot_config($epp);
  $self->_verify_bed_barcodes($epp);

  $self->_verify_plate_mapping($epp, $self->_plate_mapping($epp));

  return 1;
}

has '_step_config' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { {} },
  writer => '_set__step_config',
);

sub _verify_step_config {
  my ($self, $epp) = @_;

  if (!exists ($self->config->{ $epp->step_name })) {
    croak qq/Bed verification config can not be found for process / . $epp->step_name;
  } else {
    return $self->_set__step_config($self->config->{ $epp->step_name });
  }
}

has '_robot_config' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub { {} },
  writer => '_set__robot_config',
);

sub _verify_robot_config {
  my ($self, $epp) = @_;

  my $robot_bc = $epp->process_doc->findvalue($ROBOT_BARCODE_PATH);

  if ($robot_bc eq q{}) {
    croak qq[Robot barcode must be set for bed verification\n];
  }

  if (!exists $self->_step_config->{$robot_bc}) {
    croak qq[Robot $robot_bc has not been configured for step ] . $epp->step_name;
  }

  return $self->_set__robot_config($self->_step_config->{$robot_bc});
}

has '_bed_names' => (
  isa        => 'ArrayRef',
  is         => 'rw',
  required => 0,
  writer => "_set_bed_names",
);
sub _create_bed_names {
  my ($self, $epp) = @_;

  my @bed_names = ();

  foreach my $bed (@{$epp->beds}) {

    push @bed_names, $bed->plate_name;
  }

  return $self->_set_bed_names(\@bed_names);
}

has '_plate_name_value_mapping' => (
  is => 'rw',
  isa => 'HashRef',
  required => 0,
  writer => "_set_plate_name_value_mapping",
);
sub _create_plate_name_value_mapping {
  my ($self, $epp) = @_;
  my %plate_name_value_map = ();

  foreach my $plate (@{$epp->plates}) {
    $plate_name_value_map{$plate->plate_full_name} = $plate->barcode;
  }

  return $self->_set_plate_name_value_mapping(\%plate_name_value_map);
}

# TODO ke4 uncomment it when fixing #433
# has '_number_of_input_beds' => (
#   is => 'rw',
#   isa => 'Int',
#   writer => "_set_number_of_input_beds",
# );
# sub _create_number_of_input_beds {
#   my ($self, $epp) = @_;
#   my $input_bed_count = 0;

#   foreach my $bed (@{$epp->beds}) {
#     if ($bed->is_input) {
#       $input_bed_count++;
#     }
#   }

#   return $self->_set_number_of_input_beds($input_bed_count);
# }

sub _verify_bed_barcodes {
  my ($self, $epp) = @_;

  my %plate_name_value_mapping = %{$self->_create_plate_name_value_mapping($epp)};

  if (scalar @{$epp->beds} == 0 ) {
    croak 'The barcode of the bed(s) are empty. Please, add barcode value(s) to the form.';
  }

  # TODO ke4: Fix this bug later #433
  # We should get the input container from the proper place
  # if ($self->_create_number_of_input_beds($epp) != $epp->step_doc->input_container_count) {
  #   croak 'Not all bed(s) barcode has been filled. Please, add all bed barcode value(s) to the form.';
  # }

  foreach my $bed (@{$epp->beds}) {
    if (!exists $self->_robot_config->{$bed->bed_name}) {
      croak $bed->bed_name . ' can not be found in config for specified robot';
    }

    if ($self->_robot_config->{$bed->bed_name} ne $bed->barcode) {
      croak $bed->bed_name . ' barcode (' . $bed->barcode . ') differs from config bed barcode (' . $self->_robot_config->{$bed->bed_name} . ')';
    }

    if (! $plate_name_value_mapping{$bed->plate_name}) {
      croak 'Not all input/output plate barcode has been filled out.';
    }
  }

  return 1;
}

sub _plate_mapping {
  my ($self, $epp) = @_;
  my @plate_mapping = ();

  $self->_create_bed_names($epp);

  foreach my $plate (@{$epp->plates}) {

    my %bed_names = map { $_ => 1 } @{$self->_bed_names};

    if(!exists($bed_names{$plate->plate_full_name})) {
      croak 'Not all bed barcode has been filled out.';
    }

    if ($self->_input_only) {
      push @plate_mapping, { source_plate => $plate->barcode }
    } else {
      next if $plate->is_output;

      my $plate_name = $plate->plate_name;
      $plate_name =~ s/Input/Output/gsm;

      my $output_plates = $self->_find_output_plate($epp, $plate_name);

      foreach my $output_plate (@{$output_plates}) {
        push @plate_mapping, { source_plate => $plate->barcode, dest_plate => $output_plate->barcode };
      }
    }
  }

  return \@plate_mapping;
}

sub _find_output_plate {
  my ($self, $epp, $plate_name) = @_;
  my @output_plates = grep { $_->plate_name eq $plate_name } @{$epp->plates};
  return \@output_plates;
}

my $source_plate_match = _plate_match('source_plate');
my $dest_plate_match   = _plate_match('dest_plate');

sub _plate_match {
  my ($plate_name) = @_;

  return sub {
    my ($a, $b) = @_;
    return $a->{$plate_name} == $b->{$plate_name};
  }
}

sub _match_all {
  my ($self, $plate_mapping, $plate_io, @verifiers) = @_;
  return grep { $self->_match_verifiers($_, $plate_io, @verifiers) } @{$plate_mapping};
}

sub _match_verifiers {
  my ($self, $mapping, $plate_io, @verifiers) = @_;
  return all { $_->($mapping, $plate_io) } @verifiers;
}

sub _verify_plate_mapping {
  my ($self, $epp, $plate_mapping) = @_;

  foreach my $plate_io (@{$epp->process_doc->plate_io_map_barcodes}) {
    my $matches;

    if ($self->_input_only) {
      $matches = $self->_match_all($plate_mapping, $plate_io, $source_plate_match);

      if ($matches != 1) {
        croak sprintf $INPUT_ONLY_ERROR, $plate_io->{'source_plate'};
      }

    } else {
      $matches = $self->_match_all($plate_mapping, $plate_io, $source_plate_match, $dest_plate_match);

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
