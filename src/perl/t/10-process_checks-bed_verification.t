use strict;
use warnings;
use JSON;
use utf8;
use Test::More tests => 13;
use Test::Exception;

use_ok('wtsi_clarity::process_checks::bed_verification');

open( my $fh, '<:encoding(UTF-8)', 't/data/config/bed_verification.json' );
local $/;
my $json_text = <$fh>;
my $config = decode_json($json_text); 

{
  my $c = wtsi_clarity::process_checks::bed_verification->new(config => $config);
  isa_ok($c, 'wtsi_clarity::process_checks::bed_verification');
  can_ok($c, qw / config verify /);
}

# Tests for the verify method to make sure it throws correctly
{
  my $c = wtsi_clarity::process_checks::bed_verification->new(config => $config);  
  throws_ok { $c->verify('rubbish') }
    qr/bed verification config can not be found for process rubbish/,
    'throw error if the process name is not a valid process';

  throws_ok { $c->verify('working_dilution', 123123123) }
    qr/robot id incorrect for process working_dilution/,
    'throws an error if the robot id is incorrect';

  # Test for when a source bed doesn't exist
  my @source = ({ bed => 99999, barcode => 123});
  my @destination = ({ bed => 3, barcode => 580040003686 });
  my @mappings = ({
    source => \@source,
    destination => \@destination
  });

  throws_ok { $c->verify('working_dilution', '009851', \@mappings) }
    qr/ Bed 99999 is not source bed for process /,
    'throws an error when the bed number does not exist';

  # Test for when a source bed barcode is incorrect
  @source = ({ bed => 2, barcode => 123 });
  @destination = ({ bed => 3, barcode => 580040003686 });
  @mappings = ({
    source => \@source, 
    destination => \@destination 
  });

  throws_ok { $c->verify('working_dilution', '009851', \@mappings) }
    qr/ Barcode for source bed 2 is different /,
    'throws an error when one of the source bed barcodes is incorrect';
}

# Tests to make sure we get back the correct value
# All the positive ones...
{
  my $c = wtsi_clarity::process_checks::bed_verification->new(config => $config);

  my @source = ({ bed => 2, barcode => 5800400002672 });
  my @destination = ({ bed => 3, barcode => 580040003686 });
  my @mappings = ({
    source => \@source,
    destination => \@destination 
  });

  is($c->verify('working_dilution', '009851', \@mappings), 1, 'Returns the correct result with one source/destination mapping'); 

  # Multiple outputs
  @source = ({ bed => 6, barcode => 580030006666 });
  @destination = (
    { bed => 7, barcode => 580030007670 },
    { bed => 8, barcode => 580030008684 },
  );
  @mappings = ({
    source => \@source,
    destination => \@destination  
  });

  is($c->verify('pico_assay_plate', '010468', \@mappings), 1, 'Returns correct result for multiple destinations');

  @source = ({ bed => 1, barcode => 580020001794 }, { bed => 2, barcode => 580020002807 });
  @destination = ({ bed => 21, barcode => 580020021839 });
  @mappings = ({
    source => \@source,
    destination => \@destination
  });
  is($c->verify('fluidigm_192_24_ifc', '014219', \@mappings), 1, "Returns correct result for multiple sources");
}

# Tests to make sure we get back the correct value
# All the negative ones...
{
  my $c = wtsi_clarity::process_checks::bed_verification->new(config => $config);

  my @source = ({ bed => 2, barcode => 5800400002672 });
  my @destination = ({ bed => 4, barcode => 580040323423 });
  my @mappings = ({
    source => \@source,
    destination => \@destination 
  });

  is($c->verify('working_dilution', '009851', \@mappings), 0, 'Returns the correct result with one source/destination mapping'); 

  # Multiple outputs
  @source = ({ bed => 6, barcode => 580030006666 });
  @destination = (
    { bed => 7, barcode => 580030007670 },
    { bed => 9, barcode => 580032342344 },
  );
  @mappings = ({
    source => \@source,
    destination => \@destination  
  });

  is($c->verify('pico_assay_plate', '010468', \@mappings), 0, 'Returns correct result for multiple destinations');

  @source = ({ bed => 1, barcode => 580020001794}, { bed => 2, barcode => 580020002807 });
  @destination = ({ bed => 22, barcode => 523424321839 });
  @mappings = ({
    source => \@source,
    destination => \@destination
  });
  is($c->verify('fluidigm_192_24_ifc', '014219', \@mappings), 0, "Returns correct result for multiple sources");
}
