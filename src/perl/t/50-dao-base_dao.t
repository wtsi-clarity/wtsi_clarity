use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use Moose::Meta::Class;

use_ok('wtsi_clarity::dao::base_dao');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/dao/base_dao';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

{
  my $lims_id = 'SYY154A1';
  my $base_dao = Moose::Meta::Class->create(
    'New::Class',
    roles => [qw/wtsi_clarity::dao::base_dao/],
    methods => {
      init => sub { return; },
    },
    attributes   => [
      Class::MOP::Attribute->new(
        resource_type => (
          accessor         => 'resource_type',
          default     => 'samples',
        )
      )
    ]
  );
  
  my $dao = $base_dao->new_object( lims_id => $lims_id);
  
  my $artifact_xml;
  lives_ok { $artifact_xml = $dao->_artifact_xml} 'got sample artifacts';
  is(ref $artifact_xml, 'XML::LibXML::Document', 'Got back an XML Document');
}

1;