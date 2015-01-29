use strict;
use warnings;
use Test::More tests => 54;
use Test::Exception;
use File::Temp qw/tempdir/;
use File::Slurp;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use_ok('wtsi_clarity::epp::generic::stamper');
my $base_uri =  'http://testserver.com:1234/here' ;

{
  my $s = wtsi_clarity::epp::generic::stamper->new(process_url => 'some', step_url => 'some');
  isa_ok($s, 'wtsi_clarity::epp::generic::stamper');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp';
  #local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => 'http://testserver.com:1234/here/processes/24-98502',
              step_url => 'some');
  lives_ok { $s->_analytes } 'got all info from clarity';
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container');
  is (scalar keys %{$s->_analytes->{$containers[0]}}, 6, 'five input analytes and a container doc');

  is ($s->container_type_name->[0], 'ABgene 0800', 'container name retrieved correctly');
  is ($s->_validate_container_type, 0, 'container type validation flag unset');
  is ($s->_container_type->[0],
     '<type uri="http://testserver.com:1234/here/containertypes/105" name="ABgene 0800"/>',
     'container type value');

  delete $s->_analytes->{$containers[0]}->{'doc'};
  my @wells = sort map { $s->_analytes->{$containers[0]}->{$_}->{'well'} } (keys %{$s->_analytes->{$containers[0]}});
  is (join(q[ ], @wells), 'B:11 D:11 E:11 G:9 H:9', 'sorted wells');

}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp';
  my $s = wtsi_clarity::epp::generic::stamper->new(
    process_url => $base_uri . '/processes/24-98502',
    step_url    => 'some'
  );
  lives_ok { $s->_analytes } 'got all info from clarity';

  my @container_urls = keys %{$s->_analytes};
  my $climsid = '27-4536';
  my $curi = 'http://c.com/containers/' . $climsid;
  $s->_analytes->{$container_urls[0]}->{'output_container'}->{'limsid'} = $climsid;
  $s->_analytes->{$container_urls[0]}->{'output_container'}->{'uri'} = $curi;

  my $doc;
  lives_ok { $doc = $s->_create_placements_doc } 'placement doc created';
  lives_ok { $s->_direct_stamp($doc) } 'individual placements created';
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp_with_control';
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => $base_uri . '/processes/24-99904',
              step_url => 'some');
  lives_ok { $s->_analytes } 'got all info from clarity (no container type name)';
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container, control tube is skipped');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp_with_control';
  #local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => $base_uri . '/processes/24-99904',
              step_url => 'some',
              container_type_name => ['ABgene 0800']);
  lives_ok { $s->_analytes } q{got all info from clarity ('ABgene 0800')};
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container, control tube is skipped');
  ok ($s->_validate_container_type, 'validate container flag is true');
  is ($s->_container_type->[0],
      '<type uri="' . $base_uri . '/containertypes/105" name="ABgene 0800"/>',
      'container type derived correctly from name');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp_with_control';
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => $base_uri . '/processes/24-99904',
              step_url => 'some',
              container_type_name => ['ABgene 0765', 'ABgene 0800']);

  lives_ok { $s->_analytes } q{got all info from clarity ('ABgene 0765', 'ABgene 0800')};
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container, control tube is skipped');
  is (scalar(map { $_ =~ /\Ahttp/ } keys %{$s->_analytes->{$containers[0]}}), 4, 'control will not be stamped');

  ok ($s->_validate_container_type, 'validate container flag is true');
  is (scalar @{$s->_container_type}, 2, 'two container types retrieved');
  is ($s->_container_type->[0],
      '<type uri="' . $base_uri . '/containertypes/106" name="ABgene 0765"/>',
      'first container type derived correctly from name');
  is ($s->_container_type->[1],
      '<type uri="' . $base_uri . '/containertypes/105" name="ABgene 0800"/>',
      'second container type derived correctly from name');

}

{
  my $dir = tempdir(CLEANUP => 1);
  `cp -R t/data/epp/generic/stamper/stamp_with_control $dir`;
   #remove tube container from test data
  `rm $dir/stamp_with_control/GET/containers.27-7555`;
  my $control = "$dir/stamp_with_control/GET/artifacts.151C-801PA1?state=359614";
  my $control_xml = read_file $control;
  $control_xml =~ s/27-7555/27-7103/g;  #place control on the input plate
  $control_xml =~ s/1:1/H:12/g;         #in well H:12
  open my $fh, '>', $control or die "cannot open filehandle to write to $control";
  print $fh $control_xml or die "cannot write to $control";
  close $fh;

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = "$dir/stamp_with_control";
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => $base_uri . '/processes/24-99904',
              step_url => 'some',
              with_controls => 1);
  lives_ok { $s->_analytes } 'got all info from clarity';
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container');
  is (scalar(map { $_ =~ /\Ahttp/ } keys %{$s->_analytes->{$containers[0]}}), 5,
    'control will be stamped when with_controls flag is true');
}

