package wtsi_clarity::genotyping::fluidigm;

use Moose;
use Carp;

use wtsi_clarity::genotyping::fluidigm::result_set;
use wtsi_clarity::genotyping::fluidigm::file_wrapper;
use wtsi_clarity::genotyping::fluidigm::assay_set;

our $VERSION = '0.0';

has 'directory' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

sub parse {
  my $self = shift;
  my %assay_set = ();

  my $result_set = wtsi_clarity::genotyping::fluidigm::result_set->new(
    directory => $self->directory,
  );

  my $file_wrapper = wtsi_clarity::genotyping::fluidigm::file_wrapper->new(
    file_name => $result_set->export_file,
  );

  foreach my $sample (keys $file_wrapper->content) {
    $assay_set{$sample} = wtsi_clarity::genotyping::fluidigm::assay_set->new(
      file_content => $file_wrapper->content->{$sample},
    );
  }

  return %assay_set;
}

1;

__END__

=head1 NAME

wtsi_clarity::genotyping::fluidigm

=head1 SYNOPSIS

  wtsi_clarity::genotyping::fluidigm->new(
    directory => '/my/fludigm/directory'
  )->parse();

=head1 DESCRIPTION

  An simple interface for fluidigm analysis

=head1 SUBROUTINES/METHODS

=head2 parse - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::util::error_reporter

=item wtsi_clarity::genotyping::fluidigm::result_set;

=item wtsi_clarity::genotyping::fluidigm::file_wrapper;

=item wtsi_clarity::genotyping::fluidigm::assay_set;

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
