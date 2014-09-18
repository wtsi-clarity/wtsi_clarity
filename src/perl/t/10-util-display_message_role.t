use strict;
use warnings;
use Test::MockObject::Extends;
use Test::Exception;
use wtsi_clarity::util::request;
use XML::LibXML;
use Test::More tests => 9;

my $base_uri = q{http://some.com/anything};

sub _testXML {
  my ($str, $msg, $level) = @_;

  my $parser = XML::LibXML->new();
  my $xml = $parser->parse_string($str);

  is($xml->findvalue('//message'), $msg);
  is($xml->findvalue('//status'), $level);

  return;
}

sub _create_fake_epp_class {
  my $mocked_request = shift;

  return Moose::Meta::Class->create_anon_class(
    superclasses  => [qw /wtsi_clarity::epp/],
    roles         => [qw /wtsi_clarity::util::display_message_role /]
  )->new_object(
    process_url  => $base_uri . q[/processes/123456],
    # step_url => $base_uri. '/steps/123456', 
    request => $mocked_request
  );
}

# Tests for displaying an error message
{
  my $error_message = 'Test error message';
  my $mocked_request = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $mocked_request->mock(q(put), sub {
     my ($self, $url, $param) = @_;

     _testXML($param, $error_message, 'ERROR');
    });

  my $fake_class = _create_fake_epp_class($mocked_request);

  throws_ok { $fake_class->display_error($error_message) } 
    qr /Test error message/, 'Displaying an error message has succeeded.';
}

# Tests for displaying an info message
{
  my $info_message = 'This is an information message';
  my $mocked_request = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $mocked_request->mock(q(put), sub {
     my ($self, $url, $param) = @_;

     _testXML($param, $info_message, 'INFO');
    });

  my $fake_class = _create_fake_epp_class($mocked_request);

  $fake_class->display_info($info_message);
}

# Tests for displaying a debug message
{
  my $debug_message = 'This is a debug message';
  my $mocked_request = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $mocked_request->mock(q(put), sub {
     my ($self, $url, $param) = @_;

     _testXML($param, $debug_message, 'DEBUG');
    });

  my $fake_class = _create_fake_epp_class($mocked_request);

  $fake_class->display_debug($debug_message);
}

# Tests for displaying an info message
{
  my $warning_message = 'This is a warning message';
  my $mocked_request = Test::MockObject::Extends->new( q(wtsi_clarity::util::request) );
  $mocked_request->mock(q(put), sub {
     my ($self, $url, $param) = @_;

     _testXML($param, $warning_message, 'WARNING');
    });

  my $fake_class = _create_fake_epp_class($mocked_request);

  $fake_class->display_warning($warning_message);
}

