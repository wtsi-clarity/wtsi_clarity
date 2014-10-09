use strict;
use warnings;
use Test::More tests => 11;
use Test::Exception;
use Test::MockObject::Extends;
use XML::SemanticDiff;
use XML::LibXML;
use Carp;

use Data::Dumper;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/isc/agilent_analyser';

use_ok ('wtsi_clarity::epp::isc::agilent_analyser');


{
  my $errors = { 'A01' => qq{some error}, 'Z34' => qq{some error},  };
  my $res = wtsi_clarity::epp::isc::agilent_analyser::_make_error_report($errors);
  my $expected = qq{The wells [A01, Z34] are out of range!};
  cmp_ok($res, 'eq', $expected, '_make_error_report should return a properly concatenated string');
}


{
  my $location = 'A01';
  my $results = { 'concentration' => 12.3 , 'molarity' => 27, 'size' => 12  };
  my $range   = { 'conc_min' => 10, 'conc_max' => 100, 'molarity_min' => 10, 'molarity_max' => 50, 'size_min' => 10, 'size_max' => 50 };
  my $res = wtsi_clarity::epp::isc::agilent_analyser::_check_range_for_one_result($location, $results, $range);
  my $expected = qq{};
  cmp_ok($res, 'eq', $expected, '_check_range_for_one_result should return nothing');
}


{
  my $location = 'A01';
  my $results = { 'concentration' => 120.3 , 'molarity' => 27, 'size' => 12  };
  my $range   = { 'conc_min' => 10, 'conc_max' => 100, 'molarity_min' => 10, 'molarity_max' => 50, 'size_min' => 10, 'size_max' => 50 };
  my $res = wtsi_clarity::epp::isc::agilent_analyser::_check_range_for_one_result($location, $results, $range);
  my $expected = q{Concentration is out of range for well A01.};
  cmp_ok($res, 'eq', $expected, '_check_range_for_one_result should return an error when concentration is out of range');
}


{
  my $location = 'A01';
  my $results = { 'concentration' => 12.3 , 'molarity' => 270, 'size' => 12 };
  my $range   = { 'conc_min' => 10, 'conc_max' => 100, 'molarity_min' => 10, 'molarity_max' => 50, 'size_min' => 10, 'size_max' => 50  };
  my $res = wtsi_clarity::epp::isc::agilent_analyser::_check_range_for_one_result($location, $results, $range);
  my $expected = q{Molarity is out of range for well A01.};
  cmp_ok($res, 'eq', $expected, '_check_range_for_one_result should return an error when molarity is out of range');
}


{
  my $location = 'A01';
  my $results = { 'concentration' => 12.3 , 'molarity' => 27, 'size' => 102 };
  my $range   = { 'conc_min' => 10, 'conc_max' => 100, 'molarity_min' => 10, 'molarity_max' => 50, 'size_min' => 10, 'size_max' => 50  };
  my $res = wtsi_clarity::epp::isc::agilent_analyser::_check_range_for_one_result($location, $results, $range);
  my $expected = q{Size is out of range for well A01.};
  cmp_ok($res, 'eq', $expected, '_check_range_for_one_result should return an error when size is out of range');
}


{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = wtsi_clarity::epp::isc::agilent_analyser->new(
    process_url => $base_uri .'/processes/24-18008'
  );
  throws_ok {
    $m->_precheck();
  }
  qr {The number of results found \(2\) is not compatible with the number of wells on the input plate \(95\)!},
  qq {_precheck should throw when results are not matching input};
}

