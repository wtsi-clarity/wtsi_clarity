package wtsi_clarity::epp::isc::pool_analyser;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use URI::Escape;
use List::Compare;
use Try::Tiny;
use wtsi_clarity::util::textfile;
use wtsi_clarity::util::report;

our $VERSION = '0.0';

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_process';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_ID_PATH                        => q(/prc:process/@limsid);

## use critic

override 'run' => sub {
  my $self= shift;
  super();

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::pool_analyser

=head1 SYNOPSIS

  my $pooler = wtsi_clarity::epp::isc::pool_analyser->new(
    process_url => $base_uri . '/processes/122-21977',
  );

=head1 DESCRIPTION

  This module is creates a pdf document describing the plates, and upload it on the server.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
