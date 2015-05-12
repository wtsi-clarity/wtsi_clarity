package wtsi_clarity::dao::sample_dao;

use Moose;
use Readonly;
use POSIX qw(strftime);

with 'wtsi_clarity::dao::base_dao';

# In the ATTRIBUTES hash: an element's key is the attribute name
# and the element's value is the XPATH to get the attribute's value

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash  my %ATTRIBUTES  => {  'id_sample_lims'   => q{/smp:sample/@limsid},
                                      'uuid_sample_lims' => q{/smp:sample/name},
                                      'name' => q{/smp:sample/name},
                                      'reference_genome' => q{/smp:sample/udf:field[@name='Reference Genome']},
                                      'organism' => q{/smp:sample/udf:field[@name='WTSI Organism']},
                                      'common_name' => q{/smp:sample/udf:field[@name='WTSI Supplier Sample Name (SM)']},
                                      'taxon_id' => q{/smp:sample/udf:field[@name='WTSI Taxon ID']},
                                      'gender' => q{/smp:sample/udf:field[@name='WTSI Supplier Gender - (SM)']},
                                      'control' => q{/smp:sample/udf:field[@name='Control?']},
                                      'supplier_name' => q{/smp:sample/udf:field[@name='WTSI Supplier']},
                                      'public_name' => q{/smp:sample/udf:field[@name='WTSI Supplier Sample Name (SM)']},
                                      'donor_id' => q{/smp:sample/udf:field[@name='WTSI Donor ID']},
                                    };

Readonly::Scalar my $PROJECT_LIMSID => q{/smp:sample/project/@limsid};
Readonly::Scalar my $BAIT_LIBRARY_PATH => q{/smp:sample/udf:field[@name='WTSI Bait Library Name']};
## use critic

our $VERSION = '0.0';

has 'project_limsid' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_build_project_limsid',
  traits      => [ 'DoNotSerialize' ],
);
sub _build_project_limsid {
  my $self = shift;
  return $self->findvalue($PROJECT_LIMSID);
}

has 'bait_library_name' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_build_bait_library_name',
  traits  => ['DoNotSerialize'],
);
sub _build_bait_library_name {
  my $self = shift;
  return $self->findvalue($BAIT_LIBRARY_PATH);
}

has 'last_updated' => (
  is => 'ro',
  isa => 'Str',
  default => sub {
    return strftime('%Y-%m-%Od %H:%M:%S', localtime);
  },
);

has '+resource_type' => (
  default     => 'samples',
);

has '+attributes' => (
  default     => sub { return \%ATTRIBUTES; },
);

1;

__END__

=head1 NAME

wtsi_clarity::dao::sample_dao

=head1 SYNOPSIS
  my $sample_dao = wtsi_clarity::dao::sample_dao->new(lims_id => "1234");
  $sample_dao->to_message();

=head1 DESCRIPTION
 A data object representing a sample.
 Its data coming from the sample artifact (XML file).

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item wtsi_clarity::dao::base_dao

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
