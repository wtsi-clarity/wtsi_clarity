package wtsi_clarity::file_parsing::dtx_concentration_calculator;

use Moose;
use Carp;
use wtsi_clarity::util::clarity_elements;
use Readonly;

Readonly::Scalar my $CV_LIMIT => 10.0;

Readonly::Scalar my $ALL_ROWS          => qq{/ss:Workbook/ss:Worksheet[\@ss:Name='Raw_P_1_Seq_1_Cycle1']/ss:Table/ss:Row};
Readonly::Scalar my $CELL_DATA_INDEX_1 => qq{.//ss:Cell[\@ss:Index=1]/ss:Data/text()};
Readonly::Scalar my $CELL_DATA_INDEX_2 => qq{.//ss:Cell[\@ss:Index=2]/ss:Data/text()};
Readonly::Scalar my $CELL_DATA_INDEX_3 => qq{.//ss:Cell[\@ss:Index=3]/ss:Data/text()};


our $VERSION = '0.0';

has 'standard_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
);

has 'plateA_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
);

has 'plateB_doc' => (
  is => 'ro',
  isa => 'XML::LibXML::Document',
);

has 'standard_fluorescence' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has 'plateA_fluorescence' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has 'plateB_fluorescence' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has 'cvs' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
sub _build_cvs {
  my ($self) = @_;
  my $results = {};
  while (my ($well, $data) = each %{$self->standard_fluorescence} ) {
    my $average_fluorescence = 0.5 *( $self->plateA_fluorescence->{$well} + $self->plateB_fluorescence->{$well} );

    my $x1 = ($self->plateA_fluorescence->{$well} - $average_fluorescence) ** 2;
    my $x2 = ($self->plateB_fluorescence->{$well} - $average_fluorescence) ** 2;

    $results->{$well} = sqrt($x1 + $x2) * 100 / $average_fluorescence;
  }
  return $results;
}

sub get_analysis_results {
  my ($self) = @_;
  my $whole_data = {
    'standard' => $self->standard_fluorescence,
    'plateA' => $self->plateA_fluorescence,
    'plateB' => $self->plateB_fluorescence,
    'cv' => $self->cvs,
   };
  my $fit_data = _get_standard_coefficients($whole_data);
  my $results = {};

  while (my ($well, $data) = each %{$self->standard_fluorescence} ) {
    $results->{$well} = { 'concentration' => - 1.0,
                          'cv' => - 1.0,
                          'status' => 'unknown',
                        };
    my $average_fluorescence = ($self->plateA_fluorescence->{$well} + $self->plateB_fluorescence->{$well}) * 0.5;
    $results->{$well}->{'concentration'} = ($average_fluorescence - $fit_data->{'intercept'}) / $fit_data->{'slope'};
    $results->{$well}->{'cv'}            = $self->cvs->{$well};
    $results->{$well}->{'status'}        = _get_status($self->cvs->{$well});
    $results->{$well}->{'plateA_fluorescence'} = $self->plateA_fluorescence->{$well};
    $results->{$well}->{'plateB_fluorescence'} = $self->plateB_fluorescence->{$well};

  }

  return $results;
}

sub _get_status {
  my $cv = shift;
  if ($cv > $CV_LIMIT) {
    return 'Failed';
  }
  return 'Passed';
}

sub _get_standard_coefficients {
  my ($data) = @_;
  my $res = {};

  $res = _get_standard_intermediate_coefficients($data);

  my $x   = $res->{'X'};
  my $xsq = $res->{'Xsq'};
  my $y   = $res->{'Y'};
  my $ysq = $res->{'Ysq'};
  my $xy  = $res->{'XY'};
  my $xsq_by_ysq = $res->{'Xsq_by_Ysq'};
  my $x_by_ysq   = $res->{'X_by_Ysq'};
  my $y_by_ysq   = $res->{'Y_by_Ysq'};
  my $xy_by_ysq  = $res->{'XY_by_Ysq'};
  my $one_by_ysq   = $res->{'one_by_Ysq'};

  my $slope = ($y_by_ysq - $xy_by_ysq * $one_by_ysq / $x_by_ysq) / ($x_by_ysq - $xsq_by_ysq * $one_by_ysq / $x_by_ysq) ;
  my $intercept = ($y_by_ysq - $x_by_ysq * $slope) / $one_by_ysq;
  $res->{'slope'} = $slope;
  $res->{'intercept'} = $intercept;

  return $res;
}

sub _get_average {
  my ($data, $row) = @_;
  my $acc = 0;
  for (9..12) {
    $acc += $data->{'standard'}->{"$row:$_"};
  }
  return $acc * 0.25 ;
}

sub _get_std_deviation {
  my ($data, $average, $row) = @_;
  my $acc = 0;
  for (9..12) {
    $acc += ($data->{'standard'}->{"$row:$_"} - $average)**2;
  }
  return sqrt ( $acc / 3.0 ) ;
}

sub _get_standard_intermediate_coefficients {
  my ($data) = @_;
  my $res = {};

  $res->{'known_concentration1'} = 10;
  $res->{'known_concentration2'} = 5;
  $res->{'known_concentration3'} = 2.5;
  $res->{'known_concentration4'} = 1.25;
  $res->{'known_concentration5'} = 0.625;
  $res->{'known_concentration6'} = 0.3125;
  $res->{'known_concentration7'} = 0.15625;
  $res->{'known_concentration8'} = 0.078125;

  for (1..8){
    my $i = $_;
    ## no critic (CodeLayout::ProhibitParensWithBuiltins)
    my $row = chr ( ord ('A') + ($i-1) );
    ## use critic
    $res->{"average$i"} = _get_average($data, $row);
    $res->{"std$i"} = _get_std_deviation($data, $res->{"average$i"}, $row);
    $res->{"cv$i"} = 100. * $res->{"std$i"} / $res->{"average$i"} ;

    $res->{"X$i"}          = $res->{  "known_concentration$i"};
    $res->{"Y$i"}          = $res->{              "average$i"};
    $res->{"Xsq$i"}        = $res->{  "X$i"} * $res->{  "X$i"};
    $res->{"Ysq$i"}        = $res->{  "Y$i"} * $res->{  "Y$i"};
    $res->{"XY$i"}         = $res->{  "X$i"} * $res->{  "Y$i"};
    $res->{"Xsq_by_Ysq$i"} = $res->{"Xsq$i"} / $res->{"Ysq$i"} ;
    $res->{"X_by_Ysq$i"}   = $res->{  "X$i"} / $res->{"Ysq$i"} ;
    $res->{"Y_by_Ysq$i"}   =             1.0 / $res->{  "Y$i"} ;
    $res->{"XY_by_Ysq$i"}  = $res->{  "X$i"} / $res->{  "Y$i"} ;
    $res->{"one_by_Ysq$i"}   =           1.0 / $res->{"Ysq$i"} ;

    $res->{'X'}          += $res->{         "X$i"} ;
    $res->{'Y'}          += $res->{         "Y$i"} ;
    $res->{'Xsq'}        += $res->{       "Xsq$i"} ;
    $res->{'Ysq'}        += $res->{       "Ysq$i"} ;
    $res->{'XY'}         += $res->{        "XY$i"} ;
    $res->{'Xsq_by_Ysq'} += $res->{"Xsq_by_Ysq$i"} ;
    $res->{'X_by_Ysq'}   += $res->{  "X_by_Ysq$i"} ;
    $res->{'Y_by_Ysq'}   += $res->{  "Y_by_Ysq$i"} ;
    $res->{'XY_by_Ysq'}  += $res->{ "XY_by_Ysq$i"} ;
    $res->{'one_by_Ysq'} += $res->{"one_by_Ysq$i"} ;
  }
  return $res;
}

sub _build_standard_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_doc($self->standard_doc);
}

