package wtsi_clarity::epp::stamp;

use Moose;
use English qw(-no_match_vars);
use namespace::autoclean;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

wtsi_clarity::epp::stamp

=head1 SYNOPSIS
  
  wtsi_clarity::epp:stamp->new(process_url => 'http://my.com/processes/3345')->run();
  
=head1 DESCRIPTION

  Stamps the content of source plates to desctination plates.
  Three scenarios are considered: 1:1, N:N (in pairs), 1:N

=head1 SUBROUTINES/METHODS

=head2 run

  Method executing the epp callback

=head2 process_url

  Clarity process url, required.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item namespace::autoclean

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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
