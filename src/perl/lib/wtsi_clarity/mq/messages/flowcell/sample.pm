package wtsi_clarity::mq::messages::flowcell::sample;

use Moose;
use MooseX::Storage;

our $VERSION = '0.0';

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

with 'wtsi_clarity::mq::messages::packer';

my @defaults = ( is => 'ro', isa => 'Str', required => 1 );

has [
     'tag_sequence',
     'tag_set_name',
     'pipeline_id_lims',
     'entity_type',
     'bait_name',
     'sample_uuid',
     'cost_code',
     'is_r_and_d',
     'id_library_lims',
    ] => @defaults;

has [
    'study_uuid',
    'study_id',
    'requested_insert_size_from',
    'requested_insert_size_to',] => @defaults, required => 0;

has [
     'tag_index',
    ] => @defaults, isa => 'Int';

1;

__END__

=head1 NAME

wtsi_clarity::mq::messages::flowcell::sample

=head1 SYNOPSIS

  my $sample = wtsi_clarity::mq::messages::flowcell::sample->new(
    tag_sequence               => 'ATAG',
    tag_set_name               => 'Sanger_168tags - 10 mer tags',
    pipeline_id_lims           => 'GCLP',
    entity_type                => 'library_indexed',
    bait_name                  => 'DDD_V5_plus',
    sample_uuid                => '00000000-0000-0000-000000000',
    study_uuid                 => '00000000-0000-0000-000000001',
    cost_code                  => '12345',
    entity_id_lims             => '12345',
    is_r_and_d                 => 'false',
    tag_index                  => 3,
    requested_insert_size_from => 100,
    requested_insert_size_to   => 200,
  );

  $sample->freeze();

=head1 DESCRIPTION

  This message probably does not need to be used directly. wtsi_clarity::mq::messages::flowcell::lane will coerce its
  sample attribute to an array containing wtsi_clarity::mq::messages::flowcell::sample s.

=head1 SUBROUTINES/METHODS

=head2 freeze

  Creates a JSON representation of the class

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Storage

=item wtsi_clarity::mq::messages::packer

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
