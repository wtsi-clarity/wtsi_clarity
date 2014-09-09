package wtsi_clarity::util::beckman;

use Moose;
use Carp;
use Readonly;
use wtsi_clarity::util::csv::factory;

our $VERSION = '0.0';

has 'writer_type' => (
  is      => 'ro',
  isa     => 'Str',
  default => sub {
    return 'beckman_writer';
  },
);

has 'headers' => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub {
              return [  'Sample',
                        'Bed',
                        'Source EAN13',
                        'Source Barcode',
                        'Source Stock',
                        'Source Well',
                        'Destination EAN13',
                        'Destination Barcode',
                        'Destination Well',
                        'Source Volume' ];
                  },
);

sub get_file {
  my ($self, $csv_data) = @_;


  if (!defined $self->writer_type) {
    croak qq{Writer for Becman is not implemented yet.}
  }

  my $factory = wtsi_clarity::util::csv::factory->new();
  return $factory->create(type    => $self->writer_type,
                          headers => $self->headers,
                          data    => $csv_data );
};

1;

__END__

=head1 NAME

wtsi_clarity::util::beckman

=head1 SYNOPSIS

  my $factory = wtsi_clarity::util::beckman->new();
  my $file = $factory->get_file($data); # returns a wtsi_clarity::util::textfile

=head1 DESCRIPTION

  Class able to creates drivers for a beckman robot. (Potentially, it can be used
  -once implemented- to read the beckman output)

=head1 SUBROUTINES/METHODS

=head2 get_file

  returns a textfile instance ready to be dumped on the file system

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::csv::factory::generic_csv_writer

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