use strict;
use warnings;
use Test::More tests => 14;
use Test::Exception;
use Test::Deep;
use Test::MockObject::Extends;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::report');

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/report';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;


{ # _get_artifact_ids_with_udf
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_get_artifact_ids_with_udf('Volume Check (SM)', qq{Volume});
  my $expected = [ '2-2001', '2-2002', '2-2003' ];
  cmp_bag($res, $expected, qq{_get_artifact_ids_with_udf should return the correct ids.} );
}

{ # _get_udf_values
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> qq{Volume},
        },
      };
    });

  my $res = $m->_get_udf_values('Volume Check (SM)', qq{Volume});
  my $expected = {
    'SAMPLE0001' => {
      qq{Volume} => '1.25',
      },
    'SAMPLE0002' => {
      qq{Volume} => '1.50',
      },
    'SAMPLE0003' => {
      qq{Volume} => '1.75',
      }
    };
  is_deeply($res, $expected, qq{_get_udf_values should return the correct values.} );
}

{ # _get_udf_values
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_get_udf_values('Picogreen Analysis (SM)', qq{Concentration});
  my $expected = {
    'SAMPLE0001' => {
      qq{Concentration} => '25',
      },
    'SAMPLE0002' => {
      qq{Concentration} => '26',
      },
    'SAMPLE0003' => {
      qq{Concentration} => '27',
      }
    };
  is_deeply($res, $expected, qq{_get_udf_values should return the correct values.} );
}

{ # _get_udf_values
my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> q{Volume},
        },
      };
    });

  throws_ok
   { $m->_get_udf_values('Volume Check (SM)-rerun', qq{Volume}) }
   qr{The sample SAMPLE0002 possesses more than one value associated with "Volume". It is not currently possible to deal with it.},
   q{_get_udf_values should croak if the process has been rerun} ;
}

{ # _build__all_udf_values
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> q{Volume},
        },
      };
    });

  my $res = $m->_build__all_udf_values();
  my $expected = {
    'SAMPLE0001' => {
      q{Concentration} => '25',
      qq{Volume} => '1.25',
      },
    'SAMPLE0002' => {
      q{Concentration} => '26',
      qq{Volume} => '1.50',
      },
    'SAMPLE0003' => {
      q{Concentration} => '27',
      qq{Volume} => '1.75',
      }
    };
  is_deeply($res, $expected, qq{_build__all_udf_values should return the correct ids.} );
}

{ # _get_nethod_name_from_header
  my $testdata = {
    'Status'        => '_get_status',
    'word1 word2'   => '_get_word1_word2',
    ' Word3 word4 ' => '_get_word3_word4',
    };
  while (my ($test, $expected) = each %{$testdata} ) {
    my $res = wtsi_clarity::epp::report::_get_nethod_name_from_header($test);

    cmp_ok($res, 'eq', $expected, qq{_get_nethod_name_from_header should return the correct name.} );
  }
}

{ # _get_method_from_header  (batch_199de3d8a642c1d94e8556286a50e52f)
  my $testdata = {
    'Status' => '_get_status',
    'hello' => '_get_not_implemented_yet',
    };
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );
  while (my ($test, $expected) = each %{$testdata} ) {
    my $res = $m->_get_method_from_header($test);

    is_deeply($res, $expected, qq{_get_method_from_header should return the correct name.} );
  }
}

{ # _get_first_missing_necessary_data
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> q{Volume},
        },
      };
    });

  is($m->_get_first_missing_necessary_data(), undef,  '_get_first_missing_necessary_data should return nothing when all the data are provided.');
}

{ # _get_first_missing_necessary_data
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> q{Volume},
        },
        q{impossible_value} => {
          src_process => q{ProcessImpossible},
          src_udf_name=> q{Impossible Value},
        },
      };
    });

  cmp_ok($m->_get_first_missing_necessary_data(), 'eq', q{Impossible Value},  '_get_first_missing_necessary_data should return the correct value when not all the data are provided.');
}

{ # _build__all_udf_values
  my $m = Test::MockObject::Extends->new( wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  ) );
  $m->mock(q(_required_sources), sub{
      return {
        q{concentration} => {
          src_process => q{Picogreen Analysis (SM)},
          src_udf_name=> q{Concentration},
        },
        q{cherry_volume} => {
          src_process => q{Volume Check (SM)},
          src_udf_name=> qq{Volume},
        },
        q{impossible_value} => {
          src_process => q{ProcessImpossible},
          src_udf_name=> q{Impossible Value},
        },
      };
    });
  throws_ok
   { $m->_main_method() }
   qr{Impossible to produce the report: "Impossible Value" could not be found on the genealogy of some samples. Have you run all the necessary steps on the samples?},
   q{_main_method should croak if not all the data are present.} ;
}

######################################################
# WIP use this to create the output file...
# {
#   print qq{_main_method\n};
#   my $m = wtsi_clarity::epp::report->new(
#     process_url => $base_uri . '/processes/24-999'
#   );

#   my $res = $m->_main_method();
# }




1;
