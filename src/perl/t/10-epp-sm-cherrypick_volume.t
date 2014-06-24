use strict;
use warnings;
use Test::More tests => 68;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;

use_ok('wtsi_clarity::epp::sm::cherrypick_volume', 'can use wtsi_clarity::epp::sm::cherrypick_volume' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );


my $espilon = 0.000001;

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/cherrypick_volume';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::cherrypick_volume->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-102066');

  lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (1), the class managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 5, 'In case (1), there should be 5 artifacts (Test Fixture).');

  my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
  my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);

  my %expected_result = (
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A251PA1?state=360076' => [5/45 , 10 - 5/45 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A252PA1?state=360082' => [5/3  , 10 - 5/3  ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A253PA1?state=360058' => [5/9  , 10 - 5/9  ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A254PA1?state=360086' => [5/35 , 10 - 5/35 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A255PA1?state=360078' => [2    , 10 - 2    ],
  );

  foreach my $sampleURI (keys %{$step->_targets})
  {
    my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
    my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
    cmp_ok(scalar @element_samples, '==', 1, 'In case (1), the sample volume should be present on the sample.');
    cmp_ok(scalar @element_buffers, '==', 1, 'In case (1), the buffer volume should be present on the sample.');
    my $element_sample = shift @element_samples;
    my $element_buffer = shift @element_buffers;
    cmp_ok(abs($element_sample->textContent - @{$expected_result{$sampleURI}}[0]), '<', $espilon, 'In case (1), the sample volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
    cmp_ok(abs($element_buffer->textContent - @{$expected_result{$sampleURI}}[1]), '<', $espilon, 'In case (1), the buffer volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
  }
}





{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/cherrypick_volume';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::cherrypick_volume->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-102067');

  lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (2), the class managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 11, 'In case (2), there should be 11 artifacts (Test Fixture).');

  my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
  my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);

  my %expected_result = (
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/201' => [ 25/450 ,  0.1 - 25/450 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/202' => [ 25/50  ,  0 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/203' => [ 1.0    ,  0 ],

    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/211' => [ 25/450 ,  0.1 - 25/450 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/212' => [ 25/75  ,  0.0 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/213' => [ 0.5    ,  0.0 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/214' => [ 0.5    ,  0.0 ],

    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/221' => [ 25/450 ,  0.1 - 25/450 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/222' => [ 25/75  ,  0 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/223' => [ 0.5    ,  0 ],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/224' => [ 0.5    ,  0 ],
  );

  foreach my $sampleURI (keys %{$step->_targets})
  {
    my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
    my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
    cmp_ok(scalar @element_samples, '==', 1, 'In case (2), the sample volume should be present on the sample.');
    cmp_ok(scalar @element_buffers, '==', 1, 'In case (2), the buffer volume should be present on the sample.');
    my $element_sample = shift @element_samples;
    my $element_buffer = shift @element_buffers;
    cmp_ok(abs($element_sample->textContent - @{$expected_result{$sampleURI}}[0]), '<', $espilon, 'In case (2), the sample volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
    cmp_ok(abs($element_buffer->textContent - @{$expected_result{$sampleURI}}[1]), '<', $espilon, 'In case (2), the buffer volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
  }
}







{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/sm/cherrypick_volume';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::cherrypick_volume->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-102068');

  lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (3), the class managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 5, 'In case (3), there should be 5 artifacts (Test Fixture).');

  my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
  my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);

  my %expected_result = (
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A251PA1?state=360076' => [50,''],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A252PA1?state=360082' => [50,''],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A253PA1?state=360058' => [50,''],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A254PA1?state=360086' => [50,''],
    'http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/artifacts/JON1301A255PA1?state=360078' => [ 2,''],
  );

  foreach my $sampleURI (keys %{$step->_targets})
  {
    my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
    my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
    cmp_ok(scalar @element_samples, '==', 1, 'In case (3), the sample volume should be present on the sample.');
    cmp_ok(scalar @element_buffers, '==', 1, 'In case (3), the buffer volume should be present on the sample.');
    my $element_sample = shift @element_samples;
    my $element_buffer = shift @element_buffers;
    cmp_ok(abs($element_sample->textContent - @{$expected_result{$sampleURI}}[0]), '<', $espilon, 'In case (3), the sample volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
    cmp_ok($element_buffer->textContent, 'eq', @{$expected_result{$sampleURI}}[1], 'In case (3), the buffer volume should be empty.');
  }
}
1;
