use strict;
use warnings;
use Test::More tests => 20;
use Test::Exception;
use Test::MockObject::Extends;
use File::Temp qw/ tempdir /;
use Digest::MD5;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::util::request');

sub read_file {
  my $file_path = shift;

  local $/=undef;
  open my $fh,  $file_path or die "Couldn't open file $file_path";
  my $content = <$fh>;
  close $fh;
  return $content;
}

## Instanstiates correctly...
{
  my $r = wtsi_clarity::util::request->new();
  isa_ok( $r, 'wtsi_clarity::util::request');
  is ($r->cache_dir_var_name, q[WTSICLARITY_WEBCACHE_DIR], 'cache dir var name');
  is ($r->save2cache_dir_var_name, q[SAVE2WTSICLARITY_WEBCACHE], 'save2cache dir var name');
}

## GET Request
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/cached/';
  local $ENV{'http_proxy'} = 'http://wibble';
  my $r = wtsi_clarity::util::request->new();
  my $data;
  lives_ok {
    $data = $r->get($base_uri . q{/processes/24-28177})
           } 'no error retrieving from cache';

  my $xml = read_file('t/data/cached/GET/processes/24-28177');

  is ($data, $xml, 'content retrieved correctly');
}


{ # _create_path
  my $data = [
    {
      input   => {
        'url'     => $base_uri . '/resource/resource_id',
        'type'    => 'GET',
        'content' => undef,
      },
      expected => '/GET/resource/resource_id',
    },
    {
      input   => {
        'url'     => $base_uri . '/resource/resource_id',
        'type'    => 'POST',
        'content' => 'payload',
      },
      expected => '/POST/resource/resource_id' . wtsi_clarity::util::request::_decorate_resource_name('payload'),
    }
  ];

    use Data::Dumper;
  my $r = wtsi_clarity::util::request->new();

  foreach my $datum (@{$data}) {
    my $url     = $datum->{'input'}->{'url'};
    my $type    = $datum->{'input'}->{'type'};
    my $content = $datum->{'input'}->{'content'};
    my $path = $r->_create_path($url, $type, $content);

    if (!defined $content) {
      $content = q{(no payload)};
    }
    cmp_ok($path, 'eq', $datum->{'expected'} , qq/_create_path should return the correct cache path (from $url, $type, $content)/);
  }
}

{ # _decorate_resource_name
  my $data = [
    {
      input    => 'payload',
      expected => "_" . Digest::MD5::md5_hex('payload'),
    }
  ];
  my $r = wtsi_clarity::util::request->new();

  foreach my $datum (@{$data}) {
    my $content = $datum->{'input'};
    my $result = wtsi_clarity::util::request::_decorate_resource_name($content);
    cmp_ok($result, 'eq', $datum->{'expected'} , qq/_decorate_resource_name should return the correct value (from $content)/);
  }
}

## Caching stuff...
{
  my $test_dir = tempdir( CLEANUP => 1);
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;

  my $r = wtsi_clarity::util::request->new();
  $r = Test::MockObject::Extends->new($r);

  my %methods_tested = (
    post => {verb => 'POST',   payload => '<link>1</link><link>2</link>' },
    put  => {verb => 'PUT',    payload => 'payload'                      },
    del  => {verb => 'DELETE'                                            },
  );

  foreach my $method (keys %methods_tested) {
    my $test_url = $base_uri . '/artifacts/123456';
    my $method_verb = $methods_tested{$method}->{'verb'};
    local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
    my $file_path = $test_dir . qq{/$method_verb/artifacts/123456};

    $r->mock(q{_from_web}, sub {
      my ($self, $type, $uri, $content, $path) = @_;
      my $body = qq/$type - $uri/;
      return $body;
    });

    my $payload = $methods_tested{$method}->{'payload'};
    my $deco = q{};
    if ($payload) {
      $deco = wtsi_clarity::util::request::_decorate_resource_name( $payload );
    }
    $r->$method($test_url, $payload);

    my $file_contents = read_file($file_path.$deco);

    is($file_contents, qq/$method_verb - $test_url/, qq{file written to correct place ($method_verb - $test_url)});

    $r->unmock(q{_from_web});

    $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
    is($r->$method($test_url, $payload), qq/$method_verb - $test_url/, qq{reads from the cache when SAVE2WTSICLARITY_WEBCACHE is false ($method_verb - $test_url)} )
  }

}

{
  SKIP: {
    if ( !$ENV{'LIVE_TEST'} ) {
      skip 'set LIVE_TEST to true to run', 5;
    }

    local $ENV{'WTSI_CLARITY_HOME'}= q[];
    my $config = wtsi_clarity::util::config->new();
    my $live_base_uri = $config->clarity_api->{'base_uri'};

    my $samples_uri = $live_base_uri . q{/samples};
    my $sample_uri = $samples_uri . q{/SMI102A12};

    my $r = wtsi_clarity::util::request->new();
    my $data = $r->get($sample_uri);
    ok($data, 'data received');
    is($r->base_url, 'clarity-ap.internal.sanger.ac.uk:8080', 'base url correct');
    my $old_date = '2013-10-31';
    my $new_date = '2013-10-21';
    if ($data =~ /$new_date/) {
      my $temp = $new_date;
      $new_date = $old_date;
      $old_date = $temp;
    }
    $data =~ s/$old_date/$new_date/;
    my $new_data;
    $r = wtsi_clarity::util::request->new();
    lives_ok {$new_data = $r->put($sample_uri, $data)}
     'put request succeeds';
    ok($new_data =~ /$new_date/, 'amended sample data returned');

    my $sample = q[<smp:samplecreation xmlns:smp="http://genologics.com/ri/sample" xmlns:udf="http://genologics.com/ri/userdefined">
    <name>mar_ina_test-11</name>
    <project limsid="GOU51" uri="] . $base_uri . q[/projects/GOU51"/>
    <date-received>2014-05-01</date-received>
    <location><container limsid="27-151" uri="] . $base_uri . q[/containers/27-151"/><value>H:12</value></location>
    <udf:field name="WTSI Sample Consent Withdrawn">false</udf:field>
    <udf:field name="WTSI Requested Size Range From">600</udf:field>
    <udf:field name="Reference Genome">Homo_sapiens (1000Genomes)</udf:field>
    </smp:samplecreation>
    ];

    throws_ok {$new_data = $r->post($samples_uri, $sample)}
      qr/The container placement: H:12 is a duplicate for container: 27-151/,
      'cannot create a new sample in the same well'

    #lives_ok {$new_data = $r->post($sample_uri)}
    #  'delete request succeeds';
    #diag $new_data;
  }
}

1;
