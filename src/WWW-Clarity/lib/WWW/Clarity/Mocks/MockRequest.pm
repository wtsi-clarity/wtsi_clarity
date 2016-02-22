package WWW::Clarity::Mocks::MockRequest;
use Moose;
use Digest::MD5 qw(md5_hex);

extends 'WWW::Clarity::Request';

has '_cache' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {{}}
  );
has 'download' => (
    is  => 'ro',
    isa => 'Bool',
  );

sub to_filename {
  my ($self, $url) = @_;

  my ($filename) = ($url =~ qr/.*\/api\/v2\/(.*)/);
  $filename =~ s/\//_/;

  return "t/Data/$filename.xml";
}

sub to_filename_batch {
  my ($self, $urls) = @_;

  my $filename = md5_hex(map {
      ($_ =~ qr/.*\/api\/v2\/(.*)/);
    } @{$urls}
  );

  return "t/Data/$filename.xml";
}

sub get_xml {
  my ($self, $url) = @_;

  if (exists $self->_cache->{$url}) {
    return XML::LibXML->load_xml(
      string => $self->_cache->{$url},
    )->documentElement;

  } elsif ($self->download) {
    my $xml = $self->SUPER::get_xml($url);

    my $filename = $self->to_filename($url);
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $xml->toString;
    close $fh;

    return $xml;

  } else {
    my $filename = $self->to_filename($url);

    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    binmode $fh;

    my $xml = XML::LibXML->load_xml(
      IO => $fh,
    );

    close $fh;
    return $xml->documentElement;
  }
}

sub batch_get_xml {
  my ($self, $uris) = @_;

  if (exists $self->_cache->{$uris}) {
  } elsif ($self->download) {
    my $xml = $self->SUPER::batch_get_xml($uris);

    my $filename = $self->to_filename_batch($uris);
    open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
    print $fh $xml->toString;
    close $fh;

    return $xml;

  } else {
    my $filename = $self->to_filename_batch($uris);

    open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    binmode $fh;

    my $xml = XML::LibXML->load_xml(
      IO => $fh,
    );

    close $fh;
    return $xml->documentElement;
  }
}

sub put_xml {
  my ($self, $url, $xml) = @_;

  $self->_cache->{$url} = $xml->toString;
}

1;