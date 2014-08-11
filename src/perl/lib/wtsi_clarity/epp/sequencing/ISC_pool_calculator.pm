package wtsi_clarity::epp::sequencing::ISC_pool_calculator;

use Moose;
use Carp;
use Readonly;
use Data::Dumper;

use POSIX;
use Text::CSV;
use List::MoreUtils qw/ uniq /;

sub _filecontent_to_hash
{
  my ($data) = @_;
  # print Dumper $data;

  my $csv_parser = Text::CSV->new();
  shift $data;

  my $output = {};
  my @header = qw/Well_Label Sample_Name Peak_Count Total_Conc Molarity/;

  foreach my $line (@$data) {
    chomp $line;
    $csv_parser->parse($line);
    my @values = $csv_parser->fields();
    shift @values;
    my %hash;
    # create a hash with the headers as key, and trim the values;
    @hash{@header} = map { $_ =~ s/^\s+|\s+$//g ; $_ } @values;

    # only add this hash to the output if there's a molarity.
    if ($hash{'Molarity'}) {
      $hash{'Sample_Name'} =~ /(\w\d)_.*/xms;
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
  # print Dumper $output;
  return $output;
}

# sub _clean_label
# {
#   my ($label) = @_;
#   if ($label =~ /\w0\d/) {
#     $label =~ s/0//;
#   }
#   return $label;
# }

# sub build_pool_map
# {
#   my ($type) = @_;
#   if ($type eq q{384_8_in_1} ) {

#     my $letters = map { chr(ord('A') + $_-1) } (1..$NB_ROWS_96);
#     my $t = map  $j = $_; return map ($_.$j) $letters; ) (1..$NB_ROWS_96)
#     print Dumper $t;

#     # for my $i (1..$NB_ROWS_384) {
#     #   for my $j (1..$NB_COLS_384) {
#     #     my $letter = chr(ord('A') + $i-1);
#     #     # print "$letter$j\n";
#     #   }
#     # }


#     return {};
#   }
#   croak qq{Unknown '$type' pool map!};
# }

sub _transform_mapping 
{
  my ($mappings) = @_;
  my $new_mappings = {};
  foreach my $mapping (@$mappings) {
    my $dest_plate   = $mapping->{ 'dest_plate'   };
    my $dest_well    = $mapping->{ 'dest_well'    };
    my $source_plate = $mapping->{ 'source_plate' };
    my $source_well  = $mapping->{ 'source_well'  };

    if ( not $new_mappings->{$dest_plate} ) {
      $new_mappings->{$dest_plate} = {};
    }
    if ( not $new_mappings->{$dest_plate}->{$dest_well} ) {
      $new_mappings->{$dest_plate}->{$dest_well} = [];
    }
    my $details = { 'source_plate' => $source_plate, 'source_well' => $source_well };
    push $new_mappings->{$dest_plate}->{$dest_well}, $details;

  }
  return $new_mappings;
}



sub _update_concentrations_for_all_pools
{
  my $warnings = {};
  my ($mappings, $data, $min_volume, $max_volume, $max_total) = @_;
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
  foreach my $source (@$dest_well) {
    my $source_plate = $source->{ 'source_plate' };
    my $source_well  = $source->{ 'source_well'  };
    my $mol1 = $data->{$source_plate}->{$source_well}->{'Molarity_1'};
    my $mol2 = $data->{$source_plate}->{$source_well}->{'Molarity_2'};
    $mol1 = 0 if (!defined $mol1);
    $mol2 = 0 if (!defined $mol2);
    my $mol = 5 * 0.5 * ($mol1 + $mol2) ;
    $source->{'Molarity'} = $mol;
    if ( $mol > 0 ) {
      if (!defined $min) { $min = $mol; }
      if ($min > $mol)   { $min = $mol; }
    }
  }

  if (!defined $min || 0 >= $min) {
    push $warnings, qq{Warning: Too many concentration data missing! This well cannot be configured!};
    return $warnings;
  }

  my $total = 0.0;
  foreach my $source (@$dest_well) {
    my $mol = $source->{'Molarity'};
    if (0 >= $mol) {
      my $source_plate = $source->{ 'source_plate' };
      my $source_well  = $source->{ 'source_well'  };
      push $warnings, qq{Warning: concentration data missing for [ plate $source_plate | well $source_well ]};
      $source->{'Volume'} = 0.0;
    } else {
      my $ratio = $mol / $min;
      $source->{'Volume'} = $max_volume / $ratio;
      $total += $source->{'Volume'};
    }
  }


  my $ratio = $max_total / $total ;
  foreach my $source (@$dest_well) {
    if ($total > $max_total) {
      $source->{'Volume'} = $source->{'Volume'} * $ratio;
    }
    if ($source->{'Volume'} < $min_volume) {
      my $source_plate = $source->{ 'source_plate' };
      my $source_well  = $source->{ 'source_well'  };
      my $v = $source->{'Volume'};
      push $warnings, qq{Warning: volume required from [ plate $source_plate | well $source_well ] if too low ( = $v )!};
    }
  }


  return $warnings;
}


sub main
{
  my (@data, $mapping) = @_;

  my $hashed_data = _filecontent_to_hash(@data);

  return ;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sequencing::ISC_pool_calculator

=head1 SYNOPSIS

  wtsi_clarity::epp::sequencing::ISC_pool_calculator->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

????  Creates a pdf document describing the plates, and upload it on the server, as an output for each output plate.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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

