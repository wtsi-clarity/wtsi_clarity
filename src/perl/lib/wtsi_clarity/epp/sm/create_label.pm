package wtsi_clarity::epp::sm::create_label;

use Moose;
use Carp;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

has 'source_plate' => (
  isa        => 'Bool',
  is         => 'ro',
  required   => 0,
  default    => 0,
);

has 'printer' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

override 'run' => sub {
  my $self = shift;
  super(); #call parent's run method
  return 1;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::create_label

=head1 SYNOPSIS
  
  wtsi_clarity::epp:sm::create_label->new(process_url => 'http://my.com/processes/3345')->run();
  
=head1 DESCRIPTION

  Creates a barcode and sets it for the containers (if required), formats the label  and prints it.

=head1 SUBROUTINES/METHODS

=head2 process_url - Clarity process url, required.

=head2 printer - printer name (as known to the print service), an optional attribute.

=head2 source_plate - a boolean flag indicating whether source or target plates have to be considered
  false by default, meaning that target plates should be considered bt default, an optional attribute.

=head2 run - callback for the create_label action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

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
