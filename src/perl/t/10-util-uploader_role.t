use strict;
use warnings;
use Test::More tests => 12;
use Cwd;
use XML::LibXML;


##################  start of test class ####################
package test::10_util_uploader_role_test_class;
use Moose;
use Carp;
use XML::LibXML;
use Readonly;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::uploader_role';

# no Moose;
##################  end of test class ####################
package main;
use lib qw ( t );
use util::xml;

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/util/uploader_role';

  my $doc = wtsi_clarity::util::uploader_role::_get_storage_request("resource_name", "path");
  my $xpc = XML::LibXML::XPathContext->new($doc->getDocumentElement());

  my @elements = $xpc->findnodes( q{/file:file/attached-to });
  cmp_ok(scalar @elements, '==', 1, q{The 'attached-to' field should be added to the container.} );
  cmp_ok($elements[0]->textContent(), 'eq', "resource_name", 'The resource_name should be correct');

  @elements = $xpc->findnodes( q{/file:file/content-location });
  cmp_ok(scalar @elements, '==', 1, q{The 'content-location' field should be added to the container.} );
  cmp_ok($elements[0]->textContent(), 'eq', "path", 'The content-location should be correct');

  @elements = $xpc->findnodes( q{/file:file/original-location });
  cmp_ok(scalar @elements, '==', 1, q{The 'original-location' field should be added to the container.} );
  cmp_ok($elements[0]->textContent(), 'eq', "path", 'The original-location should be correct');

  my ($server, $dir, $filename) = wtsi_clarity::util::uploader_role::_extract_locations("sftp://myserver.com/here/andhere/down/here/myfile.pdf");
  cmp_ok($server, 'eq', 'myserver.com', 'The server extraction should be correct');
  cmp_ok($dir, 'eq', 'here/andhere/down/here', 'The directory extraction should be correct');
  cmp_ok($filename, 'eq', 'myfile.pdf', 'The filename extraction should be correct');

  ($server, $dir, $filename) = wtsi_clarity::util::uploader_role::_extract_locations("torrent://myserver.com/here/andhere/down/here/myfile.pdf");
  is($server, undef, 'The server extraction should be correct (undef when wrong)');
  is($dir, undef,  'The directory extraction should be correct (undef when wrong)');
  is($filename, undef, 'The filename extraction should be correct (undef when wrong)');
}

1;
