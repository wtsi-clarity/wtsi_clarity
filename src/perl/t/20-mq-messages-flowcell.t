use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use_ok 'wtsi_clarity::mq::messages::flowcell::flowcell';

{
  my $flowcell = wtsi_clarity::mq::messages::flowcell::flowcell->new(
    flowcell_barcode    => '123456778903',
    flowcell_id         => '24-12345',
    forward_read_length => 222,
    reverse_read_length => 222,
    updated_at          => '2014-04-13 10:22:42',
    lanes               => [{
      entity_type  => 'library',
      id_pool_lims => 'DN324095D A1:H2',
      entity_id_lims             => '29-098',
      position     => 1,
      samples      => [{
        tag_sequence               => 'ATAG',
        tag_set_name               => 'Sanger_168tags - 10 mer tags',
        pipeline_id_lims           => 'GCLP',
        entity_type                => 'library_indexed',
        bait_name                  => 'DDD_V5_plus',
        sample_uuid                => '00000000-0000-0000-000000000',
        study_uuid                 => '00000000-0000-0000-000000001',
        id_study_lims              => '28-12345',
        cost_code                  => '12345',
        entity_id_lims             => '12345',
        is_r_and_d                 => 'false',
        tag_index                  => 3,
        requested_insert_size_from => 100,
        requested_insert_size_to   => 200,
        id_library_lims            => '1234567890',
      }],
      controls    => [{
        sample_uuid                => '00000000-0000-0000-00000003',
        study_uuid                 => '00000000-0000-0000-00000004',
        tag_index                  => 3,
        entity_type                => 'library_indexed_spike',
        tag_sequence               => 'ATAG',
        tag_set_id_lims            => '2',
        entity_id_lims             => '12345',
        tag_set_name               => 'Sanger_168tags - 10 mer tags',
        id_library_lims            => '1234567890',
        pipeline_id_lims           => 'GCLP-CLARITY-ISC',
      }],
    }],
  );

  my $json;
  lives_ok { $json = $flowcell->pack() } 'Can create an object from the class' ;
}