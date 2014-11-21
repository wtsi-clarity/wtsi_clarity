package wtsi_clarity::process_checks::bed_verifier;

use Moose;
use Carp;
use Readonly;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ROBOT_BARCODE_PATH => q[ /prc:process/udf:field[@name="Robot ID"] ];
## use critic

# Required
has 'config' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 1,
);

sub verify {
  my ($self, $process) = @_;

  $self->_verify_step_config($process);
  $self->_verify_robot_config($process);
  $self->_verify_bed_barcodes($process);

  $self->_verify_plate_mapping($process, $self->_plate_mapping($process));

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
  my ($self, $process) = @_;

  if (!exists ($self->config->{ $process->step_name })) {
    croak qq/Bed verification config can not be found for process / . $process->step_name;
  } else {
    return $self->_set__step_config($self->config->{ $process->step_name });
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
  my ($self, $process) = @_;

  my $robot_bc = $process->process_doc->findvalue($ROBOT_BARCODE_PATH);

  if ($robot_bc eq q{}) {
    croak qq[Robot barcode must be set for bed verification\n];
  }

  if (!exists $self->_step_config->{$robot_bc}) {
    croak qq[Robot $robot_bc has not been configured for step ] . $process->step_name;
  }

  return $self->_set__robot_config($self->_step_config->{$robot_bc});
}

sub _verify_bed_barcodes {
  my ($self, $process) = @_;

  foreach my $bed (@{$process->beds}) {
    if (!exists $self->_robot_config->{$bed->bed_name}) {
      croak $bed->bed_name . ' can not be found in config for specified robot';
    }

    if ($self->_robot_config->{$bed->bed_name} ne $bed->barcode) {
      croak $bed->bed_name . ' barcode (' . $bed->barcode . ') differs from config bed barcode (' . $self->_robot_config->{$bed->bed_name} . ')';
    }
  }

  return 1;
}

sub _plate_mapping {
  my ($self, $process) = @_;
  my @plate_mapping = ();

  foreach my $plate (@{$process->plates}) {
    next if $plate->is_output;

    my $plate_name = $plate->plate_name;
    $plate_name =~ s/Input/Output/gsm;

    my $output_plates = $self->_find_output_plate($process, $plate_name);

    foreach my $output_plate (@{$output_plates}) {
      push @plate_mapping, { source_plate => $plate->barcode, dest_plate => $output_plate->barcode };
    }
  }

  return \@plate_mapping;
}

sub _find_output_plate {
  my ($self, $process, $plate_name) = @_;
  my @output_plates = grep { $_->plate_name eq $plate_name } @{$process->plates};
  return \@output_plates;
}

sub _verify_plate_mapping {
  my ($self, $process, $plate_mapping) = @_;

  foreach my $plate_io (@{$process->plate_io_map_barcodes}) {
    my $matches = grep { ($_->{'source_plate'} == $plate_io->{'source_plate'} && $_->{'dest_plate'} == $plate_io->{'dest_plate'}) } @{$plate_mapping};
    if ($matches != 1) {
      croak "Expected source plate " . $plate_io->{'source_plate'} . " to be paired with destination plate " . $plate_io->{'dest_plate'};
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

=head2 verify($process)

  Pass in an EPP process and it will verify the robot id, the barcodes of the beds are correct,
  and the plates in a process are in the correct bed positions.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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
