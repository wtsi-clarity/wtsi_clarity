use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use DateTime;
use File::Temp qw/ tempdir /;

use_ok('wtsi_clarity::epp::reports::report');
use_ok('wtsi_clarity::mq::message');

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

{
  my $manifest = wtsi_clarity::epp::reports::report->new( process_url => 'http://clarity.com/processes/1' );
  isa_ok($manifest, 'wtsi_clarity::epp::reports::report',
    'Creates a wtsi_clarity::epp::reports::report when passed just a process_url');
}

{
  my $manifest = wtsi_clarity::epp::reports::report->new( container_id => [qw/24-123/] );
  isa_ok($manifest, 'wtsi_clarity::epp::reports::report',
    'Creates a wtsi_clarity::epp::reports::report when passed just a container_id');
}

{
  my $message  = wtsi_clarity::mq::message->create('report',
    process_url => 'http://clarity.com/processes/1',
    step_url    => 'http://clarity.com/steps/1',
    purpose     => '14MG_sample_manifest',
    timestamp   => DateTime->now(),
  );
  my $manifest = wtsi_clarity::epp::reports::report->new( message => $message );
  isa_ok($manifest, 'wtsi_clarity::epp::reports::report',
    'Creates a wtsi_clarity::epp::reports::report when passed just a message');
  is($manifest->process_url, 'http://clarity.com/processes/1', '...and sets the process_url when message is set');
}

{
  my $manifest = wtsi_clarity::epp::reports::report->new(
    process_url => 'http://clarity.com/processes/1',
    publish_to_irods  => 1
  );

  my @headers = ();
  my @file_content = ('test');

  my $file = $manifest->_file_factory->create(
      type      => 'report_writer',
      headers   => \@headers,
      data      => \@file_content,
      delimiter => $manifest->file_delimiter,
    );

  my $filename = '123456.manifest.txt';

  my $dir = tempdir(CLEANUP => 1);

  like ($file->saveas(join q{/}, $dir, $filename), qr/$filename/, 'save the temporary file with a correct name');
}


# {
#   throws_ok { wtsi_clarity::epp::reports::report->new() }
#     qr/Either process_url or message must be passed for generating a report/,
#     'Throws an error when none of the arguments are passed in';
# }

1;