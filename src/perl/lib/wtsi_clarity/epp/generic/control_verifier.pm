package wtsi_clarity::epp::generic::control_verifier;
use strict;
use warnings FATAL => 'all';
use Moose;
use Carp;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;
  super();

  $self->_validate();

  return;
};

sub _validate {
  my $self = shift;

  my $analytes = $self->process_doc->input_artifacts();
  my @control_types = $analytes->findnodes(q(art:details/art:artifact/control-type));

  croak "Multiple control samples found" if scalar @control_types > 1;
  croak "No control samples found" if scalar @control_types == 0;

  return 1;
}

no Moose;

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::control_verifier

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::control_verifier->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will raise an error if there is not exactly one control analtye added to the process.

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=back

=head1 AUTHOR

Ronan Forman E<lt>rf9@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 20145 Genome Research Ltd.

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