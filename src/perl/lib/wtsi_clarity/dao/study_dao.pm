package wtsi_clarity::dao::study_dao;

use Moose;
use Readonly;

with 'wtsi_clarity::dao::base_dao';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Hash  my %ATTRIBUTES => { name                        => q{/prj:project/name},
                                    reference_genome            => q{/prj:project/udf:field[@name='WTSI Study reference genome']},
                                    state                       => q{/prj:project/udf:field[@name='WTSI Project State']},
                                    study_type                  => q{/prj:project/udf:field[@name='WTSI Type']},
                                    abstract                    => q{/prj:project/udf:field[@name='WTSI Project Abstract']},
                                    abbreviation                => q{/prj:project/udf:field[@name='WTSI Project Abbreviation']},
                                    accession_number            => q{/prj:project/udf:field[@name='WTSI Accession Number']},
                                    description                 => q{/prj:project/udf:field[@name='WTSI Project Description']},
                                    contains_human_dna          => q{/prj:project/udf:field[@name='WTSI Do samples contain Human DNA?']},
                                    contaminated_human_dna      => q{/prj:project/udf:field[@name='WTSI Contaminated with Human DNA that needs removal?']},
                                    data_release_strategy       => q{/prj:project/udf:field[@name='WTSI Release Strategy']},
                                    data_release_timing         => q{/prj:project/udf:field[@name='WTSI Data release timing']},
                                    data_access_group           => q{/prj:project/udf:field[@name='WTSI Data Access Group']},
                                    study_title                 => q{/prj:project/udf:field[@name='WTSI Study Title for Publishing']},
                                    ega_dac_accession_number    => q{/prj:project/udf:field[@name='WTSI Accession Number']},
                                    remove_x_and_autosomes      => q{/prj:project/udf:field[@name='WTSI Does the study require the removal of X-chromosome and autosome sequence?']},
                                    separate_y_chromosome_data  => q{/prj:project/udf:field[@name='WTSI Does the study require the removal of Y-chromosome and autosome sequence?']},
                                  };
## use critic

our $VERSION = '0.0';

has '+resource_type' => (
  default     => 'projects',
);

has '+attributes' => (
  default     => sub { return \%ATTRIBUTES; },
);

1;

__END__

=head1 NAME

wtsi_clarity::dao::study_dao

=head1 SYNOPSIS
  my $study_dao = wtsi_clarity::dao::study_dao->new(lims_id => "1234");
  $study_dao->to_message();

=head1 DESCRIPTION
 A data object representing a study.
 Its data coming from the study artifact (XML file).

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
