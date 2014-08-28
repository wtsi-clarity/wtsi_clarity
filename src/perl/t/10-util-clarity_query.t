use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use_ok('wtsi_clarity::util::clarity_query');

{

  my $test_data = [
    { 'input' => {
        'sample_id' => 1234567890,
        'step' => 'Hello hello',
        'type' => 'Analyte'
      },
      'resource' => 'artifacts',
      'expected' => 'samplelimsid=1234567890&process-type=Hello hello&type=Analyte',
    },
    { 'input' => {
        'artifact_id' => [ 1234567890, 987654321, 1234567765432 ],
      },
      'resource' => 'processes',
      'expected' => 'inputartifactlimsid=1234567890&inputartifactlimsid=987654321&inputartifactlimsid=1234567765432',
    },
    { 'input' => {
        'artifact_id' => [ 1234567890, ],
      },
      'resource' => 'processes',
      'expected' => 'inputartifactlimsid=1234567890',
    },
    { 'input' => {
        'sample_id' => 1234567890,
        'type' => 'Analyte'
      },
      'resource' => 'artifacts',
      'expected' => 'samplelimsid=1234567890&type=Analyte',
    },
    { 'input' => {
        'sample_id' => 1234567890,
        'step' => 'Hello hello',
      },
      'resource' => 'artifacts',
      'expected' => 'samplelimsid=1234567890&process-type=Hello hello',
    },
    { 'input' => {
        'sample_id' => 1234567890,
      },
      'resource' => 'artifacts',
      'expected' => 'samplelimsid=1234567890',
    },
  ];

  foreach my $data (@{$test_data}) {
    my $results = wtsi_clarity::util::clarity_query::_build_query($data->{'resource'}, $data->{'input'});
    cmp_ok($results, 'eq', $data->{'expected'}, '_build_query should return the correct value.');
  }
}
1;
