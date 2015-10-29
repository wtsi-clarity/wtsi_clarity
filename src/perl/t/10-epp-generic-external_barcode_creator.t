use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use Test::MockObject::Extends;
use Cwd;
use Carp;
use XML::SemanticDiff;

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/external_barcode_creator';
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

use_ok('wtsi_clarity::epp::generic::external_barcode_creator');

{
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => 'some',
  );
  isa_ok($barcode_creator, 'wtsi_clarity::epp::generic::external_barcode_creator');
}

{
  # creates a number of containers
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => $base_uri . '/processes/24-29592',
  );

  my @expected_container_limsids = ('27-5496', '27-5496'); # because caching we get back the same limsids

  is_deeply($barcode_creator->_new_containers(), \@expected_container_limsids, 'Got back the correct container limsids.');
}

{
  # creates barcodes for containers from their limsids
  # and add them to a hash along with their limsid and uris, sanger barcode (num)
  # container purpose and signature
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => $base_uri . '/processes/24-29592',
    _new_containers       => ['27-5496', '27-5497'],
  );

  my $expected_container_data;
  if ($config->barcode_mint->{'internal_generation'}) {
    $expected_container_data = {
      $base_uri . '/containers/27-5496' => {
        'limsid'    => '27-5496',
        'barcode'   => '5260275496792',
        'num'       => 'SM-275496O',
        'purpose'   => 'Stock Plate',
      },
      $base_uri . '/containers/27-5497' => {
        'limsid'    => '27-5497',
        'barcode'   => '5260275497805',
        'num'       => 'SM-275497P',
        'purpose'   => 'Stock Plate',
      }
    };
  } else {
    $expected_container_data = {
      $base_uri . '/containers/27-5496' => {
        'limsid'    => '27-5496',
        'barcode'   => 'GCLP:SM:5496:7',
        'num'       => 'GCLP:SM:5496:7',
        'purpose'   => 'Stock Plate',
      },
      $base_uri . '/containers/27-5497' => {
        'limsid'    => '27-5497',
        'barcode'   => 'GCLP:SM:5497:4',
        'num'       => 'GCLP:SM:5497:4',
        'purpose'   => 'Stock Plate',
      }
    };
  }

  is_deeply(
    $barcode_creator->_containers_data,
    $expected_container_data,
    'Creates the barcodes and uris for the given containers');
}

{
  # batch retrieve containers XML documents
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => $base_uri . '/processes/24-29592',
  );

  my @container_uris = (
    $base_uri . '/containers/27-5496',
    $base_uri . '/containers/27-5497'
  );

  my $expected_file = q{expected_containers.xml};
  my $testdata_dir = q{/t/data/epp/generic/external_barcode_creator/};
  my $expected_containers_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file;
  my $comparer = XML::SemanticDiff->new();

  my $containers_xml = $barcode_creator->batch_retrieve_containers_xml(\@container_uris);

  lives_and {
    is ref($containers_xml), 'XML::LibXML::Document'
  }
    'Retrieves containers XML document.';

  my @differences = $comparer->compare($containers_xml, $expected_containers_xml);
  cmp_ok(scalar @differences, '==', 0, 'Successfully retrieves containers XML document.');

}

{
  # Updates the name of the containers with their barcodes.
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => $base_uri . '/processes/24-29592',
    _new_containers       => ['27-5496', '27-5497'],
  );

  lives_ok {
    $barcode_creator->_update_containers_name_with_barcodes
  }
    'Updates containers name with their barcodes';

  # my $expected_file = q{expected_updated_containers.xml};
  # my $testdata_dir  = q{/t/data/epp/generic/external_barcode_creator/};
  # my $expected_containers_xml = XML::LibXML->load_xml(location => cwd . $testdata_dir . $expected_file) or croak 'File cannot be found at ' . cwd() . $testdata_dir . $expected_file ;
  # my $comparer = XML::SemanticDiff->new();

  # my @differences = $comparer->compare(
  #   $barcode_creator->batch_retrieve_containers_xml(\@container_uris), $expected_containers_xml);
  # cmp_ok(scalar @differences, '==', 0, 'Successfully updated containers name with their barcodes');

}

