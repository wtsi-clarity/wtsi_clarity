use strict;
use warnings;
use JSON;
use utf8;
use Moose::Meta::Class;
use Test::More tests => 25;
use Test::Exception;
use Test::MockObject;
use Test::MockObject::Extends;

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
# my $base_url = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::process_checks::bed_verifier');

sub get_config {
  open(my $fh, '<:encoding(UTF-8)', 't/data/config/bed_verification.json');
  local $/;
  my $json_text = <$fh>;
  my $config = decode_json($json_text);
}

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];
local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;

my $epp = Moose::Meta::Class
  ->create_anon_class(
  superclasses => ['wtsi_clarity::epp::generic::bed_verifier'],
);

local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';
my $base_url = 'http://testserver.com:1234/here/';

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(config => get_config());

  isa_ok($bed_verifier, 'wtsi_clarity::process_checks::bed_verifier');
  can_ok($bed_verifier, qw / config verify /);
}

# Step Config
{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => 'fake url',
    ),
  );

  isa_ok($bed_verifier->_step_config, 'HASH', 'Creates the step config');
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'rubbish',
      process_url => 'fake url',
    ),
  );

  throws_ok { $bed_verifier->_step_config }
    qr/Bed verification config can not be found for process rubbish/,
    'Throws when it can not find the step config';
}

# Robot Config
{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => '/processes/24-102433',
    ),
  );

  isa_ok($bed_verifier->_robot_config, 'HASH', 'Sets the robot config');
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => '/processes/24-102433_a',
    ),
  );

  throws_ok { $bed_verifier->_robot_config }
    qr/Robot barcode must be set for bed verification/,
    'Throws if the robot barcode is not set';
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => '/processes/24-103751',
    ),
  );

  throws_ok { $bed_verifier->_robot_config }
    qr/Robot 010468 has not been configured for step working_dilution/,
    'Throws if the robot barcode is not set';
}

# Verify Bed Barcodes Are Correct
{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_b1',
    ),
  );

  my $process = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-102433_b1',
  );

  is($bed_verifier->_verify_bed_barcodes($process), 1, 'Verifies the bed barcodes are correct');
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_b4',
    ),
  );

  is($bed_verifier->_verify_bed_barcodes, 1, 'Verifies the bed and input/output barcodes are correct');
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_c',
    ),
  );

  throws_ok { $bed_verifier->_verify_bed_barcodes }
    qr/Bed something else can not be found in config for specified robot/,
    'Throws an error when a bed has a name not in the config';
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_d',
    ),
  );

  throws_ok { $bed_verifier->_verify_bed_barcodes }
    qr/Bed 2 barcode \(12345\) differs from config bed barcode \(580040002672\)/,
    'Throws an error when a bed has different barcode to the config';
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_e',
    ),
  );

  throws_ok { $bed_verifier->_verify_bed_barcodes }
    qr/Could not find any bed barcodes, please scan in at least one bed udf field/,
    'Throws an error when no bed has barcodes filled in';
}

{
  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $epp->new_object(
      step_name   => 'working_dilution',
      process_url => $base_url.'/processes/24-102433_b3',
    ),
  );
  my $process7 = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-102433_b3',
  );

  # $bed_verifier->_plate_mapping;
  throws_ok {$bed_verifier->_plate_mapping }
    qr/Not all plate barcodes have been filled out./,
    'Throws an error when not every bed barcodes has been filled in';

  # my $process8 = $epp->new_object(
  #   step_name => 'working_dilution',
  #   process_url => $base_url . '/processes/24-50647',
  # );

  # throws_ok {$bed_verifier->_verify_bed_barcodes }
  #   qr/Not all bed\(s\) barcode has been filled. Please, add all bed barcode value\(s\) to the form./,
  #   'Throws an error when not every bed barcodes has been filled in';
}

# Plate Mappings

{
  my $process = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-103751_a',
  );

  my $plate_mapping = [
    {source_plate => 1234, dest_plate => 5678}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  is_deeply($bed_verifier->_plate_mapping, $plate_mapping, 'Builds the plate mapping correctly');
}

