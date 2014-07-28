package wtsi_clarity::util::configurable;

use Moose::Role;
use wtsi_clarity::util::config;

our $VERSION = '0.0';

has 'config'      => (
  isa             => 'wtsi_clarity::util::config',
  is              => 'ro',
  required        => 0,
  lazy_build      => 1,
);
sub _build_config {
  return wtsi_clarity::util::config->new();
}

1;

__END__

=head1 NAME

wtsi_clarity::util::configurable

=head1 SYNOPSIS

 In your class:

 package mypackage;
 use Moose;
 with 'wtsi_clarity::util::configurable';
 1;

 Using your class:

 my $p = mypackage->new();
 my $api_credentials = $p->config->clarity_api;

=head1 DESCRIPTION

 A Moose role providing access to configuration options for the wtsi_clarity project.
 
=head1 SUBROUTINES/METHODS

=head2 config

 A reference to wtsi_clarity::util::config object,
 access to configuration options for the package.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
