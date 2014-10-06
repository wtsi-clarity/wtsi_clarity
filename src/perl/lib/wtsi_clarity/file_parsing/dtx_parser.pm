package wtsi_clarity::file_parsing::dtx_parser;

use Moose;
use Readonly;
use XML::LibXML;

Readonly::Scalar my $ALL_ROWS          => qq{/ss:Workbook/ss:Worksheet[\@ss:Name='Raw_P_1_Seq_1_Cycle1']/ss:Table/ss:Row};
Readonly::Scalar my $CELL_DATA_INDEX_1 => qq{.//ss:Cell[\@ss:Index=1]/ss:Data/text()};
Readonly::Scalar my $CELL_DATA_INDEX_2 => qq{.//ss:Cell[\@ss:Index=2]/ss:Data/text()};
Readonly::Scalar my $CELL_DATA_INDEX_3 => qq{.//ss:Cell[\@ss:Index=3]/ss:Data/text()};

our $VERSION = '0.0';

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
sub parse {
  my ($self, $file_path) = @_;
  my $results = {};

  my $xmldoc = XML::LibXML->load_xml(
    location => $file_path,
  );

  my $root = $xmldoc->getDocumentElement();#
  my $xpc = XML::LibXML::XPathContext->new($root);
  $xpc->registerNs('ss', 'urn:schemas-microsoft-com:office:spreadsheet');

  for(0..95) {
    my $i = $_;
    my $well_str;
    my $datarow1_measurement1;
    my $datarow1_measurement2;
    my $datarow2_measurement1;
    my $datarow2_measurement2;
    for(0..2) {
      my $j = $_;
      my $n = $i*4 + $j + 8;
      my $filter = "[\@ss:Index=$n]";
      my @rows = $xpc->findnodes( qq{$ALL_ROWS$filter} );
      if (0 == $j){ # well
        $well_str = ($rows[0]->findnodes($CELL_DATA_INDEX_1))[0];
        $well_str =~ s/Well\s//xms;
        $well_str =~ s/[.]/:/xms;
      }
      if (1 == $j){ # datarow 1
        $datarow1_measurement1 = ($rows[0]->findnodes( $CELL_DATA_INDEX_2 ))[0]->nodeValue;
        $datarow1_measurement1 =~ s/Well\s//xms;
        $datarow1_measurement1 =~ s/[.]/:/xms;
        $datarow1_measurement2 = ($rows[0]->findnodes( $CELL_DATA_INDEX_3 ))[0]->nodeValue;
        $datarow1_measurement2 =~ s/Well\s//xms;
        $datarow1_measurement2 =~ s/[.]/:/xms;
      }
      if (2 == $j){ # datarow 2
        $datarow2_measurement1 = ($rows[0]->findnodes( $CELL_DATA_INDEX_2 ))[0]->nodeValue;
        $datarow2_measurement1 =~ s/Well\s//xms;
        $datarow2_measurement1 =~ s/[.]/:/xms;
        $datarow2_measurement2 = ($rows[0]->findnodes( $CELL_DATA_INDEX_3 ))[0]->nodeValue;
        $datarow2_measurement2 =~ s/Well\s//xms;
        $datarow2_measurement2 =~ s/[.]/:/xms;
      }
    }
    $results->{$well_str} = { d1m1=>$datarow1_measurement1, d1m2=>$datarow1_measurement2, d2m1=>$datarow2_measurement1, d2m2=>$datarow2_measurement2};
  }
  return $results;
}

1;

__END__

=head1 NAME

wtsi_clarity::file_parsing::dtx_parser

=head1 SYNOPSIS

  my $dtx_parser = wtsi_clarity::file_parsing::dtx->new();
  my $dtx_file = $dtx_parser->parser('/path/to/dtx/file.xml');

=head1 DESCRIPTION

  Module parse the xml file produced by a Pico DTX and return a useful hash.

=head1 SUBROUTINES/METHODS

=head2 parse - Takes file path of the DTX file as an argument. Parses this file and retuns a hash.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item XML::LibXML

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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

