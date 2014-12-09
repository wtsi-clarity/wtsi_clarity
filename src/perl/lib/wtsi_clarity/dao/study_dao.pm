package wtsi_clarity::dao::study_dao;

use Moose;
use Readonly;

use wtsi_clarity::util::artifact_reader;

with 'wtsi_clarity::dao::base_dao';

Readonly::Scalar my $STUDY_NAME_PATH                => q{/prj:project/name};

Readonly::Array  my @STUDY_ATTRIBUTES                        => qw/ name
                                                                  /;

our $VERSION = '0.0';

has 'resource_type' => (
  isa         => 'Str',
  is          => 'ro',
  required    => 0,
  default     => 'projects',
);

foreach my $study_attribute ( @STUDY_ATTRIBUTES ) {
  has $study_attribute => (
    isa             => 'Str',
    is              => 'rw',
    required        => 0,
    lazy_build      => 1,
  );
}

sub _build_name {
  my $self = shift;

  return $self->findvalue($STUDY_NAME_PATH);
}

sub init {
  my $self = shift;

  foreach my $study_attribute ( @STUDY_ATTRIBUTES ) {
    $self->$study_attribute;
  }

  return;
}

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

=head2 init
  Initialize the data object with its data.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
