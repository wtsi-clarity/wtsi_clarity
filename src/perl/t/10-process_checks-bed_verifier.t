use strict;
use warnings;
use JSON;
use utf8;
use Moose::Meta::Class;
use Test::More tests => 21;
use Test::Exception;
use Test::MockObject;

use_ok('wtsi_clarity::process_checks::bed_verifier');

sub get_config {
  open( my $fh, '<:encoding(UTF-8)', 't/data/config/bed_verification.json' );
  local $/;
  my $json_text = <$fh>;
  my $config = decode_json($json_text);
}

local $ENV{'WTSI_CLARITY_HOME'} = q[t/data/config];

my $epp = Moose::Meta::Class
            ->create_anon_class(
              superclasses => ['wtsi_clarity::epp::generic::bed_verifier'],
            );

my $base_url = 'http://testserver.com:1234/here/';
my $bed_verifier = wtsi_clarity::process_checks::bed_verifier->new(config => get_config());

{
  isa_ok($bed_verifier, 'wtsi_clarity::process_checks::bed_verifier');
  can_ok($bed_verifier, qw / config verify /);
}

# Step Config
{
  my $process1 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => 'fake url',
  );

  $bed_verifier->_verify_step_config($process1);

  isa_ok($bed_verifier->_step_config, 'HASH', 'Creates the step config');

  my $process2 = $epp->new_object(
    step_name => 'rubbish',
    process_url => 'fake url',
  );

  throws_ok { $bed_verifier->_verify_step_config($process2) }
    qr/Bed verification config can not be found for process rubbish/,
    'Throws when it can not find the step config';
}

# Robot Config
{

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process1 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => 'processes/24-102433',
  );

  $bed_verifier->_verify_robot_config($process1);
  isa_ok($bed_verifier->_robot_config, 'HASH', 'Sets the robot config');

  my $process2 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => 'processes/24-102433_a',
  );

  throws_ok { $bed_verifier->_verify_robot_config($process2) }
    qr/Robot barcode must be set for bed verification/,
    'Throws if the robot barcode is not set';

  my $process3 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => 'processes/24-103751',
  );

  throws_ok { $bed_verifier->_verify_robot_config($process3) }
    qr/Robot 010468 has not been configured for step working_dilution/,
    'Throws if the robot barcode is not set';
}

# Verify Bed Barcodes Are Correct
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-102433_b',
  );

  is($bed_verifier->_verify_bed_barcodes($process), 1, 'Verifies the bed barcodes are correct');

  my $process2 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-102433_c',
  );

  throws_ok { $bed_verifier->_verify_bed_barcodes($process2) }
    qr/Bed something else can not be found in config for specified robot/,
    'Throws an error when a bed has a name not in the config';

  my $process3 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-102433_d',
  );

  throws_ok { $bed_verifier->_verify_bed_barcodes($process3) }
    qr/Bed 2 barcode \(12345\) differs from config bed barcode \(580040002672\)/,
    'Throws an error when a bed has different barcode to the config';
}

# Plate Mappings

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-103751_a',
  );

  my $plate_mapping = [
    {source_plate => 1234, dest_plate => 5678}
  ];

  is_deeply($bed_verifier->_plate_mapping($process), $plate_mapping, 'Builds the plate mapping correctly');

  ## no.2
  my $process2 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-102433_b',
  );

  my $plate_mapping2 = [
    {source_plate => 1, dest_plate => 5},
    {source_plate => 2, dest_plate => 6},
    {source_plate => 3, dest_plate => 7},
    {source_plate => 4, dest_plate => 8}
  ];

  is_deeply($bed_verifier->_plate_mapping($process2), $plate_mapping2, 'Builds the plate mapping correctly');

  ## no.3
  my $process3 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-103751',
  );

  my $plate_mapping3 = [
    {source_plate => 1234, dest_plate => 5678},
    {source_plate => 1234, dest_plate => 9101},
  ];

  is_deeply($bed_verifier->_plate_mapping($process2), $plate_mapping2, 'Builds the plate mapping correctly');

  ## no.4
  my $process4 = $epp->new_object(
    step_name => 'working_dilution',
    process_url => $base_url . 'processes/24-103751_c',
  );

  my $plate_mapping4 = [
    {source_plate => 1234, dest_plate => 9999},
    {source_plate => 5678, dest_plate => 9999},
  ];

  is_deeply($bed_verifier->_plate_mapping($process4), $plate_mapping4, 'Builds the plate mapping correctly');

}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';;

  my $process = Test::MockObject->new();
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

  is($bed_verifier->_verify_plate_mapping($process, $plate_map), 1, 'Verifies that the plates are correct');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = Test::MockObject->new();
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

  throws_ok { $bed_verifier->_verify_plate_mapping($process, $plate_map) }
    qr/Expected source plate 1234 to be paired with destination plate 5678/,
    'Throws when incorrect plates in beds';
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = Test::MockObject->new();
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

  is($bed_verifier->_verify_plate_mapping($process, $plate_map), 1, 'Verifies that the plates are correct 1 input => 2 outputs');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = Test::MockObject->new();
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

  throws_ok { $bed_verifier->_verify_plate_mapping($process, $plate_map) }
    qr/Expected source plate 1234 to be paired with destination plate 9999/,
    'Throws when incorrect plates in beds 1 input => 2 outputs';
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = Test::MockObject->new();
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

  is($bed_verifier->_verify_plate_mapping($process, $plate_map), 1, 'Verifies that the plates are correct 2 inputs => 1 output');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/bed_verifier/working_dilution/';

  my $process = Test::MockObject->new();
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

  throws_ok { $bed_verifier->_verify_plate_mapping($process, $plate_map) }
    qr/Expected source plate 2222 to be paired with destination plate 3333/,
    'Throws when incorrect plates in beds 2 inputs => 1 output';
}

1;