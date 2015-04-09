package wtsi_clarity::mq::messages::flowcell::control;

use Moose;
use MooseX::Storage;

our $VERSION = '0.0';

with Storage( 'traits' => ['OnlyWhenBuilt'],
              'format' => 'JSON',
              'io' => 'File' );

my @defaults = ( is => 'ro', isa => 'Str', required => 1 );

has [
     'tag_sequence',
     'tag_set_name',
     'entity_type',
     'sample_uuid',
     'study_uuid',
     'entity_id_lims',
    ] => @defaults;

has 'tag_index' => @defaults, isa => 'Int';

1;

__END__

=head1 NAME

wtsi_clarity::mq::messages::flowcell::control

=head1 SYNOPSIS

  my $control = wtsi_clarity::mq::messages::flowcell::control->new(
    sample_uuid                => '00000000-0000-0000-00000003',
    study_uuid                 => '00000000-0000-0000-00000004',
    tag_index                  => 3,
    entity_type                => 'library_indexed_spike',
    tag_sequence               => 'ATAG',
    tag_set_id_lims            => '2',
    entity_id_lims             => '12345',
    tag_set_name               => 'Sanger_168tags - 10 mer tags',
  );

  $control->freeze();

=head1 DESCRIPTION

  This message probably does not need to be used directly. wtsi_clarity::mq::messages::flowcell::lane will coerce its
  control attribute to an array containing wtsi_clarity::mq::messages::flowcell::control s.

=head1 SUBROUTINES/METHODS

=head2 freeze

  Creates a JSON representation of the class

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Storage;

=item wtsi_clarity::util::types;

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