{
  ## no.2
  my $process2 = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-102433_b',
  );

  my $plate_mapping2 = [
    {source_plate => 1, dest_plate => 5},
    {source_plate => 2, dest_plate => 6},
    {source_plate => 3, dest_plate => 7},
    {source_plate => 4, dest_plate => 8}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process2,
  );

  is_deeply($bed_verifier->_plate_mapping, $plate_mapping2, 'Builds the plate mapping correctly');
}

{
  ## no.3
  my $process3 = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-103751',
  );

  my $plate_mapping3 = [
    {source_plate => 1234, dest_plate => 5678},
    {source_plate => 1234, dest_plate => 9101},
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process3,
  );

  is_deeply($bed_verifier->_plate_mapping, $plate_mapping3, 'Builds the plate mapping correctly');
}

{
  ## no.4
  my $process4 = $epp->new_object(
    step_name   => 'working_dilution',
    process_url => $base_url.'/processes/24-103751_c',
  );

  my $plate_mapping4 = [
    {source_plate => 1234, dest_plate => 9999},
    {source_plate => 5678, dest_plate => 9999},
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process4,
  );

  is_deeply($bed_verifier->_plate_mapping, $plate_mapping4, 'Builds the plate mapping correctly');
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [{source_plate => 1234, dest_plate => 5678}];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1234, dest_plate => 5678}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  is($bed_verifier->_verify_plate_mapping($plate_map), 1, 'Verifies that the plates are correct');
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [{source_plate => 1234, dest_plate => 5678}];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1234, dest_plate => 1234}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  throws_ok { $bed_verifier->_verify_plate_mapping($plate_map) }
    qr/Expected source plate 1234 to be paired with destination plate 5678/,
    'Throws when incorrect plates in beds';
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [
        {source_plate => 1234, dest_plate => 5678},
        {source_plate => 1234, dest_plate => 9999}
      ];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1234, dest_plate => 5678},
    {source_plate => 1234, dest_plate => 9999}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  is($bed_verifier->_verify_plate_mapping($plate_map), 1, 'Verifies that the plates are correct 1 input => 2 outputs');
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [
        {source_plate => 1234, dest_plate => 5678},
        {source_plate => 1234, dest_plate => 9999}
      ];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1234, dest_plate => 5678},
    {source_plate => 1234, dest_plate => 8888}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  throws_ok { $bed_verifier->_verify_plate_mapping($plate_map) }
    qr/Expected source plate 1234 to be paired with destination plate 9999/,
    'Throws when incorrect plates in beds 1 input => 2 outputs';
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [
        {source_plate => 1111, dest_plate => 3333},
        {source_plate => 2222, dest_plate => 3333}
      ];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1111, dest_plate => 3333},
    {source_plate => 2222, dest_plate => 3333}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  is($bed_verifier->_verify_plate_mapping($plate_map), 1, 'Verifies that the plates are correct 2 inputs => 1 output');
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [
        {source_plate => 1111, dest_plate => 3333},
        {source_plate => 2222, dest_plate => 3333}
      ];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1111, dest_plate => 3333},
    {source_plate => 2345, dest_plate => 3333}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config => get_config(),
    epp    => $process,
  );

  throws_ok { $bed_verifier->_verify_plate_mapping($plate_map) }
    qr/Expected source plate 2222 to be paired with destination plate 3333/,
    'Throws when incorrect plates in beds 2 inputs => 1 output';
}

{
  my $process = Test::MockObject::Extends->new(
    $epp->new_object(
      step_name => 'testing',
      process_url => '1234',
    )
  );
  my $process_doc = Test::MockObject->new();

  $process_doc->mock(q{plate_io_map_barcodes}, sub {
      return [
        {source_plate => 1111},
        {source_plate => 2222}
      ];
    });

  $process->mock(q{process_doc}, sub {
      return $process_doc;
    });

  my $plate_map = [
    {source_plate => 1111},
    {source_plate => 2222}
  ];

  my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(
    config     => get_config(),
    input_only => 1,
    epp        => $process,
  );

  is($bed_verifier->_verify_plate_mapping($plate_map), 1, 'Input only test');
}

1;