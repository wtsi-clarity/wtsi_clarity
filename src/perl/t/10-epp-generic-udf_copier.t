use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

use_ok 'wtsi_clarity::epp::generic::udf_copier';

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/udf_copier/';

{
  my $process = wtsi_clarity::epp::generic::udf_copier->new(
    process_url  => 'http://testserver.com:1234/here/processes/24-67093',
    from_process => 'Pre Capture Lib Pooling',
    fields       => ['Average Molarity'],
  );

  my @input_analytes = $process->_input_artifacts->findnodes('art:details/art:artifact');


  throws_ok { wtsi_clarity::epp::generic::udf_copier->new(process_url => 'fake', from_process => 'process') }
    'Moose::Exception::AttributeIsRequired',
    'Throws an exception when fields are not passed in';

  throws_ok { wtsi_clarity::epp::generic::udf_copier->new(process_url => 'fake', fields => ['molarity']) }
    'Moose::Exception::AttributeIsRequired',
    'Throws an exception when from_process is not passed in';

  isa_ok($process->_input_artifacts, 'XML::LibXML::Document', 'Input artifacts');

  my @expected_sample_list = qw/ SV2454A112 SV2454A114 SV2454A115 /;

  my @sample_list = $process->_sample_list_from_artifact($input_analytes[0]);

  is_deeply(\@sample_list, \@sample_list, 'Gets the samples from an artifact');

  $process->_copy_fields();

  my $average_molarity  = $process->_input_artifacts->findvalue('art:details/art:artifact[1]/udf:field[@name="Average Molarity"]');
  my $average_molarity2 = $process->_input_artifacts->findvalue('art:details/art:artifact[2]/udf:field[@name="Average Molarity"]');

  is($average_molarity, '223.07745', 'Copies the molarity to the first input analyte');
  is($average_molarity2, '334.40805', 'Copies the molarity to the second input analyte');
}

{
  # Make sure it can do multiple fields
  my $process = wtsi_clarity::epp::generic::udf_copier->new(
    process_url  => 'http://testserver.com:1234/here/processes/24-67093',
    from_process => 'Pre Capture Lib Pooling',
    fields       => ['Average Molarity', 'Concentration'],
  );

  $process->_copy_fields();

  my $average_molarity  = $process->_input_artifacts->findvalue('art:details/art:artifact[1]/udf:field[@name="Average Molarity"]');
  my $average_molarity2 = $process->_input_artifacts->findvalue('art:details/art:artifact[2]/udf:field[@name="Average Molarity"]');

  my $concentration  = $process->_input_artifacts->findvalue('art:details/art:artifact[1]/udf:field[@name="Concentration"]');
  my $concentration2 = $process->_input_artifacts->findvalue('art:details/art:artifact[2]/udf:field[@name="Concentration"]');

  is($average_molarity, '223.07745', 'Copies the molarity to the first input analyte');
  is($average_molarity2, '334.40805', 'Copies the molarity to the second input analyte');

  is($concentration, '12345', 'Copies the concentration to the first input analyte');
  is($concentration2, '78945', 'Copies the concentration to the second input analyte');
}

{
  # Make sure it croaks when not all fields are set for the "from_process"
  my $process = wtsi_clarity::epp::generic::udf_copier->new(
    process_url  => 'http://testserver.com:1234/here/processes/24-67093',
    from_process => 'Pre Capture Lib Pooling',
    fields       => ['Average Molarity', 'Concentration', 'Croaker'],
  );

  throws_ok { $process->_copy_fields() }
    qr/Field Croaker has not been set on all artifacts at Pre Capture Lib Pooling/,
    'Throws an error when not all artifacts have all fields set';
}

1;