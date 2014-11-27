use strict;
use warnings;

use Test::More tests => 2;

use_ok('wtsi_clarity::mq::dao::sample_dao');

{
  my $lims_id = '1234';
  my $sample_dao = wtsi_clarity::mq::dao::sample_dao->new( lims_id => $lims_id);
  isa_ok($sample_dao, 'wtsi_clarity::mq::dao::sample_dao');
}