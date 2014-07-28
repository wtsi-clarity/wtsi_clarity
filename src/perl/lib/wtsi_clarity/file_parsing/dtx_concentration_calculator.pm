package wtsi_clarity::file_parsing::dtx_concentration_calculator;

use Moose;
use Carp;
use wtsi_clarity::util::clarity_elements;
use Readonly;

Readonly::Scalar my $CV_LIMIT => 10.0;


our $VERSION = '0.0';

has 'standard_path' => (
  is => 'ro',
  isa => 'Str',
);

has 'plateA_path' => (
  is => 'ro',
  isa => 'Str',
);

has 'plateB_path' => (
  is => 'ro',
	isa => 'Str',
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
  my $fit_data = get_standard_coefficients($whole_data);
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

sub get_standard_coefficients {
  my ($data) = @_;
  my $res = {};

  $res = get_standard_intermediate_coefficients($data);

  my $x   = $res->{"X"};
  my $xsq = $res->{"Xsq"};
  my $y   = $res->{"Y"};
  my $ysq = $res->{"Ysq"};
  my $xy  = $res->{"XY"};
  my $xsq_by_ysq = $res->{"Xsq_by_Ysq"};
  my $x_by_ysq   = $res->{"X_by_Ysq"};
  my $y_by_ysq   = $res->{"Y_by_Ysq"};
  my $xy_by_ysq  = $res->{"XY_by_Ysq"};
  my $one_by_ysq   = $res->{"one_by_Ysq"};

  my $slope = ($y_by_ysq - $xy_by_ysq * $one_by_ysq / $x_by_ysq) / ($x_by_ysq - $xsq_by_ysq * $one_by_ysq / $x_by_ysq) ;
  my $intercept = ($y_by_ysq - $x_by_ysq * $slope) / $one_by_ysq;
  $res->{'slope'} = $slope;
  $res->{'intercept'} = $intercept;

  return $res;
}

sub get_standard_intermediate_coefficients {
  my ($data) = @_;
  my $res = {};

  sub get_average {
    my ($data, $row) = @_;
    my $acc = 0;
    for (my $i=9 ; $i < 13 ; $i++) {
      $acc += $data->{'standard'}->{"$row:$i"};
    }
    return $acc * 0.25 ;
  }

  sub get_std_deviation {
    my ($data, $average, $row) = @_;
    my $acc = 0;
    for (my $i=9 ; $i < 13 ; $i++) {
      $acc += ($data->{'standard'}->{"$row:$i"} - $average)**2;

    }
    return sqrt ( $acc / 3.0 ) ;
  }

  $res->{'known_concentration1'} = 10;
  $res->{'known_concentration2'} = 5;
  $res->{'known_concentration3'} = 2.5;
  $res->{'known_concentration4'} = 1.25;
  $res->{'known_concentration5'} = 0.625;
  $res->{'known_concentration6'} = 0.3125;
  $res->{'known_concentration7'} = 0.15625;
  $res->{'known_concentration8'} = 0.078125;

  for (my $i=1 ; $i < 9 ; $i++ ){
    my $row = chr ( ord ('A') + ($i-1) );
    $res->{"average$i"} = get_average($data, $row);
    $res->{"std$i"} = get_std_deviation($data, $res->{"average$i"}, $row);
    $res->{"cv$i"} = 100. * $res->{"std$i"} / $res->{"average$i"} ;

    $res->{"X$i"}          = $res->{"known_concentration$i"};
    $res->{"Y$i"}          = $res->{"average$i"};
    $res->{"Xsq$i"}        = $res->{  "X$i"} * $res->{  "X$i"};
    $res->{"Ysq$i"}        = $res->{  "Y$i"} * $res->{  "Y$i"};
    $res->{"XY$i"}         = $res->{  "X$i"} * $res->{  "Y$i"};
    $res->{"Xsq_by_Ysq$i"} = $res->{"Xsq$i"} / $res->{"Ysq$i"} ;
    $res->{"X_by_Ysq$i"}   = $res->{  "X$i"} / $res->{"Ysq$i"} ;
    $res->{"Y_by_Ysq$i"}   =             1.0 / $res->{  "Y$i"} ;
    $res->{"XY_by_Ysq$i"}  = $res->{  "X$i"} / $res->{  "Y$i"} ;
    $res->{"one_by_Ysq$i"}   =           1.0 / $res->{"Ysq$i"} ;

    $res->{"X"}          += $res->{         "X$i"} ;
    $res->{"Y"}          += $res->{         "Y$i"} ;
    $res->{"Xsq"}        += $res->{       "Xsq$i"} ;
    $res->{"Ysq"}        += $res->{       "Ysq$i"} ;
    $res->{"XY"}         += $res->{        "XY$i"} ;
    $res->{"Xsq_by_Ysq"} += $res->{"Xsq_by_Ysq$i"} ;
    $res->{"X_by_Ysq"}   += $res->{  "X_by_Ysq$i"} ;
    $res->{"Y_by_Ysq"}   += $res->{  "Y_by_Ysq$i"} ;
    $res->{"XY_by_Ysq"}  += $res->{ "XY_by_Ysq$i"} ;
    $res->{"one_by_Ysq"}   += $res->{  "one_by_Ysq$i"} ;
  }
  return $res;
}

sub _build_standard_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_file($self->standard_path)
}

