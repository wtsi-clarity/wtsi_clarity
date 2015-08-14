use strict;
use warnings;

use wtsi_clarity::util::bulk_publish_wh_messages;

use Test::More tests => 6;
use Test::Exception;

use_ok('wtsi_clarity::util::bulk_publish_wh_messages');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/bulk_publish_wh_messages';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;

{ # Test for getting the correct process type for sample.
  my $model = 'sample';

  my $expected_process_type = 'type=Sample Receipt (SM)';

  my $messanger = wtsi_clarity::util::bulk_publish_wh_messages->new(
    process_url => $base_uri . '/processes/24-62561',
    model       => $model
  );

  is($messanger->_process_type, $expected_process_type, 'Returns the expected process type.')
}

{ # Test for getting the correct process type for study.
  my $model = 'study';

  my $expected_process_type = 'type=Sample Receipt (SM)';

  my $messanger = wtsi_clarity::util::bulk_publish_wh_messages->new(
    process_url => $base_uri . '/processes/24-62561',
    model       => $model
  );

  is($messanger->_process_type, $expected_process_type, 'Returns the expected process type.')
}

{ # Test for getting the correct process type for fluidigm.
  my $model = 'fluidigm';

  my $expected_process_type = 'type=Fluidigm 96.96 IFC Analysis (SM)';

  my $messanger = wtsi_clarity::util::bulk_publish_wh_messages->new(
    process_url => $base_uri . '/processes/24-62561',
    model       => $model
  );

  is($messanger->_process_type, $expected_process_type, 'Returns the expected process type.')
}

{ # Test for getting the correct process type for flowcell.
  my $model = 'flowcell';

  my $expected_process_type = 'type=Cluster Generation';

  my $messanger = wtsi_clarity::util::bulk_publish_wh_messages->new(
    process_url => $base_uri . '/processes/24-62561',
    model       => $model
  );

  is($messanger->_process_type, $expected_process_type, 'Returns the expected process type.')
}

{ # Test for getting the correct process URLs for the given project name.
  my $model = 'sample';

  my $messanger = wtsi_clarity::util::bulk_publish_wh_messages->new(
    project_name  => 'UTF-8 TEST Project',
    model         => $model
  );

  my @expected_process_urls = (
    'http://testserver.com:1234/here/processes/24-62561',
    'http://testserver.com:1234/here/processes/24-62562',
    'http://testserver.com:1234/here/processes/24-62563'
  );

  is_deeply($messanger->_process_urls_by_project_name, \@expected_process_urls, 'Returns the correct process URLs.');
}

1;