{
  use wtsi_clarity::util::config;
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $config = wtsi_clarity::util::config->new();
  my $base_uri = $config->clarity_api->{'base_uri'};

  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::isc::agilent_analyser->new(
    process_url => $base_uri .'/processes/24-18008'
  ) ) ;

  # by doing this, we only update two artifacts...
  # this would not be possible if we were calling _main_method directly, as it implies the call to
  # _precheck(), which will croack if the nb of results does not match the nb of artifacts.
  $m->mock(q(_mapping_details), sub{
     return {
              'B1' => {
                    'file_path' => 't/data/epp/isc/agilent_analyser/5260002753679_A1_B1.xml',
                    'wells' => [
                                 3,
                                 4
                               ]
                  },
              'A1' => {
                    'file_path' => 't/data/epp/isc/agilent_analyser/5260002753679_A1_B1.xml',
                    'wells' => [
                                 1,
                                 2
                               ]
                  }
            };
  });
  my $updated_details = $m->_update_output_details();
  my $testdata_dir  = q{t/data/epp/isc/agilent_analyser/};
  my $expected_file = q{expected_data1.xml};
  my $expected_results = XML::LibXML->load_xml(location => $testdata_dir . $expected_file) or croak 'File cannot be found at ' . $testdata_dir . $expected_file ;
  my $comparer = XML::SemanticDiff->new();

  my @differences = $comparer->compare($updated_details, $expected_results);
  cmp_ok(scalar @differences, '==', 0, '_update_output_details should update properly the given XML document');
}


{
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::isc::agilent_analyser->new(
    process_url => '/something/'
  ) );
  $m->mock(q(_map_artid_location), sub{
      return {
        '1' => 'A1',
        '2' => 'A2',
      };
    });
  $m->mock(q(_analysis_results), sub{
      return {
        'A1' => {'concentration' => 12.3, 'molarity' => 12.4  , 'size' => 12.4 },
        'A2' => {'concentration' => 100.3, 'molarity' => 12.4 , 'size' => 12.4 },
      };
    });
  $m->mock(q(_map_artid_range), sub{
      return {
        '1' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 12.4, 'molarity_max' => 110., 'size_min' => 10, 'size_max' => 50 },
        '2' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 12.4, 'molarity_max' => 110., 'size_min' => 10, 'size_max' => 50 },
      };
    });
  throws_ok {
    $m->_check_range();
  }
  qr{The wells \[A2\] are out of range!},
  qq{_check_range should throw when one concentration is out of range};
}


{
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::isc::agilent_analyser->new(
    process_url => '/something/'
  ) );
  $m->mock(q(_map_artid_location), sub{
      return {
        '1' => 'A1',
        '2' => 'A2',
      };
    });
  $m->mock(q(_analysis_results), sub{
      return {
        'A1' => {'concentration' => 12.3, 'molarity' => 120.4 , 'size' => 12.4 },
        'A2' => {'concentration' => 10, 'molarity' => 12.4 , 'size' => 12.4 },
      };
    });
  $m->mock(q(_map_artid_range), sub{
      return {
        '1' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 10.0, 'molarity_max' => 100., 'size_min' => 10, 'size_max' => 50 },
        '2' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 10.0, 'molarity_max' => 100., 'size_min' => 10, 'size_max' => 50 },
      };
    });
  throws_ok {
    $m->_check_range();
  }
  qr{The wells \[A1\] are out of range!},
  qq{_check_range should throw when one molarity is out of range};
}


{
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::isc::agilent_analyser->new(
    process_url => '/something/'
  ) );
  $m->mock(q(_map_artid_location), sub{
      return {
        '1' => 'A1',
        '2' => 'A2',
      };
    });
  $m->mock(q(_analysis_results), sub{
      return {
        'A1' => {'concentration' => 12.3, 'molarity' => 12.4 , 'size' => 12.4 },
        'A2' => {'concentration' => 10, 'molarity' => 12.4 , 'size' => 12.4 },
      };
    });
  $m->mock(q(_map_artid_range), sub{
      return {
        '1' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 10, 'molarity_max' => 100., 'size_min' => 10, 'size_max' => 50 },
        '2' => {'conc_max' => 100, 'conc_min' => 10, 'molarity_min' => 10, 'molarity_max' => 100., 'size_min' => 10, 'size_max' => 50 },
      };
    });
  ok($m->_check_range(), qq{_check_range should not throw when everything is fine.} );
}
