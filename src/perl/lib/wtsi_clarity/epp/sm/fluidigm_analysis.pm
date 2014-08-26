package wtsi_clarity::epp::sm::fluidigm_analysis;

use Moose;
use Carp;
use Readonly;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $FIRST_ANALYTE_PATH => q{ /prc:process/input-output-map[1]/input/@uri };
Readonly::Scalar my $CONTAINER_PATH => q{ /art:artifact/location/container/@uri };
Readonly::Scalar my $CONTAINER_NAME => q{ /con:container/name };
## use critic

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';

our $VERSION = '0.0';

has '_filename' => (
  isa => 'Any',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__filename {
  my $self = shift;
  my $container_hash = $self->fetch_targets_hash($FIRST_ANALYTE_PATH, $CONTAINER_PATH);
  my $container = (values $container_hash)[0];
  return $container->findvalue($CONTAINER_NAME);
}

sub _get_filepath {
  my $self = shift;
  return join q{/}, $self->config->robot_file_dir->{'fluidigm_analysis'}, $self->_filename;
}

override 'run' => sub {
  my $self = shift;
  super();

  # Find file
  my $filepath = $self->_get_filepath();

  # Parse the file

  # Update the sample with call rate and gender

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::fluidigm_analysis

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::fluidigm_analysis->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will extract the filepath for a fluidigm results directory, parse the necessary files inside,
  and update the analytes with the call rate and gender.

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Ltd.

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
