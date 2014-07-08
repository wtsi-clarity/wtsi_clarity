package wtsi_clarity::epp::sm::cp_bed_verification;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::request;
extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();

  # Fetch file from previous step ( sneaky ?inputartifactslimsid filter )

  # Parse the file to find which plates go where

  # Switch bed names for bed barcodes

  # Fetch plates and beds from process

  # Validate beds and containers

  # Check all plates in .gwl file are present

  # Return happy :)

  return;
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::cp_bed_verification

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::cp_bed_verification->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Checks that the correct plates have been put into the correct beds, and that all plates are present,
  according to the .gwl file generated in the previous step.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - callback for the cp_bed_verification action

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