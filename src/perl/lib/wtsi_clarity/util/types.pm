package wtsi_clarity::util::types;

use Moose::Util::TypeConstraints;
use XML::LibXML::NodeList;
use wtsi_clarity::util::clarity_bed;
use wtsi_clarity::util::clarity_plate;

our $VERSION = '0.0';

subtype 'WtsiClarityReadableFile'
      => as 'Str'
      => where { -r };

subtype 'WtsiClarityExecutable'
      => as 'Str'
      => where { -x };

subtype 'WtsiClarityDirectory'
      => as 'Str'
      => where { -d };

subtype 'NodeList'
      => as 'XML::LibXML::NodeList';

subtype 'WtsiClarityProcessBeds'
      => as 'ArrayRef[wtsi_clarity::util::clarity_bed]';

coerce 'WtsiClarityProcessBeds',
      from 'NodeList',
      via {
        my @beds = map { wtsi_clarity::util::clarity_bed->new(element => $_) } $_->get_nodelist;
        return \@beds;
      };

subtype 'WtsiClarityPlates'
      => as 'ArrayRef[wtsi_clarity::util::clarity_plate]';

coerce 'WtsiClarityPlates',
      from 'NodeList',
      via {
        my @plates = map { wtsi_clarity::util::clarity_plate->new(element => $_) } $_->get_nodelist;
        return \@plates;
      };

duck_type 'HasRequestAndConfig', [qw/request config/];

duck_type 'WtsiClarityPoolingStrategy', [qw/get_pool_name dest_well_position/];

duck_type 'WtsiClarityMessageHandler', [qw/process/];

no Moose::Util::TypeConstraints;

1;
__END__

=head1 NAME

wtsi_clarity::util::types

=head1 SYNOPSIS

  package mypackage;
  use wtsi_clarity::util::types;

  has 'dir_path'  => (
    isa  => 'WtsiClarityDirectory',
  );

=head1 DESCRIPTION

  Custom Moose types for the wtsi_clarity project.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Util::TypeConstraints

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL

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