sub _build_plateA_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_doc($self->plateA_doc);
}

sub _build_plateB_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_doc($self->plateB_doc);
}

sub _get_fluorescence_from_doc {
  my ($self, $xmldoc) = @_;
  my $fluorescences = $self->_parse_xml($xmldoc);
  while (my ($well, $data) = each %{$fluorescences} ) {
    my $d = $data->{'d1m1'}*1.0 + $data->{'d2m1'}*1.0 + $data->{'d1m2'}*1.0 + $data->{'d2m2'}*1.0;
    $fluorescences->{$well} = 0.25 * ( $data->{'d1m1'} + $data->{'d2m1'} + $data->{'d1m2'} + $data->{'d2m2'} );
  }
  return $fluorescences;
}

sub _parse_xml {
  my ($self, $xmldoc) = @_;
  my $results = {};

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

## use critic

1;


__END__

=head1 NAME

wtsi_clarity::file_parsing::dtx_concentration_calculator

=head1 SYNOPSIS

  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_path => $testdata_path.$standard_name,
    plateA_path   => $testdata_path.$plateA_name,
    plateB_path   => $testdata_path.$plateB_name);

  $calculator->get_analysis_results();

=head1 DESCRIPTION

  Module able to analyse the picogreen results files against a standard one.

=head1 SUBROUTINES/METHODS

=head2 standard_path - path for the standard result file

=head2 plateA_path - path for the plate A result file

=head2 plateB_path - path for the plate B result file

=head2 get_analysis_results - return a hash representing the analysis results

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item wtsi_clarity::util::clarity_elements;

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

