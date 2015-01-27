package wtsi_clarity::dao::study_user_dao;

use Moose;
use Readonly;

with 'wtsi_clarity::dao::base_dao';

# In the ATTRIBUTES hash: an element's key is the attribute name
# and the element's value is the XPATH to get the attribute's value

Readonly::Hash  my %ATTRIBUTES => { 'first_name'  => q{/res:researcher/first-name},
                                    'last_name'   => q{/res:researcher/last-name},
                                    'login'       => q{/res:researcher/credentials/username},
                                    'email'       => q{/res:researcher/email},
                                  };

our $VERSION = '0.0';

has '+resource_type' => (
  default     => 'researchers',
);

has '+attributes' => (
  default     => sub { return \%ATTRIBUTES; },
);

has 'name' => (
  isa         => 'Str',
  is          => 'rw',
  required    => 0,
  lazy_build  => 1,
);
sub _build_name {
  my $self = shift;

  return join q{ }, $self->first_name, $self->last_name;
}

1;

__END__

=head1 NAME

wtsi_clarity::dao::study_user_dao

=head1 SYNOPSIS
  my $study_user_dao = wtsi_clarity::dao::study_user_dao->new(lims_id => "1234");
  $study_user_dao->to_message();

=head1 DESCRIPTION
 A data object representing a user of a study.
 Its data coming from the researcher artifact (XML file).

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
