package wtsi_clarity::mq::messages::flowcell::lane;

use Moose;
use MooseX::Storage;
use Moose::Util::TypeConstraints;
use wtsi_clarity::mq::messages::flowcell::sample;
use wtsi_clarity::mq::messages::flowcell::control;

our $VERSION = '0.0';

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

subtype 'WtsiClarityMessageFlowcellSamples'
      => as 'ArrayRef[wtsi_clarity::mq::messages::flowcell::sample]';

coerce 'WtsiClarityMessageFlowcellSamples',
      from 'ArrayRef[HashRef]',
      via {
        my @samples = map { wtsi_clarity::mq::messages::flowcell::sample->new($_) } @{$_};
        return \@samples;
      };

subtype 'WtsiClarityMessageFlowcellControls'
      => as 'ArrayRef[wtsi_clarity::mq::messages::flowcell::control]';

coerce 'WtsiClarityMessageFlowcellControls',
      from 'ArrayRef[HashRef]',
      via {
        my @controls = map { wtsi_clarity::mq::messages::flowcell::control->new($_) } @{$_};
        return \@controls;
      };

my @defaults = ( is => 'ro', isa => 'Str', required => 1 );

has ['entity_type', 'id_pool_lims'] => @defaults;

has 'position' => @defaults, isa => 'Int';

has 'samples' => @defaults, isa => 'WtsiClarityMessageFlowcellSamples', coerce => 1;

has 'controls' => @defaults, isa => 'WtsiClarityMessageFlowcellControls', coerce   => 1;

1;

__END__

=head1 NAME

wtsi_clarity::mq::messages::flowcell::lane

=head1 SYNOPSIS

  my $lane = wtsi_clarity::mq::messages::flowcell::lane->new({
    entity_type  => 'library',
    id_pool_lims => 'DN324095D A1:H2',
    position     => 1,
    samples      => [{
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
    }],
  );

  $sample->freeze();

=head1 DESCRIPTION

  This message probably does not need to be used directly. wtsi_clarity::mq::messages::flowcell::flowcell will coerce its
  lane attribute to an array containing wtsi_clarity::mq::messages::flowcell::lane s.

  This class also coerces samples and controls from arrays of hashes.

=head1 SUBROUTINES/METHODS

=head2 freeze

  Creates a JSON representation of the class

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Storage

=item Moose::Util::TypeConstraints

=item wtsi_clarity::mq::messages::flowcell::sample

=item wtsi_clarity::mq::messages::flowcell::control

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
