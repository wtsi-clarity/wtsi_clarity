use strict;
use warnings;
use Test::More tests => 10;
use Carp;
use Test::MockObject::Extends;
use wtsi_clarity::util::textfile;
use wtsi_clarity::util::csv::factories::generic_csv_reader;
use List::MoreUtils qw/uniq/;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};
my $mock_qc_report_path = "t/data/epp/sm/proceed_sample_updater/24-28533.csv";
my $mock_wrong_qc_report_path = "t/data/epp/sm/proceed_sample_updater/24-28533_wrong.csv";

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/proceed_sample_updater';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

sub _mock_download_qc_file {
  my $file_path = shift;
  my $file = wtsi_clarity::util::textfile->new();
  $file->read_content($file_path);

  my $reader = wtsi_clarity::util::csv::factories::generic_csv_reader->new();

  my $content = $reader->build(
    file_content => $file->content,
  );

  return $content;
}

use_ok('wtsi_clarity::epp::sm::proceed_sample_updater', 'can use wtsi_clarity::epp::sm::proceed_sample_updater');

{
  my $epp = wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/24-25342',
  );
  isa_ok($epp, 'wtsi_clarity::epp::sm::proceed_sample_updater');
  can_ok($epp, qw/ run /);
}

{ #Gets the list of wells, which are OK to proceed
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/24-28533',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  my $wells_to_proceed = $epp->_plate_and_wells_to_proceed();

  my $expected_wells = {
    "5260273403730" => ["A:1", "A:2"],
    "5260272618821" => ["A:1", "A:3", "A:4"]
  };

  is_deeply($wells_to_proceed, $expected_wells, "Returns the correct wells to proceed.")
}

{ #Gets the list of placement uris to update
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/122-22674',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  my $wells_to_proceed = {
    "5260273403730" => ["A:1", "A:2"],
    "5260272618821" => ["A:1", "A:3", "A:4"]
  };

  my $expected_placement_uris = [
    'http://testserver.com:1234/here/artifacts/2-206317',
    'http://testserver.com:1234/here/artifacts/2-206319',
    'http://testserver.com:1234/here/artifacts/2-206320',
    'http://testserver.com:1234/here/artifacts/2-206321',
    'http://testserver.com:1234/here/artifacts/2-206322'
  ];

  my @actual_placement_uris = sort @{$epp->_placements_to_mark_proceed($wells_to_proceed)};

  is_deeply(\@actual_placement_uris, $expected_placement_uris, "Returns the correct uris of the placements");
}

{ #Gets the list of sample uris to update
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/122-22674',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  my $placement_uris = [
    'http://testserver.com:1234/here/artifacts/2-206317',
    'http://testserver.com:1234/here/artifacts/2-206319',
    'http://testserver.com:1234/here/artifacts/2-206320',
    'http://testserver.com:1234/here/artifacts/2-206321',
    'http://testserver.com:1234/here/artifacts/2-206322'
  ];

  my $expected_sample_uris = [
    'http://testserver.com:1234/here/samples/DEA103A1291',
    'http://testserver.com:1234/here/samples/DEA103A1307',
    'http://testserver.com:1234/here/samples/DEA103A1315',
    'http://testserver.com:1234/here/samples/DEA103A1766',
    'http://testserver.com:1234/here/samples/DEA103A1774'
  ];

  is_deeply($epp->_sample_uris_to_mark_proceed($placement_uris), $expected_sample_uris, "Returns the correct uris of the samples");
}

{ #Updates the sample's 'WTSI Proceed to Sequencing?' UDF field
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/122-22674',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  my $udf_path = q(/smp:sample/udf:field[@name="WTSI Proceed To Sequencing?"]/../@limsid);
  my $sample_uris = [
    'http://testserver.com:1234/here/samples/DEA103A1291',
    'http://testserver.com:1234/here/samples/DEA103A1307',
    'http://testserver.com:1234/here/samples/DEA103A1315',
    'http://testserver.com:1234/here/samples/DEA103A1766',
    'http://testserver.com:1234/here/samples/DEA103A1774'  ];
  my $expected_limsid = [
    'DEA103A1291',
    'DEA103A1307',
    'DEA103A1315',
    'DEA103A1766',
    'DEA103A1774'
  ];

  $epp->_update_samples_to_proceed($sample_uris);

  my $actual_lims_ids = ();
  foreach my $sample_uri (@{$sample_uris}) {
    my $sample_xml = $epp->fetch_and_parse($sample_uri);
    push @{$actual_lims_ids}, $epp->grab_values($sample_xml, $udf_path)->[0];
  }

  is_deeply($actual_lims_ids, $expected_limsid, "Updated the correct samples.");
}

{ #Checks if the correct plate(s) has been loaded
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/24-28533',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  my @plates_from_qc = sort keys %{$epp->_plate_and_wells_to_proceed()};

  my $plate_nodes_from_process =
    $epp->_plate_and_wells_from_process()->findnodes(q{/con:details/con:container/name/text()});
  my @plates_from_process = uniq( map { $_ } @{$plate_nodes_from_process});

  is_deeply(\@plates_from_qc, \@plates_from_process, "Returns the correct plates to proceed.");
  is($epp->_check_valid_plate_has_been_loaded, 1, "Valid plates has been loaded to the process.");
}

{ #Check with invalid plates
  my $epp = Test::MockObject::Extends->new(
    wtsi_clarity::epp::sm::proceed_sample_updater->new(
      process_url => $base_uri . '/processes/24-28533',
    )
  );

  my $method_ref = _mock_download_qc_file($mock_wrong_qc_report_path);
  $epp->mock(q(_download_qc_file), sub { return $method_ref;});

  is($epp->_check_valid_plate_has_been_loaded, 0, "Not valid plates has been loaded to the process.");
}

1;