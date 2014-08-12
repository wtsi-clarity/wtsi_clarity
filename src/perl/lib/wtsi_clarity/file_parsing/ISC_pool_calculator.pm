package wtsi_clarity::epp::sequencing::ISC_pool_calculator;

use Moose;
use Carp;
use Readonly;

use POSIX;
use Text::CSV;
use List::MoreUtils qw/ uniq /;

Readonly::Scalar my $CONCENTRATION_NORMALISER => 5;

our $VERSION = '0.0';

sub _filecontent_to_hash {
  # transforms the csv content into a hash.
  # the samples are duplicated. we pack them together.
  my ($data, $barcode) = @_;

  my $csv_parser = Text::CSV->new();
  shift $data;

  my $output = {};
  my @header = qw/Well_Label Sample_Name Peak_Count Total_Conc Molarity/;

  foreach my $line (@{$data}) {
    chomp $line;
    $csv_parser->parse($line);
    my @values = $csv_parser->fields();
    shift @values;
    my %hash;
    # create a hash with the headers as key, and trim the values;
    @hash{@header} = map { _cleanup_key($_) } @values;

    # only add this hash to the output if there's a molarity.
    if ($hash{'Molarity'}) {
      $hash{'Sample_Name'} =~ /(\w\d)_.*/xms or croak qq{Impossible to parse the file. The sample name is not correct ($line);};
      my $real_label = $1;
      if ($output->{ $real_label }){
        $output->{ $real_label }{'Molarity_2'} = $hash{'Molarity'};
      } else {
        $hash{'Molarity_1'} = $hash{'Molarity'};
        delete $hash{'Molarity'};
        delete $hash{'Well_Label'};
        $output->{ $real_label } = \%hash;
      }
    }
  }
  my $hashed_data = { $barcode => $output };
  return $hashed_data;
}

sub _cleanup_key {
  my $key = shift;
  $key =~ s/^\s+|\s+$//xmsg ;
  return $key;
}

sub _transform_mapping {
  # transforming an array of hashes describing the plexing
  # into something a bit better for the rest of the module
  my ($mappings) = @_;
  my $new_mappings = {};
  foreach my $mapping (@{$mappings}) {
    push @{$new_mappings->{ $mapping->{ 'dest_plate' } }->{ $mapping->{ 'dest_well' } } },
       {
         'source_plate' => $mapping->{ 'source_plate' },
         'source_well'  => $mapping->{ 'source_well'  },
       };
  }
  return $new_mappings;
}

sub _update_concentrations_for_all_pools {
  my ($mappings, $data, $min_volume, $max_volume, $max_total) = @_;
  my $warnings = {};
  while (my ($plate_name, $plate) = each %{$mappings} ) {
    $warnings->{$plate_name} = {};
    while (my ($well_name, $dest_well) = each %{$plate} ) {
      my $warns= _update_concentrations_for_one_pool($dest_well, $data, $min_volume, $max_volume, $max_total);
      $warnings->{$plate_name}->{$well_name} = $warns;
    }
  }
  return $warnings;
}

