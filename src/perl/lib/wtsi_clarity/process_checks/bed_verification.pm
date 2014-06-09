package wtsi_clarity::process_checks::bed_verification;

use Moose;
use Carp;

our $VERSION = '0.0';

has 'config' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 1,
);

sub verify {
  my ($self, $process_name, $robot_id, $mappings) = @_;

  if (!exists ($self->config->{$process_name})) {
    croak qq/bed verification config can not be found for process $process_name/;
  }

  my $process = $self->config->{$process_name};

  if ($process->{robot} ne $robot_id) {
    croak qq/robot id incorrect for process $process_name/;
  }

  foreach my $input_mapping (@{$mappings}) {

    my $source = $input_mapping->{source};
    my $config_mapping = $self->_find_mapping_by_bed($process, $source->[0]->{bed});

    return 0 if $self->_verify_mapping($input_mapping, $config_mapping) == 0;
  }

  return 1;
}

sub _verify_mapping {
  my ($self, $input_mapping, $config_mapping) = @_;

  my $sources = $input_mapping->{source};
  my $config_sources = $config_mapping->{source};
  my $destination = $input_mapping->{destination};
  my $config_destination = $config_mapping->{destination};

  if ($self->_verify_beds($sources, $config_sources) && $self->_verify_beds($destination, $config_destination)) {
    return 1;
  } else {
    return 0;
  }
}

sub _verify_beds {
  my ($self, $input, $config) = @_;
  foreach my $bed (@{$input}) {
    my $matching_config_bed = $self->_find_matching_config_bed($bed, $config);

    if ($matching_config_bed == 0) {
      return 0;
    }

    if ($bed->{barcode} != $matching_config_bed->{barcode}) {
      croak qq/ Barcode for source bed $bed->{bed} is different to config /;
    }
  }

  return 1;
}

sub _find_matching_config_bed {
  my ($self, $bed, $config) = @_;

  foreach my $config_bed (@{$config}) {
    if ($config_bed->{bed} == $bed->{bed}) {
      return $config_bed;
    }
  }

  return 0;
}

sub _find_mapping_by_bed {
  my ($self, $process, $bed) = @_;

  foreach my $mapping (@{ $process->{mappings} }) {
    foreach my $source (@{ $mapping->{source} }) {
      if ($source->{bed} == $bed) {
        return $mapping;
      }
    }
  }
  # Hopefully would not get to here...
  croak qq/ Could not find bed $bed for this process /;
}

1;

__END__

=head1 NAME

wtsi_clarity::process_checks::bed_verification

=head1 SYNOPSIS

  # $config comes from a JSON file (decoded into a Perl object)
  $c = wtsi_clarity::process_checks::bed_verification->new(config => $config);
  $c->verify($process_name, $robot_id, $mappings);

=head1 DESCRIPTION
  Provides the method verify to determine whether beds have been scanned into 
  the correct place on a machine.

=head1 SUBROUTINES/METHODS

=head2 verify - returns a bool dependent on plates being correctly placed in beds 

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

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