{
  my $dir = tempdir(CLEANUP => 1);
  `cp -R t/data/epp/generic/stamper/stamp_with_control $dir`;
   #remove tube container from test data
  `rm $dir/stamp_with_control/GET/containers.27-7555`;
  my $control = "$dir/stamp_with_control/GET/artifacts.151C-801PA1?state=359614";
  my $control_xml = read_file $control;
  $control_xml =~ s/27-7555/27-7103/g;  #place control on the input plate
  $control_xml =~ s/1:1/H:12/g;         #in well H:12
  open my $fh, '>', $control or die "cannot open filehandle to write to $control";
  print $fh $control_xml or die "cannot write to $control";
  close $fh;

  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = "$dir/stamp_with_control";
  my $s = wtsi_clarity::epp::generic::stamper->new(
              process_url => $base_uri . '/processes/24-99904',
              step_url => 'some',
              shadow_plate => 1);
  lives_ok { $s->_analytes } 'got all info from clarity';
  my @containers = keys %{$s->_analytes};
  is (scalar @containers, 1, 'one input container');
  is (scalar(map { $_ =~ /\Ahttp/ } keys %{$s->_analytes->{$containers[0]}}), 5,
    'control will be stamped when it is a shadow plate');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp';
  my $s = wtsi_clarity::epp::generic::stamper->new(
            process_url => $base_uri . '/processes/24-16122',
            step_url => 'some',
          );

  my $climsid = '27-4536';
  my $curi = 'http://c.com/containers/' . $climsid;
  my $h = {
    'limsid' => $climsid,
    'uri'    => $curi,
  };
  foreach my $analyte (keys %{$s->_analytes}) {
    push @{$s->_analytes->{$analyte}->{'output_containers'}}, $h;
  }

  my $doc;
  my $output_placements;
  lives_ok { $doc = $s->_create_placements_doc } 'Can create placements doc';
  lives_ok { $output_placements = $s->_stamp_with_copy($doc) } 'Can create placements';
}

{

  my $s = wtsi_clarity::epp::generic::stamper->new(
            process_url => 'http://testserver.com:1234/here/processes/24-16122',
            step_url => 'some',
            copy_on_target => 0
          );

  my ($well1, $well2) = $s->calculate_destination_wells('A:1');
  is($well1, 'A:1', 'The first well is A:1');
  is($well2, 'B:1', 'The second well is B:1');

  my ($well3, $well4) = $s->calculate_destination_wells('B:1');
  is($well3, 'C:1', 'The first well is C:1');
  is($well4, 'D:1', 'The second well is D:1');

  my ($well5, $well6) = $s->calculate_destination_wells('A:2');
  is($well5, 'A:3', 'The first well is A:3');
  is($well6, 'B:3', 'The second well is B:3');

  my ($well7, $well8) = $s->calculate_destination_wells('E:1');
  is($well7, 'I:1', 'The first well is I:1');
  is($well8, 'J:1', 'The second well is J:1');

  my ($well9, $well10) = $s->calculate_destination_wells('H:1');
  is($well9, 'O:1', 'The first well is O:1');
  is($well10, 'P:1', 'The second well is P:1');

  throws_ok { $s->calculate_destination_wells('I:1') } qr/Source plate must be a 96 well plate/,
    'Only accepts 96 well plates';
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/stamp_shadow';
  use Mojo::Collection 'c';

  my $expected = { '27-2001' => 'barcode-00001-0002'};
  my $s = wtsi_clarity::epp::generic::stamper->new(
            process_url => 'http://testserver.com:1234/here/processes/24-16122',
            step_url => 'some',
            shadow_plate => 1
          );

  $s->_create_containers();
  my $doc = $s->_create_placements_doc;
  $doc = $s->_direct_stamp($doc);

  $s->_update_plate_name_with_previous_name();
  my $res = $s->_output_container_details;

  my $details = c->new($res->findnodes( qq{/con:details/con:container} )->get_nodelist())
    ->reduce(sub {
      my $id = $b->findvalue( qq{\@limsid} );
      my $barcode = $b->findvalue( qq{name/text()} );
      $a->{$id} = $barcode;
      $a;
    }, {});

  is_deeply($details, $expected, qq{_update_plate_name_with_previous_name should update the _output_container_details with the correct name.});
}

# Group artifacts on output plate by input plate
{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/epp/generic/stamper/group';

  my $analytes = {
    'input_container_1' => {
      'output_containers' => [
        { uri => 'Con 1', limsid => 1, }
      ],
      'analyte1' => { well => 'A:1', target_analyte_uri => ['target01'] }
    },
    'input_container_2' => {
      'output_containers' => [
        { uri => 'Con 1', limsid => 1, }
      ],
      'analyte3' => { well => 'D:1', target_analyte_uri => ['target03'] },
      'analyte4' => { well => 'E:1', target_analyte_uri => ['target04'] },
      'analyte5' => { well => 'F:1', target_analyte_uri => ['target05'] },
      'analyte6' => { well => 'G:1', target_analyte_uri => ['target06'] },
    },
    'input_container_3' => {
      'output_containers' => [
        { uri => 'Con 1', limsid => 1, }
      ],
      'analyte7' => { well => 'G:1', target_analyte_uri => ['target07'] },
      'analyte8' => { well => 'E:4', target_analyte_uri => ['target08'] },
      'analyte9' => { well => 'G:3', target_analyte_uri => ['target09'] },
      'analyte10' => { well => 'C:5', target_analyte_uri => ['target10'] },
    }
  };

  my $s = wtsi_clarity::epp::generic::stamper->new(
    process_url => 'http://testserver.com:1234/here/processes/24-25701',
    step_url => 'http://testserver.com:1234/here/steps/24-25350',
    group => 1,
    _analytes => $analytes,
  );

  my $doc = $s->_create_placements_doc;

  $doc = $s->_group_inputs_by_container_stamp($doc);

  my @wells = ('A:1', 'B:1', 'C:1', 'D:1', 'E:1', 'F:1', 'G:1', 'H:1', 'A:2');

  foreach my $placement ($doc->findnodes('/stp:placements/output-placements/output-placement')->get_nodelist()) {
    is($placement->findvalue('./location/value'), shift @wells, 'Puts in correct well');
  }

}

1;
