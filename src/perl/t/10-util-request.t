use strict;
use warnings;
use Test::More tests => 18;
use Test::Exception;
use Test::MockObject::Extends;
use File::Path;

use_ok('wtsi_clarity::util::request');

sub read_file {
  my $file_path = shift;

  local $/=undef;
  open my $fh,  $file_path or die "Couldn't open file";
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
    $data = $r->get(q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/processes/24-28177})
           } 'no error retrieving from cache';
  ok(!$r->base_url, 'base url not set');

  my $xml = read_file('t/data/cached/GET/processes/24-28177');

  is ($data, $xml, 'content retrieved correctly');
}

## Caching stuff...
{
  my $test_dir = 't/data/util/request/';
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = $test_dir;
  
  my $r = wtsi_clarity::util::request->new();
  $r = Test::MockObject::Extends->new($r);

  my %methods = (
    post => 'POST',
    put  => 'PUT',
    del  => 'DELETE',
  );

  foreach my $method (keys %methods) {
    my $test_url = 'http://www.fakeurl.com/api/v2/artifacts/123456';
    my $method_val = $methods{$method};
    local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
    
    $r->mock(q{_from_web}, sub {
      my ($self, $type, $uri, $content, $path) = @_;
      my $body = qq/$type - $uri/;
      return $body;
    });

    $r->$method($test_url, '<link>1</link><link>2</link>');

    my $file_contents = read_file($test_dir . qq{$method_val/artifacts/123456});

    is($file_contents, qq/$method_val - $test_url/, 'file written to correct place');

    $r->unmock(q{_from_web});

    $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 0;
    is($r->$method($test_url, 'nothing'), qq/$method_val - $test_url/, 'reads from the cache when SAVE2WTSICLARITY_WEBCACHE is false')
  }

  ## Cleanup
  File::Path::remove_tree($test_dir, { keep_root => 1 });
}

{
  SKIP: {
    if ( !$ENV{'LIVE_TEST'} ) {
      skip 'set LIVE_TEST to true to run', 5;
    }
    my $base = q{http://clarity-ap.internal.sanger.ac.uk:8080/api/v2};
    my $samples_uri = $base . q{/samples};
    my $sample_uri = $samples_uri . q{/GOU51A7};
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
    <project limsid="GOU51" uri="] . $base . q[/projects/GOU51"/>
    <date-received>2014-05-01</date-received>
    <location><container limsid="27-151" uri="] . $base . q[/containers/27-151"/><value>H:12</value></location>
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
