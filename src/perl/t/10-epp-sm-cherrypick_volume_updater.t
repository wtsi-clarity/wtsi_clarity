use strict;
use warnings;
use Test::More tests => 74;
use Test::Exception;
use DateTime;
use XML::LibXML;
use Carp;
use lib qw ( t );
use util::xml;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
my $base_uri = q{http://testserver.com:1234/here};

use_ok('wtsi_clarity::epp::sm::cherrypick_volume_updater', 'can use wtsi_clarity::epp::sm::cherrypick_volume_updater' );
use_ok('util::xml', 'can use wtsi_clarity::t::util::xml' );

my $epsilon = 0.000001;

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/cherrypick_volume_updater';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::cherrypick_volume_updater->new(
    process_url => $base_uri . '/processes/24-102066');

  lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (1), the class managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 5, 'In case (1), there should be 5 artifacts (Test Fixture).');

  my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
  my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);

  my %expected_result = (
    $base_uri . '/artifacts/JON1301A251PA1?state=360076' => [5/45 , 10 - 5/45 ],
    $base_uri . '/artifacts/JON1301A252PA1?state=360082' => [5/3  , 10 - 5/3  ],
    $base_uri . '/artifacts/JON1301A253PA1?state=360058' => [5/9  , 10 - 5/9  ],
    $base_uri . '/artifacts/JON1301A254PA1?state=360086' => [5/35 , 10 - 5/35 ],
    $base_uri . '/artifacts/JON1301A255PA1?state=360078' => [2    , 10 - 2    ],
  );

  foreach my $sampleURI (keys %{$step->_targets})
  {
    my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
    my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
    cmp_ok(scalar @element_samples, '==', 1, 'In case (1), the sample volume should be present on the sample.');
    cmp_ok(scalar @element_buffers, '==', 1, 'In case (1), the buffer volume should be present on the sample.');
    my $element_sample = (shift @element_samples)->textContent;
    my $element_buffer = (shift @element_buffers)->textContent;

    my $expected_sample = @{$expected_result{$sampleURI}}[0];
    my $expected_buffer = @{$expected_result{$sampleURI}}[1];

    cmp_ok(abs($element_sample - $expected_sample), '<', $epsilon, 'In case (1), the sample volume should be as expected ('.($expected_sample).' rather than '.$element_sample.').');
    cmp_ok(abs($element_buffer - $expected_buffer), '<', $epsilon, 'In case (1), the buffer volume should be as expected ('.($expected_buffer).' rather than '.$element_buffer.').');
  }
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/cherrypick_volume_updater';
  # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $step = wtsi_clarity::epp::sm::cherrypick_volume_updater->new(
    process_url => $base_uri . '/processes/24-102067');

  lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (2), the class managed to fetch and updates the artifact';

  cmp_ok(scalar keys %{$step->_targets}, '==', 12, 'In case (2), there should be 12 artifacts (Test Fixture).');

  my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
  my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);

  my %expected_result = (
    $base_uri . '/artifacts/201' => [ 25/450 ,  0.1 - 25/450 ],
    $base_uri . '/artifacts/202' => [ 25/50  ,  0 ],
    $base_uri . '/artifacts/203' => [ 1.0    ,  0 ],
    $base_uri . '/artifacts/204' => [ 1.0    ,  0 ],

    $base_uri . '/artifacts/211' => [ 25/450 ,  0.1 - 25/450 ],
    $base_uri . '/artifacts/212' => [ 25/75  ,  0.0 ],
    $base_uri . '/artifacts/213' => [ 0.5    ,  0.0 ],
    $base_uri . '/artifacts/214' => [ 0.5    ,  0.0 ],
    $base_uri . '/artifacts/221' => [ 25/600 ,  0.1 - 25/600 ],
    $base_uri . '/artifacts/222' => [ 0.05   ,  0.1 - 0.05   ],
    $base_uri . '/artifacts/223' => [ 0.05   ,  0.1 - 0.05   ],
    $base_uri . '/artifacts/224' => [ 0.05   ,  0.1 - 0.05   ],
  );

  foreach my $sampleURI (keys %expected_result) #{$step->_targets})
  {
    my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
    my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
    cmp_ok(scalar @element_samples, '==', 1, 'In case (2), the sample volume should be present on the sample.');
    cmp_ok(scalar @element_buffers, '==', 1, 'In case (2), the buffer volume should be present on the sample.');
    my $element_sample = (shift @element_samples)->textContent + 0;
    my $element_buffer = (shift @element_buffers)->textContent + 0;

    my $expected_sample = @{$expected_result{$sampleURI}}[0]   + 0;
    my $expected_buffer = @{$expected_result{$sampleURI}}[1]   + 0;

    cmp_ok(abs($element_sample - $expected_sample), '<', $epsilon, 'In case (2), the sample volume should be as expected ('.($expected_sample).' rather than '.$element_sample.').');
    cmp_ok(abs($element_buffer - $expected_buffer), '<', $epsilon, 'In case (2), the buffer volume should be as expected ('.($expected_buffer).' rather than '.$element_buffer.').');
  }
}




#
#
#
# {
#   local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/sm/cherrypick_volume_updater';
#   # local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
#   my $step = wtsi_clarity::epp::sm::cherrypick_volume_updater->new(
#     process_url => $base_uri . '/processes/24-102068');
#
#   lives_ok { $step->fetch_and_update_targets($step->process_doc) } 'In case (3), the class managed to fetch and updates the artifact';
#
#   cmp_ok(scalar keys %{$step->_targets}, '==', 5, 'In case (3), there should be 5 artifacts (Test Fixture).');
#
#   my $SAMPLE_PATH = q(/art:artifact/udf:field[@name='Cherrypick Sample Volume']);
#   my $BUFFER_PATH = q(/art:artifact/udf:field[@name='Cherrypick Buffer Volume']);
#
#   my %expected_result = (
#     $base_uri . '/artifacts/JON1301A251PA1?state=360076' => [50,''],
#     $base_uri . '/artifacts/JON1301A252PA1?state=360082' => [50,''],
#     $base_uri . '/artifacts/JON1301A253PA1?state=360058' => [50,''],
#     $base_uri . '/artifacts/JON1301A254PA1?state=360086' => [50,''],
#     $base_uri . '/artifacts/JON1301A255PA1?state=360078' => [ 2,''],
#   );
#
#   foreach my $sampleURI (keys %{$step->_targets})
#   {
#     my @element_samples = util::xml::find_elements( $step->_targets->{$sampleURI}, $SAMPLE_PATH) ;
#     my @element_buffers = util::xml::find_elements( $step->_targets->{$sampleURI}, $BUFFER_PATH) ;
#     cmp_ok(scalar @element_samples, '==', 1, 'In case (3), the sample volume should be present on the sample.');
#     cmp_ok(scalar @element_buffers, '==', 1, 'In case (3), the buffer volume should be present on the sample.');
#     my $element_sample = shift @element_samples;
#     my $element_buffer = shift @element_buffers;
#     cmp_ok(abs($element_sample->textContent - @{$expected_result{$sampleURI}}[0]), '<', $espilon, 'In case (3), the sample volume should be as expected ('.(@{$expected_result{$sampleURI}}[0]+0).' rather than '.$element_sample->textContent.').');
#     cmp_ok($element_buffer->textContent, 'eq', @{$expected_result{$sampleURI}}[1], 'In case (3), the buffer volume should be empty.');
#   }
# }
1;
