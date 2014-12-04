package wtsi_clarity::util::pdf::factory;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::util::pdf::factory::pico_analysis_results;
use wtsi_clarity::util::pdf::factory::pool_analysis_results;
# TODO use wtsi_clarity::util::pdf_generator::factory::worksheet;

our $VERSION = '0.0';

sub createPDF {
  my ($self, $pdf_type, $parameters) = @_;
  my $pdf_factory;

  if ($pdf_type eq 'pico_analysis_results') {
    $pdf_factory = wtsi_clarity::util::pdf::factory::pico_analysis_results->new();
  } elsif ($pdf_type eq 'pool_analysis_results') {
    $pdf_factory = wtsi_clarity::util::pdf::factory::pool_analysis_results->new();
  # TODO
  # } elsif ($pdf_type eq 'worksheet') {
  # $pdf_factory = wtsi_clarity::util::pdf_generator::factory::worksheet->new();
  } else {
    croak "PDF type $pdf_type can not be created";
  }

  return $pdf_factory->build($parameters);
}

1;

__END__

=head1 NAME

wtsi_clarity::util::pdf::factory

=head1 SYNOPSIS
  
  use wtsi_clarity::util::pdf::factory;
  my $pdf_doc = wtsi_clarity::util::pdf::factory->createPDF('pdf_type', pdf_data);
  
=head1 DESCRIPTION

  Creates the specified PDF name

=head1 SUBROUTINES/METHODS

=head2 createPDF

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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