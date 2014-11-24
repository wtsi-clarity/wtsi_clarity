package wtsi_clarity::util::csv::report_common;

use Moose::Role;

our $VERSION = '0.0';

sub get_method_from_header {
  my ($self,$header) = @_;
  my $name = _get_method_name_from_header($header);
  if ($self->can($name)) {
    return $name;
  }
  return q{_get_not_implemented_yet};
}

sub _get_method_name_from_header {
  my ($header) = @_;
  $header =~ s/^\s+|\s+$//gxms; # trim
  $header =~ s/\s/_/gxms;       # replace space with underscore
  return q{_get_} . lc $header; # lower case
}

1;

__END__

=head1 NAME

wtsi_clarity::util::csv::report_common

=head1 SYNOPSIS

=head1 DESCRIPTION

  Common methods for report creation related modules.

=head1 SUBROUTINES/METHODS

=head2 get_method_from_header

Returns a method name dynamically created from the header fields of the report file.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=back

=head1 AUTHOR

Author: Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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
