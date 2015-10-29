use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use Carp;

use wtsi_clarity::util::config;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/plate_rerouter';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::sm::plate_rerouter', 'can use wtsi_clarity::epp::sm::plate_rerouter');

{
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/bla-bla',
      process_type      => 'process_type',
      new_step_name     => 'step name',
      new_protocol_name => 'protocol name',
      new_workflow_name => 'workflow name',
  );
  isa_ok($plate_rerouter, 'wtsi_clarity::epp::sm::plate_rerouter');
  can_ok($plate_rerouter, qw/ run /);
}

{ # Tests for determine the Lims ID of the Output Artifact
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'process_type',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $expected_output_artifact_uris = [
    'http://testserver.com:1234/here/artifacts/2-376080?state=188418',
    'http://testserver.com:1234/here/artifacts/2-376081?state=188419',
    'http://testserver.com:1234/here/artifacts/2-376078?state=188416',
    'http://testserver.com:1234/here/artifacts/2-376079?state=188417',
    'http://testserver.com:1234/here/artifacts/2-376076?state=188414',
    'http://testserver.com:1234/here/artifacts/2-376077?state=188415',
    'http://testserver.com:1234/here/artifacts/2-376074?state=188412',
    'http://testserver.com:1234/here/artifacts/2-376075?state=188413',
    'http://testserver.com:1234/here/artifacts/2-376088?state=188426',
    'http://testserver.com:1234/here/artifacts/2-376089?state=188427',
    'http://testserver.com:1234/here/artifacts/2-376086?state=188424',
    'http://testserver.com:1234/here/artifacts/2-376087?state=188425',
    'http://testserver.com:1234/here/artifacts/2-376084?state=188422',
    'http://testserver.com:1234/here/artifacts/2-376085?state=188423',
    'http://testserver.com:1234/here/artifacts/2-376082?state=188420',
    'http://testserver.com:1234/here/artifacts/2-376083?state=188421',
    'http://testserver.com:1234/here/artifacts/2-376091?state=188429',
    'http://testserver.com:1234/here/artifacts/2-376090?state=188428'
  ];
  
  is_deeply($plate_rerouter->process_doc->output_artifact_uris, $expected_output_artifact_uris,
    'Returns the correct output lims ids.');
}

{ # Tests for getting the sample limsid
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'process_type',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $expected_sample_limsid = 'DEA103A525';
  my $artifact_uri = $plate_rerouter->process_doc->output_artifact_uris->[0];
  is($plate_rerouter->process_doc->sample_limsid_by_artifact_uri($artifact_uri), $expected_sample_limsid,
    'Returns the correct limsid of the sample');
}

{ # Tests for searching the artifacts with the given sample limsid in the given process-type
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'Pico Dilution (SM)',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $sample_limsid = "DEA103A525";

  my $expected_artifact_limsid = "2-101501";

  is($plate_rerouter->_artifact_limsid_by_process_type_with_samplelimsid($sample_limsid),
    $expected_artifact_limsid,
    'Returns the correct artifact limsid.');
}

{ # Tests for getting the container
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'Pico Dilution (SM)',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $artifact_limsid = "2-101501";

  my $expected_container_uri = "http://testserver.com:1234/here/containers/27-2495";

  is($plate_rerouter->process_doc->container_uri_by_artifact_limsid($artifact_limsid),
    $expected_container_uri,
    'Returns the correct container URI.');
}

{ # Gets all artifacts URI from container
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'Pico Dilution (SM)',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $container_uri = "http://testserver.com:1234/here/containers/27-2495";

  my $expected_analyte_uris = [
    'http://testserver.com:1234/here/artifacts/2-101448',
    'http://testserver.com:1234/here/artifacts/2-101505',
    'http://testserver.com:1234/here/artifacts/2-101450',
    'http://testserver.com:1234/here/artifacts/2-101501',
    'http://testserver.com:1234/here/artifacts/2-101504',
    'http://testserver.com:1234/here/artifacts/2-101449',
    'http://testserver.com:1234/here/artifacts/2-101502',
    'http://testserver.com:1234/here/artifacts/2-101503',
    'http://testserver.com:1234/here/artifacts/2-101506',
  ];

  is_deeply($plate_rerouter->process_doc->get_analytes_uris_by_container_uri($container_uri),
            $expected_analyte_uris,
            'Returns the correct analyte URIs.');
}

{ # Gets step URI for a given step
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'Pico Dilution (SM)',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $expected_uri_for_new_step = 'http://testserver.com:1234/here/configuration/workflows/601/stages/1216';

  is($plate_rerouter->_get_new_step_uri(), $expected_uri_for_new_step,
    'Returns the correct URI for new step.');
}

{ # Reroute all analytes to the given step
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
  my $plate_rerouter = wtsi_clarity::epp::sm::plate_rerouter->new(
      process_url       => $base_uri . '/processes/24-63423',
      process_type      => 'Pico Dilution (SM)',
      new_step_name     => 'Pico Assay Plate (SM)',
      new_protocol_name => 'Picogreen Protocol',
      new_workflow_name => 'GCLP Sample Management QC',
  );

  my $analyte_uris = [
    'http://testserver.com:1234/here/artifacts/2-101448',
    'http://testserver.com:1234/here/artifacts/2-101505',
    'http://testserver.com:1234/here/artifacts/2-101450',
    'http://testserver.com:1234/here/artifacts/2-101501',
    'http://testserver.com:1234/here/artifacts/2-101504',
    'http://testserver.com:1234/here/artifacts/2-101449',
    'http://testserver.com:1234/here/artifacts/2-101502',
    'http://testserver.com:1234/here/artifacts/2-101503',
    'http://testserver.com:1234/here/artifacts/2-101506',
  ];

  lives_ok { $plate_rerouter->_reroute_analytes($analyte_uris); } 'Reroting analytes working fine.';
}

1;