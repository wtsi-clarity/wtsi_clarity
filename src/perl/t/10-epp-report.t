use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;
use Test::Deep;
use Test::MockObject::Extends;

# local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::report');


{
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_get_artifact_ids_with_udf('PROCESS2001', q{Cherrypick Sample Volume});
  my $expected = [ '2-2001', '2-2002', '2-2003' ];
  cmp_bag($res, $expected, qq{_get_artifact_ids_with_udf should return the correct ids.} );
}

{
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

{
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  throws_ok
   { $m->_get_udf_values('PROCESS2001-rerun', q{Cherrypick Sample Volume}) }
   qr{The sample SAMPLE0002 possesses more than one value associated with "Cherrypick Sample Volume". It is not currently possible to deal with it.},
   q{_get_udf_values should croak if the process has been rerun} ;
}

{
  print qq{_get_all_udf_values (mock)\n};
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



  my $res = $m->_get_all_udf_values();
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
  # is_deeply($res, $expected, qq{_get_all_udf_values should return the correct ids.} );

}



{
  print qq{_get_all_udf_values\n};
  my $m = wtsi_clarity::epp::report->new(
    process_url => $base_uri . '/processes/24-999'
  );

  my $res = $m->_get_all_udf_values();
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
  is_deeply($res, $expected, qq{_get_all_udf_values should return the correct ids.} );

}



1;
