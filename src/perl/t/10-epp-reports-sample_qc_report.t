use strict;
use warnings;

use Test::More tests => 16;

use Test::MockObject::Extends;
use Test::Exception;

use DateTime;
use XML::LibXML;

use File::Slurp;

use_ok('wtsi_clarity::epp::reports::sample_qc_report');

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/sample_qc_report';

my $EXPECTED_FILE_CONTENT = [
  {
    'DNA amount library prep' => '192',
    'Library concentration' => '138.3304326231556',
    'Status' => 'Passed',
    'Sample volume' => '5.00907469236368',
    'Concentration' => '38.3304326231556',
    'Sample UUID' => '01e9be16-a7c6-11e4-b42e-68b59977951e'
  },
];

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $report = wtsi_clarity::epp::reports::sample_qc_report->new(
    process_url => $base_uri . '/processes/24-63229',
  );

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $samples = $report->_build_samples($container);

  my $expected_sample_count = 4;

  is(scalar @{$samples}, $expected_sample_count, 'Got the correct count of samples');

  $report->_sample_doc($samples);

  is($report->publish_to_irods, 1, 'Returns the correct value for ');

  my $sample_doc = $samples->[0];

  my $file_content = $report->file_content($sample_doc);

  is_deeply($file_content, $EXPECTED_FILE_CONTENT,
  'File content is generated from a sample node correctly');

  my $mocked_report = Test::MockObject::Extends->new(
    wtsi_clarity::epp::reports::sample_qc_report->new(
      process_url => $base_uri . '/processes/24-63229',
    )
  );
  $mocked_report->mock(q{now}, sub {
    return "20150813121212";
  });

  my $expected_file_name = "01e9be16-a7c6-11e4-b42e-68b59977951e.20150813121212.lab_sample_qc.txt";

  $mocked_report->_write_sample_uuid($sample_doc->findvalue('./name'));

  is($mocked_report->file_name($sample_doc), $expected_file_name, 'Creates a file name correctly');
}

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $report = wtsi_clarity::epp::reports::sample_qc_report->new(
    process_url => $base_uri . '/processes/24-63229',
  );

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $samples = $report->_build_samples($container);

  my $sample_doc = $samples->[0];

  my $sample_limsid = $sample_doc->findvalue('./@limsid');
  my $artifact = $report->_get_cherrypick_sample_artifact($sample_limsid);
  my $cherrypick_stamping_doc = $report->_get_cherrypick_stamping_process($artifact);
  my $cherrypick_volume = $report->_get_cherrypick_sample_volume($artifact);

  is($artifact->findvalue('art:artifact/@limsid'), '2-373511', 'Finds the correct artifact');

  is($cherrypick_stamping_doc->findvalue('prc:process/@limsid'), '24-63229', 'Finds the correct process');

  is($cherrypick_volume, '5.00907469236368', 'Returns the correct value for the cherrypick volume');

  my $expected_dna_amount_library_prep = 192;

  is($report->_get_dna_amount_library_prep($cherrypick_stamping_doc, $sample_doc, $cherrypick_volume), $expected_dna_amount_library_prep,
  'Returns the correct DNA amount library prep value.');
}

{
  my $report = Test::MockObject::Extends->new(
    wtsi_clarity::epp::reports::sample_qc_report->new(
      process_url => $base_uri . '/processes/24-63229',
      publish_to_irods  => 1
    )
  )->mock(q(_irods_publisher), sub {
    return Test::MockObject->new()->mock(q(publish), sub {
    });
  });

  my $report_path = $ENV{'WTSICLARITY_WEBCACHE_DIR'} . q{/example_report.txt};

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $samples = $report->_build_samples($container);

  my $sample_doc = $samples->[0];

  $report->_write_sample_uuid($sample_doc->findvalue('./name'));
  $report->_write_project_uri($sample_doc->findvalue('./project/@uri'));

  lives_ok {
    $report->_publish_report_to_irods($report_path)
  } 'Successfully published the file into iRODS.';

  is($report->irods_destination_path, '/Sanger1-dev/home/glsai', 'irods path is correct');
}

{
  my $HASH = '0123456789abcdef0123456789abcdef';

  my $irods_mock = Test::MockObject->new(
  )->mock(q(publish), sub {
    }
  )->mock(q(md5_hash), sub {
      return $HASH;
    }
  );

  my $report = Test::MockObject::Extends->new(
  wtsi_clarity::epp::reports::sample_qc_report->new(
    process_url      => $base_uri.'/processes/24-63229',
    publish_to_irods => 1
  )
  )->mock(q{irods_destination_path}, sub {
      return '/test/destination/path/'
  })->mock(q{now}, sub {
      return "20150813121212";
    })->mock(q(_irods_publisher), sub {
      return $irods_mock;
    })->mock(q(insert_hash_to_database), sub {
      my ($self, $filename, $hash, $location) = @_;
      is($filename, '01e9be16-a7c6-11e4-b42e-68b59977951e.20150813121212.lab_sample_qc.txt',
        'Inserts filename into database');
      is($hash, $HASH, 'Inserts hash into the database');
      is($location, '/test/destination/path/', 'Inserts location into the database.')
    });

  lives_ok {
    $report->_create_reports()
  } 'Created reports okay with hash.';

  $irods_mock->mock(q(md5_hash), sub {
      undef;
    });

  lives_ok {
    $report->_create_reports()
  } 'Created reports okay without hash.';
  # Shouldn't run the insert_hash_to_database method again.
}

1;