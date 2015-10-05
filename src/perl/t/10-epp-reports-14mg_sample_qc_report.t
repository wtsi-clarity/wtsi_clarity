use strict;
use warnings;

use Test::More tests => 8;
use Test::MockObject::Extends;
use Test::Exception;

use DateTime;
use XML::LibXML;

use File::Slurp;

use_ok('wtsi_clarity::epp::reports::14mg_sample_qc_report');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/14mg_sample_qc_report';

my $EXPECTED_FILE_CONTENT = [
  {
    'DNA amount library prep' => '115.339134753689',
    'Library concentration' => '138.3304326231556',
    'Status' => 'Passed',
    'Sample volume' => '120',
    'Concentration' => '38.3304326231556',
    'Sample UUID' => '01e9be16-a7c6-11e4-b42e-68b59977951e'
  },
];

{
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $report = wtsi_clarity::epp::reports::14mg_sample_qc_report->new(
    process_url => $base_uri . '/processes/24-63229',
  );

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $container_lims_id = $container->findvalue('@limsid');

  my $samples = $report->_build_samples($container);

  my $expected_sample_count = 4;

  is(scalar @{$samples}, $expected_sample_count, 'Got the correct count of samples');

  my $sample_doc = $samples->[0];

  my $file_content = $report->file_content($sample_doc);

  is_deeply($file_content, $EXPECTED_FILE_CONTENT,
    'File content is generated from a sample node correctly');

  my $mocked_report = Test::MockObject::Extends->new(
    wtsi_clarity::epp::reports::14mg_sample_qc_report->new(
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

  my $report = wtsi_clarity::epp::reports::14mg_sample_qc_report->new(
    process_url => $base_uri . '/processes/24-63229',
  );

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $container_lims_id = $container->findvalue('@limsid');

  my $samples = $report->_build_samples($container);

  my $sample_doc = $samples->[0];

  my $expected_dna_amount_library_prep = 115.339134753689;

  is($report->_get_dna_amount_library_prep($sample_doc), $expected_dna_amount_library_prep,
    'Returns the correct DNA amount library prep value.');
}

SKIP: {
  my $irods_setup_exit_code = system('ihelp > /dev/null 2>&1');

  skip 'iRODS icommands needs to be installed and they needs to be on the PATH.', 3 if ($irods_setup_exit_code != 0);

  my $report = wtsi_clarity::epp::reports::14mg_sample_qc_report->new(
    process_url => $base_uri . '/processes/24-63229',
    publish_to_irods  => 1
  );

  my $report_path = $ENV{'WTSICLARITY_WEBCACHE_DIR'} . q{/example_report.txt};

  my $containers_xml = XML::LibXML->load_xml(
    location => $ENV{'WTSICLARITY_WEBCACHE_DIR'} . '/POST/containers.batch_dc5ceba3ac75c37f39cd1fcfd78d4918'
  );

  my $container = $containers_xml->findnodes('/con:details/con:container')->pop();

  my $container_lims_id = $container->findvalue('@limsid');

  my $samples = $report->_build_samples($container);

  my $sample_doc = $samples->[0];

  $report->_write_sample_uuid($sample_doc->findvalue('./name'));

  lives_ok {$report->_publish_report_to_irods($report_path)}
    'Successfully published the file into iRODS.';

  #cleanup
  my $irods_publisher = wtsi_clarity::irods::irods_publisher->new();
  my $exit_code;
  my @file_paths = split(/\//, $report_path);
  my $file_to_remove = pop @file_paths;
  lives_ok {$exit_code = $irods_publisher->remove($file_to_remove)}
    'Successfully removed file from iRODS.';
  is($exit_code, 0, "Successfully exited from the irm command.");
}

1;