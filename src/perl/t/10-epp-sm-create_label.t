use strict;
use warnings;
use Test::More tests => 34;
use Test::Exception;
use DateTime;

local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];

use wtsi_clarity::util::config;
my $config = wtsi_clarity::util::config->new();
my $base_uri = $config->clarity_api->{'base_uri'};

use_ok('wtsi_clarity::epp::sm::create_label');

{
  my $l = wtsi_clarity::epp::sm::create_label->new(process_url => 'some');
  isa_ok($l, 'wtsi_clarity::epp::sm::create_label');
  ok (!$l->source_plate, 'source_plate flag is false by default');
  $l = wtsi_clarity::epp::sm::create_label->new(process_url => 'some', source_plate=>1, printer => 'myprinter');
  ok ($l->source_plate, 'source_plate flag can be set to true');
  lives_ok {$l->printer} 'printer given, no access to process url to get the printer';
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/create_label';
  #local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  local $ENV{'WTSI_CLARITY_HOME'}= q[t/data/config];
  my $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => $base_uri . '/processes/24-67069');

  lives_and(sub {is $l->printer, 'd304bc'}, 'correct trimmed printer name');
  lives_and(sub {is $l->user, 'D. Brooks'}, 'correct user name');
  lives_and(sub {is $l->_num_copies, 2}, 'number of copies as given');
  lives_and(sub {is $l->_plate_purpose, 'Stock Plate'}, 'plate purpose as given');

  $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => $base_uri . '/processes/24-67069');
  my $config = join q[/], $ENV{'HOME'}, '.wtsi_clarity', 'config';
  lives_and(sub {like $l->_get_printer_url('d304bc'), qr/c2ed34d0-7214-0131-2f13-005056a81d80/}, 'got printer url');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/create_label';
  my $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => $base_uri . '/processes/24-67069_custom');

  throws_ok { $l->printer} qr/Printer udf field should be defined/, 'error when printer not defined';
  lives_and(sub {is $l->user, q[]}, 'no user name by default');
  lives_and(sub {is $l->_num_copies, 1}, 'default number of copies');
  lives_and(sub {is $l->_plate_purpose, undef}, 'plate purpose undefined');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/create_label';
  #local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  my $l = wtsi_clarity::epp::sm::create_label->new(
     process_url => $base_uri . '/processes/24-67069',
     source_plate => 1,
     _date => my $dt = DateTime->new(
        year       => 2014,
        month      => 5,
        day        => 21,
        hour       => 15,
        minute     => 04,
        second     => 23,
    ),
  ); 
  lives_ok {$l->_container} 'got containers';
  my @containers = keys %{$l->_container};
  is (scalar @containers, 1, 'correct number of containers');
  my $container_url = $containers[0];
  is (scalar @{$l->_container->{$container_url}->{'samples'}}, 12, 'correct number of samples');

  my $doc = $l->_container->{$container_url}->{'doc'};
  my @nodes = $doc->findnodes(q{ /con:container/name });
  is ($nodes[0]->textContent(), 'ces_tester_101_', 'old container name');

  lives_ok {$l->_set_container_data} 'container data set';

  @nodes = $doc->findnodes( q{ /con:container/name } );
  is ($nodes[0]->textContent(), '5260271204834', 'new container name');
  my $xml =  $doc->toString;
  like ($xml, qr/WTSI Container Purpose Name\">Stock Plate/, 'container purpose present');
  like ($xml, qr/Supplier Container Name\">ces_tester_101_/, 'container supplier present');

  lives_ok {$l->_set_container_data} 'container data set is run again';
  $xml =  $doc->toString;
  like ($xml, qr/Supplier Container Name\">ces_tester_101_/, 'container supplier unchanged');

  my $label = {
          'label_printer' => { 'footer_text' => {
                                                  'footer_text2' => 'Wed May 21 15:04:23 2014',
                                                  'footer_text1' => 'footer by D. Brooks'
                                                },
                               'header_text' => {
                                                  'header_text2' => 'Wed May 21 15:04:23 2014',
                                                  'header_text1' => 'header by D. Brooks'
                                                },
                               'labels' => [
                                             {
                                               'template' => 'plate',
                                               'plate' => {
                                                            'ean13' => '5260271204834',
                                                            'label_text' => {
                                                                              'text5' => 'SM-271204S',
                                                                              'role' => 'Stock Plate',
                                                                              'text6' => 'QKJMF',
                                                                            },
                                                            'sanger' => '21-May-2014 '
                                                          }
                                             },
                                           ]
                             }
        };
  $label->{'label_printer'}->{'labels'}->[1] = $label->{'label_printer'}->{'labels'}->[0];

  is_deeply($l->_generate_labels(), $label, 'label hash representation');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/create_label';
  #local $ENV{'SAVE2WTSICLARITY_WEBCACHE'} = 1;
  
  my $dt = DateTime->new(
        year       => 2014,
        month      => 5,
        day        => 21,
        hour       => 15,
        minute     => 04,
        second     => 23,
  );

  my $l = wtsi_clarity::epp::sm::create_label->new(
     process_url => $base_uri . '/processes/24-97619',
     increment_purpose => 1,
     _date => $dt,
  ); 
  lives_ok {$l->_container} 'got containers';
  my @urls = keys %{$l->_container};
  is (scalar @urls, 2, 'correct number of containers');
  is (scalar @{$l->_container->{$urls[0]}->{'samples'}}, 95, 'correct number of samples');
  is (scalar @{$l->_container->{$urls[1]}->{'samples'}}, 95, 'correct number of samples');

  lives_ok {$l->_set_container_data} 'container data set';

  my $label = {
          'label_printer' => {
                               'footer_text' => {
                                                  'footer_text2' => 'Wed May 21 15:04:23 2014',
                                                  'footer_text1' => 'footer by D. Jones'
                                                },
                               'header_text' => {
                                                  'header_text2' => 'Wed May 21 15:04:23 2014',
                                                  'header_text1' => 'header by D. Jones'
                                                },
                               'labels' => [
                                             {
                                               'template' => 'plate',
                                               'plate' => {
                                                            'ean13' => '5260276710705',
                                                            'label_text' => {
                                                                              'text5' => 'SM-276710F',
                                                                              'role'  => 'Pico Assay A',
                                                                              'text6' => 'HP2MX'
                                                                            },
                                                            'sanger' => '21-May-2014 D. Jones'
                                                          }
                                             },
                                             {
                                               'template' => 'plate',
                                               'plate' => {
                                                            'ean13' => '5260276711719',
                                                            'label_text' => {
                                                                              'text5' => 'SM-276711G',
                                                                              'role'  => 'Pico Assay',
                                                                              'text6' => 'HP2MX'
                                                                            },
                                                            'sanger' => '21-May-2014 D. Jones'
                                                          }
                                             }
                                           ]
                             }
        };

  is_deeply($l->_generate_labels(), $label, 'label hash representation');

  $l = wtsi_clarity::epp::sm::create_label->new(
     process_url => $base_uri . '/processes/24-97619',
     _date => $dt,
  );

  lives_ok {$l->_container} 'got containers';
  lives_ok {$l->_set_container_data} 'container data set';

  # increment_purpose flag is false
  $label->{'label_printer'}->{'labels'}->[0]->{'plate'}->{'label_text'}->{'role'} = 'Pico Assay';
  is_deeply($l->_generate_labels(), $label, 'label hash representation');
}

1;
