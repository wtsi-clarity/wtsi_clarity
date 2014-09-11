package wtsi_clarity::util::csv::factories::calliper_csv_reader;

use Moose;
use Carp;
use Data::Dumper;
use wtsi_clarity::util::textfile;
use Mojo::Collection;
use Text::CSV;

our $VERSION = '0.0';

sub build {
  # transforms the csv content into a hash.
  # the samples are duplicated. we pack them together.
  my ($self, %args) = @_;


  my $headers      = $args{'headers'}      || croak qq{Requires headers!};
  my $file_content = $args{'file_content'} || croak qq{Requires a file content!};
  my $barcode      = $args{'barcode'}      || croak qq{Requires the barcode of the original plate!};

  my $csv_parser = Text::CSV->new();
  shift $file_content;

  my $output = {};

  foreach my $line (@{$file_content}) {
    chomp $line;
    $csv_parser->parse($line);
    my @values = $csv_parser->fields();
    shift @values;
    my %hash;
    # create a hash with the headers as key, and trim the values;
    @hash{ @{$headers} } = map { _cleanup_key($_) } @values;

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


1;

__END__

=head1 NAME

wtsi_clarity::util::csv::factories::calliper_csv_reader

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::csv::factories::calliper_csv_reader->build(
                                headers       => [ 'a', 'b' ],
                                file_content  => [ 'a,b', '1,2', '4.0, 5'],
                                barcode       => '1234567890123456');

=head1 DESCRIPTION

  Class able to output the content given as an argument as a CSV text

=head1 SUBROUTINES/METHODS

=head2 build

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::util::textfile

=item Mojo::Collection

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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