{
  # Gets the parameters for label printing
  my $barcode_creator = wtsi_clarity::epp::generic::external_barcode_creator->new(
    process_url           => $base_uri . '/processes/24-29592',
    _new_containers       => ['27-5496', '27-5497'],
  );

  my $expected_containers_data;
  if ($config->barcode_mint->{'internal_generation'}) {
    $expected_containers_data = {
      $base_uri . '/containers/27-5496' => {
        'limsid'    => '27-5496',
        'barcode'   => '5260275496792',
        'num'       => 'SM-275496O',
        'purpose'   => 'Stock Plate',
      },
      $base_uri . '/containers/27-5497' => {
        'limsid'    => '27-5497',
        'barcode'   => '5260275497805',
        'num'       => 'SM-275497P',
        'purpose'   => 'Stock Plate',
      }
    };
  } else {
    $expected_containers_data = {
      $base_uri . '/containers/27-5496' => {
        'limsid'    => '27-5496',
        'barcode'   => 'GCLP:SM:5496:7',
        'num'       => 'GCLP:SM:5496:7',
        'purpose'   => 'Stock Plate',
      },
      $base_uri . '/containers/27-5497' => {
        'limsid'    => '27-5497',
        'barcode'   => 'GCLP:SM:5497:4',
        'num'       => 'GCLP:SM:5497:4',
        'purpose'   => 'Stock Plate',
      }
    };
  }

  my $expected_label_parameters = {
    'number'        => '1',
    'type'          => 'plate',
    'user'          => 'Karel',
    'containers'    => $expected_containers_data,
    'source_plate'  => 1
  };

  # my $containers_data = $barcode_creator->_containers_data;

  is_deeply($barcode_creator->_label_parameters, $expected_label_parameters,
  'Returns the correct parameters for label printing');
}

{
  # creating label templates
  my $barcode_creator = Test::MockObject::Extends->new(
    wtsi_clarity::epp::generic::external_barcode_creator->new(
      process_url           => $base_uri . '/processes/24-29592',
      _new_containers       => ['27-5496', '27-5497'],
    )
  );
  $barcode_creator->mock(q{_date}, sub {
    return DateTime->new(
      year       => 2015,
      month      => 3,
      day        => 24,
      hour       => 11,
      minute     => 28,
      second     => 11,
    );
  });

  my $expected_label_templates;
  if ($config->barcode_mint->{'internal_generation'}) {
    $expected_label_templates = {
      'label_printer' => {
        'footer_text' => {
          'footer_text2' => 'Tue Mar 24 11:28:11 2015',
          'footer_text1' => 'footer by Karel'
        },
        'header_text' => {
          'header_text2' => 'Tue Mar 24 11:28:11 2015',
          'header_text1' => 'header by Karel'
        },
        'labels' => [
          {
            'template' => 'clarity_plate',
            'plate' => {
              'ean13' => '5260275496792',
              'label_text' => {
                'signature' => undef,
                'num' => 'SM-275496O',
                'date_user' => '24-Mar-2015 ',
                'purpose' => 'Stock Plate',
                'sanger_barcode' => ''
              }
            }
          },
          {
            'template' => 'clarity_plate',
            'plate' => {
              'ean13' => '5260275497805',
              'label_text' => {
                'signature' => undef,
                'num' => 'SM-275497P',
                'date_user' => '24-Mar-2015 ',
                'purpose' => 'Stock Plate',
                'sanger_barcode' => ''
              }
            }
          }
        ]
      }
    };
  } else {
    $expected_label_templates = {
      'label_printer' => {
        'footer_text' => {
          'footer_text2' => 'Tue Mar 24 11:28:11 2015',
          'footer_text1' => 'footer by Karel'
        },
        'header_text' => {
          'header_text2' => 'Tue Mar 24 11:28:11 2015',
          'header_text1' => 'header by Karel'
        },
        'labels' => [
          {
            'template' => 'clarity_data_matrix_plate',
            'plate' => {
              'barcode' => 'GCLP:SM:5496:7',
                'signature' => undef,
                'date_user' => '24-Mar-2015 ',
                'purpose' => 'Stock Plate',
            }
          },
          {
            'template' => 'clarity_data_matrix_plate',
            'plate' => {
              'barcode' => 'GCLP:SM:5497:4',
              'signature' => undef,
              'date_user' => '24-Mar-2015 ',
              'purpose' => 'Stock Plate',
            }
          }
        ]
      }
    };
  }

  is_deeply($barcode_creator->_label_templates, $expected_label_templates,
  'Got back the correct label templates');
}

1;
