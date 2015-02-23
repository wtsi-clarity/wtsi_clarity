use strict;
use warnings;
use Test::More tests => 7;
use Carp;

use Data::Dumper;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/proceed_sample_updater';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::sm::proceed_sample_updater', 'can use wtsi_clarity::epp::sm::proceed_sample_updater');

{
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/24-25342',
      qc_file_name => '24-25342'
  );
  isa_ok($epp, 'wtsi_clarity::epp::sm::proceed_sample_updater');
  can_ok($epp, qw/ run /);
}

{ #Gets the list of wells, which are OK to proceed 
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
    process_url => $base_uri . '/processes/122-22674',
    qc_file_name => '24-25342'
  );
  my $wells_to_proceed = $epp->_plate_and_wells_to_proceed();

  my $expected_wells = {
    "5260272593678" => ["A:1", "A:2", "A:4"],
    "5260273394663" => ["A:2", "A:3"]
  };

  is_deeply($wells_to_proceed, $expected_wells, "Returns the correct wells to proceed.")
}

{ #Gets the list of placement uris to update
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
    process_url => $base_uri . '/processes/122-22674',
    qc_file_name => '24-25342'
  );

  my $wells_to_proceed = {
    "5260272593678" => ["A:1", "A:2", "A:4"],
    "5260273394663" => ["A:2", "A:3"]
  };

  my $expected_placement_uris = [
    'http://testserver.com:1234/here/artifacts/2-112502',
    'http://testserver.com:1234/here/artifacts/2-112510',
    'http://testserver.com:1234/here/artifacts/2-112526',
    'http://testserver.com:1234/here/artifacts/2-133488',
    'http://testserver.com:1234/here/artifacts/2-133496'
  ];
  is_deeply($epp->_placements_to_mark_proceed($wells_to_proceed), $expected_placement_uris, "Returns the correct uris of the placements");
}

{ #Gets the list of sample uris to update
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
    process_url => $base_uri . '/processes/122-22674',
    qc_file_name => '24-25342'
  );
  my $placement_uris = [
    'http://testserver.com:1234/here/artifacts/2-112502',
    'http://testserver.com:1234/here/artifacts/2-112510',
    'http://testserver.com:1234/here/artifacts/2-112526',
    'http://testserver.com:1234/here/artifacts/2-133488',
    'http://testserver.com:1234/here/artifacts/2-133496'
  ];

  my $expected_sample_uris = [
    'http://testserver.com:1234/here/samples/DEA103A1291',
    'http://testserver.com:1234/here/samples/DEA103A1299',
    'http://testserver.com:1234/here/samples/DEA103A1315',
    'http://testserver.com:1234/here/samples/DEA103A1774',
    'http://testserver.com:1234/here/samples/DEA103A1782'
  ];

  is_deeply($epp->_sample_uris_to_mark_proceed($placement_uris), $expected_sample_uris, "Returns the correct uris of the samples");
}

{ #Updates the sample's 'WTSI Proceed to Sequencing?' UDF field
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
    process_url => $base_uri . '/processes/122-22674',
    qc_file_name => '24-25342'
  );
  my $udf_path = q(/smp:sample/udf:field[@name="WTSI Proceed To Sequencing?"]/../@limsid);
  my $sample_uris = [
    'http://testserver.com:1234/here/samples/DEA103A1291',
    'http://testserver.com:1234/here/samples/DEA103A1299',
    'http://testserver.com:1234/here/samples/DEA103A1315',
    'http://testserver.com:1234/here/samples/DEA103A1774',
    'http://testserver.com:1234/here/samples/DEA103A1782'
  ];
  my $expected_limsid = [
    'DEA103A1291',
    'DEA103A1299',
    'DEA103A1315',
    'DEA103A1774',
    'DEA103A1782'
  ];

  $epp->_update_samples_to_proceed($sample_uris);

  my $actual_lims_ids = ();
  foreach my $sample_uri (@{$sample_uris}) {
    my $sample_xml = $epp->fetch_and_parse($sample_uri);
    push @{$actual_lims_ids}, $epp->grab_values($sample_xml, $udf_path)->[0];
  }

  is_deeply($actual_lims_ids, $expected_limsid, "Updated the correct samples.")
}

1;