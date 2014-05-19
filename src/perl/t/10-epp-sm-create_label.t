use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;

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
  my $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-67069');

  lives_and(sub {is $l->printer, 'd304bc'}, 'correct trimmed printer name');
  lives_and(sub {is $l->user, 'D. Brooks'}, 'correct user name');
  lives_and(sub {is $l->_num_copies, 2}, 'number of copies as given');
  lives_and(sub {is $l->_plate_purpose, 'Stock Plate'}, 'plate purpose as given');
  {
    local $ENV{'WTSI_CLARITY_HOME'} = 't';
    throws_ok {$l->_printer_url} qr/Validation failed for 'WtsiClarityReadableFile'/,
      'failed to get print service url';
  }

  $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-67069');
  #local $ENV{'WTSI_CLARITY_HOME'} = join q[/]. $ENV{'HOME'}, '.wtsi_clarity', 'config';
  lives_and(sub {like $l->_printer_url, qr/c2ed34d0-7214-0131-2f13-005056a81d80/}, 'got printer url');
}

{
  local $ENV{'WTSICLARITY_WEBCACHE_DIR'} = 't/data/create_label';
  my $l = wtsi_clarity::epp::sm::create_label->new(
    process_url => 'http://clarity-ap:8080/api/v2/processes/24-67069_custom');

  throws_ok { $l->printer} qr/Printer udf field should be defined/, 'error when printer not defined';
  lives_and(sub {is $l->user, q[]}, 'no user name by default');
  lives_and(sub {is $l->_num_copies, 1}, 'default number of copies');
  lives_and(sub {is $l->_plate_purpose, undef}, 'plate purpose undefined');
}


1;
