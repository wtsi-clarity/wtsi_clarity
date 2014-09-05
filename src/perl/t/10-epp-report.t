use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Test::Deep;
use Test::MockObject::Extends;
use Data::Dumper;


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

  my $res = $m->_get_artifact_ids_with_udf('PROCESS2001', q{Cherrypick Sample Volume});
  my $expected = [ '2-2001', '2-2002', '2-2003' ];
  cmp_bag($res, $expected, qq{_get_artifact_ids_with_udf should return the correct ids.} );
}

{ # _get_udf_values
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_get_udf_values('PROCESS2001', q{Cherrypick Sample Volume});
  my $expected = {
    'SAMPLE0001' => {
      q{Cherrypick Sample Volume} => '1.25',
      },
    'SAMPLE0002' => {
      q{Cherrypick Sample Volume} => '1.50',
      },
    'SAMPLE0003' => {
      q{Cherrypick Sample Volume} => '1.75',
      }
    };
  is_deeply($res, $expected, qq{_get_udf_values should return the correct ids.} );
}

{ # _get_udf_values
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  throws_ok
   { $m->_get_udf_values('PROCESS2001-rerun', q{Cherrypick Sample Volume}) }
   qr{The sample SAMPLE0002 possesses more than one value associated with "Cherrypick Sample Volume". It is not currently possible to deal with it.},
   q{_get_udf_values should croak if the process has been rerun} ;
}

{ # _build__all_udf_values
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );


  my $report = Test::MockObject::Extends->new( q(wtsi_clarity::epp::report) );
  $report->mock(q(_get_udf_values), sub{
  my ($self, $step, $udf_name) = @_;
    if ($step eq 'Step0001') {
      return {
          'SAMPLE0001' => {
            q{Concentration} => '25',
            },
          'SAMPLE0002' => {
            q{Concentration} => '26',
            },
          'SAMPLE0003' => {
            q{Concentration} => '27',
            }
        };
    } else {
      return {
          'SAMPLE0001' => {
            q{Cherrypick Sample Volume} => '1.25',
            },
          'SAMPLE0002' => {
            q{Cherrypick Sample Volume} => '1.50',
            },
          'SAMPLE0003' => {
            q{Cherrypick Sample Volume} => '1.75',
            }
        };
    }
    return ;
  });

  my $res = $m->_build__all_udf_values();
  my $expected = {
    'SAMPLE0001' => {
      q{Concentration} => '25',
      q{Cherrypick Sample Volume} => '1.25',
      },
    'SAMPLE0002' => {
      q{Concentration} => '26',
      q{Cherrypick Sample Volume} => '1.50',
      },
    'SAMPLE0003' => {
      q{Concentration} => '27',
      q{Cherrypick Sample Volume} => '1.75',
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

{ # _get_nethod_from_header  (batch_199de3d8a642c1d94e8556286a50e52f)
  my $testdata = {
    'Status' => '_get_status',
    'hello' => '_get_not_implemented_yet',
    };
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );
  while (my ($test, $expected) = each %{$testdata} ) {
    my $res = $m->_get_nethod_from_header($test);

    is_deeply($res, $expected, qq{_get_nethod_from_header should return the correct name.} );
  }
}


#######################################################
# WIP use this to create the output file...
{
  print qq{_get_all_udf_values\n};
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_main_method();
}




1;