sub  _update_concentrations_for_one_pool {
  my ($dest_well, $data, $min_volume, $max_volume, $max_total) = @_;
  my $min;
  my $warnings = [];

  # get the molarity per sample, and get the lowest one
  foreach my $source (@{$dest_well}) {
    my $source_plate = $source->{ 'source_plate' };
    my $source_well  = $source->{ 'source_well'  };
    my $mol1 = $data->{$source_plate}->{$source_well}->{'Molarity_1'};
    my $mol2 = $data->{$source_plate}->{$source_well}->{'Molarity_2'};
    if (!defined $mol1) { $mol1 = 0 ; }
    if (!defined $mol2) { $mol2 = 0 ; }
    my $mol = $CONCENTRATION_NORMALISER * ($mol1 + $mol2) / 2 ;
    $source->{'Molarity'} = $mol;
    if ( $mol > 0 ) {
      if (!defined $min) { $min = $mol; }
      if ($min > $mol)   { $min = $mol; }
    }
  }

  # if no minimum molarity, then there's no data to compute for this pool
  if (!defined $min || 0 >= $min) {
    push @{$warnings}, qq{Warning: Too many concentration data missing! This well cannot be configured!};
    return $warnings;
  }

  # get the required volume for equi-molarity
  my $total = 0.0;
  foreach my $source (@{$dest_well}) {
    my $mol = $source->{'Molarity'};
    if (0 >= $mol) {
      # special case: no data -> we set the volume to zero
      my $source_plate = $source->{ 'source_plate' };
      my $source_well  = $source->{ 'source_well'  };
      push @{$warnings}, qq{Warning: concentration data missing for [ plate $source_plate | well $source_well ]};
      $source->{'Volume'} = 0.0;
    } else {
      # normal case: we make sure that he least concentrated well is the most used
      my $ratio = $mol / $min;
      $source->{'Volume'} = $max_volume / $ratio;
      # and get the total volume
      $total += $source->{'Volume'};
    }
  }

  # if the total volume is too big, we scale everything down.
  my $ratio = $max_total / $total ;
  foreach my $source (@{$dest_well}) {
    if ($total > $max_total) {
      $source->{'Volume'} = $source->{'Volume'} * $ratio;
    }
    if ($source->{'Volume'} < $min_volume) {
      # if, once scaled, it's too low, we put a warning.
      my $source_plate = $source->{ 'source_plate' };
      my $source_well  = $source->{ 'source_well'  };
      my $v = $source->{'Volume'};
      push @{$warnings}, qq{Warning: volume required from [ plate $source_plate | well $source_well ] if too low ( = $v )!};
    }
  }

  return $warnings;
}

sub get_volume_calculations_and_warnings
{
  my ($self) = @_;

  my $hashed_data    = _filecontent_to_hash($self->data, $self->original_plate_barcode);
  my $hashed_mapping = _transform_mapping($self->mapping);

  my $warnings       = _update_concentrations_for_all_pools($hashed_mapping,
                                                            $hashed_data,
                                                            $self->min_volume,
                                                            $self->max_volume,
                                                            $self->max_total_volume);
  return ($hashed_mapping, $warnings);
}

has 'data' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 1,
);

has 'mapping' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 1,
);

has 'min_volume' => (
  is => 'ro',
  isa => 'Num',
  required => 1,
);
has 'max_volume' => (
  is => 'ro',
  isa => 'Num',
  required => 1,
);
has 'max_total_volume' => (
  is => 'ro',
  isa => 'Num',
  required => 1,
);
has 'original_plate_barcode' => (
  is => 'ro',
  isa => 'Num',
  required => 1,
);


1;

__END__

=head1 NAME

wtsi_clarity::epp::sequencing::ISC_pool_calculator

=head1 SYNOPSIS

  my $calc = wtsi_clarity::epp::sequencing::ISC_pool_calculator->new( data             => $array,
                                                                      mapping          => $mapping,
                                                                      min_volume       => 5,
                                                                      max_volume       => 50,
                                                                      max_total_volume => 200,
                                                                      original_plate_barcode => 1234567890123456,
                                                                    );
  $calc->get_volume_calculations_and_warnings();

=head1 DESCRIPTION

  offers a method to calculate the volumes needed to accomplish the pooling.

=head1 SUBROUTINES/METHODS

=head2  new - Creates the instance.

        $data is the content of the caliper CSV file.

        $original_plate_barcode is the name/barcode of the plate associated with the $data. This is NOT the
        name of the caliper plate

        $mapping is an array of hashes, describing the plexing. Each one of them describing in which pool, each well will be added.
        [
          { 'source_plate' => '0001', 'source_well' =>  'A1', 'dest_plate' => '1000', 'dest_well' =>  'A1'},
          { 'source_plate' => '0001', 'source_well' =>  'B1', 'dest_plate' => '1000', 'dest_well' =>  'A1'},
          { 'source_plate' => '0002', 'source_well' =>  'A1', 'dest_plate' => '1000', 'dest_well' =>  'A1'},
          ...
        ]

        $min_volume is the minimum volume that can be extracted from the source

        $max_volume is the maximum volume that can be extracted from the source

        $max_total_volume is the maximum total volume that can be pooled, i.e. the sum of the volumes extracted for one pool

=head2  get_volume_calculations_and_warnings - Calculates the volumes needed to accomplish the pooling.
        Returns the calculations data, as well as an array of potentials errors discovered


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item POSIX;

=item Text::CSV;

=item List::MoreUtils qw/ uniq /;

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

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