sub _build_plateA_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_file($self->plateA_path)
}

sub _build_plateB_fluorescence {
  my ($self) = @_;
  return $self->_get_fluorescence_from_file($self->plateB_path)
}

sub _get_fluorescence_from_file {
  my ($self, $filepath) = @_;

  my $parser = XML::LibXML->new();
  my $xmldoc = $parser->load_xml(location => $filepath)
      or croak 'File can not be found at ' . $filepath;

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

  my @rows = $xpc->findnodes( q{/ss:Workbook/ss:Worksheet[@ss:Name='Raw_P_1_Seq_1_Cycle1']/ss:Table/ss:Row[@ss:Index>=8]})->get_nodelist();

  for(my $i=0 ; $i < 96 ; $i++) {
    my $well_str;
    my $datarow1_measurement1;
    my $datarow1_measurement2;
    my $datarow2_measurement1;
    my $datarow2_measurement2;
    for(my $j=0 ; $j < 3 ; $j++) {
      my $n = $i*4 + $j + 8;
      my $xpath = qq{/ss:Workbook/ss:Worksheet[\@ss:Name='Raw_P_1_Seq_1_Cycle1']/ss:Table/ss:Row[\@ss:Index=$n]} ;
      my @rows = $xpc->findnodes( $xpath );
      if (0 == $j){ # well
        $well_str = ($rows[0]->findnodes(qq{.//ss:Cell[\@ss:Index=1]/ss:Data/text()}))[0];
        $well_str =~ s/Well\s//xms;
        $well_str =~ s/\./\:/xms;
      }
      if (1 == $j){ # datarow 1
        $datarow1_measurement1 = ($rows[0]->findnodes(qq{.//ss:Cell[\@ss:Index=2]/ss:Data/text()}))[0]->nodeValue;
        $datarow1_measurement1 =~ s/Well\s//xms;
        $datarow1_measurement1 =~ s/\./\:/xms;
        $datarow1_measurement2 = ($rows[0]->findnodes(qq{.//ss:Cell[\@ss:Index=3]/ss:Data/text()}))[0]->nodeValue;
        $datarow1_measurement2 =~ s/Well\s//xms;
        $datarow1_measurement2 =~ s/\./\:/xms;
      }
      if (2 == $j){ # datarow 2
        $datarow2_measurement1 = ($rows[0]->findnodes(qq{.//ss:Cell[\@ss:Index=2]/ss:Data/text()}))[0]->nodeValue;
        $datarow2_measurement1 =~ s/Well\s//xms;
        $datarow2_measurement1 =~ s/\./\:/xms;
        $datarow2_measurement2 = ($rows[0]->findnodes(qq{.//ss:Cell[\@ss:Index=3]/ss:Data/text()}))[0]->nodeValue;
        $datarow2_measurement2 =~ s/Well\s//xms;
        $datarow2_measurement2 =~ s/\./\:/xms;
      }
    }
    $results->{$well_str} = { d1m1=>$datarow1_measurement1, d1m2=>$datarow1_measurement2, d2m1=>$datarow2_measurement1, d2m2=>$datarow2_measurement2};
  }
  return $results;
}

1;