use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

use_ok('wtsi_clarity::epp::stamp');

{
  my $s = wtsi_clarity::epp::stamp->new(process_url => 'some');
  isa_ok($s, 'wtsi_clarity::epp::stamp');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/stamp';
  local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $s = wtsi_clarity::epp::stamp->new(process_url => 'http://clarity-ap:8080/api/v2/processes/24-98502');
  lives_ok { $s->_analytes } 'got all info from clarity';
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container');
  is (scalar keys $s->_analytes->{$containers[0]}, 6, 'five input analytes and a container doc');

  is ($s->container_name, 'ABgene 0800', 'container name retrieved correctly');
  my $type_xml;
  lives_ok {$type_xml = $s->_container_type} 'container type retrieved';
  is ($type_xml->findvalue(q{ ./@uri }), "http://clarity-ap.internal.sanger.ac.uk:8080/api/v2/containertypes/105",
    'container type value');

  delete $s->_analytes->{$containers[0]}->{'doc'};
  my @wells = sort map { $s->_analytes->{$containers[0]}->{$_}->{'well'} } (keys %{$s->_analytes->{$containers[0]}});
  is (join(q[ ], @wells), 'B:11 D:11 E:11 G:9 H:9', 'sorted wells');
}
1;
