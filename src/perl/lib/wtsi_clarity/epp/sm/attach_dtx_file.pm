package wtsi_clarity::epp::sm::attach_dtx_file;

use Moose;
use Carp;
use Readonly;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
## use critic

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::attach_dtx_file

=head1 SYNOPSIS

  use wtsi_clarity::epp::sm::attach_dtx_file;
  wtsi_clarity::epp::sm::attach_dtx_file->new(process_url => 'http://some.com/process/1234XM')->run();

=head1 DESCRIPTION

 Finds the DTX data file for a Pico Assay plate

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::clarity_elements

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
