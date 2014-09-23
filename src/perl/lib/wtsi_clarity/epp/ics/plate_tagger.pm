package wtsi_clarity::epp::ics::plate_tagger;

use Moose;
use wtsi_clarity::util::error_reporter qw/croak/;
use Readonly;
use wtsi_clarity::tag_plate::service;

extends 'wtsi_clarity::epp';
with qw/
        wtsi_clarity::util::clarity_elements
        wtsi_clarity::epp::ics::tag_plate_common
       /;

our $VERSION = '0.0';

has 'validate' => (
    isa        => 'Bool',
    is         => 'ro',
    required   => 0,
);

has 'exhaust'  => (
    isa        => 'Bool',
    is         => 'ro',
    required   => 0,
);

sub BUILD {
  my $self = shift;
  if ($self->validate && $self->exhaust) {
    croak( 'Both "validate" and "exhaust" options cannot be true');
  }
  if (!$self->validate && !$self->exhaust) {
    croak( 'Either "validate" or "exhaust" option should be specified');
  }
  return;
}

override 'run' => sub {
  my $self = shift;

  super(); #call parent's run method
  my $service = wtsi_clarity::tag_plate::service->new(barcode => $self->barcode);
  if ($self->validate) {
    $service->validate();
  }
  if ($self->exhaust) {
    $service->mark_as_used();
  }

  return;
};

no Moose;

1;

__END__

=head1 NAME

 wtsi_clarity::epp::ics::plate_tagger

=head1 SYNOPSIS

  Either 'validate' or 'exhaust' option should be set;

  wtsi_clarity::epp::ics::plate_tagger->new(process_url => 'some', validate => 1)->run();
  wtsi_clarity::epp::ics::plate_tagger->new(process_url => 'some', exhaust  => 1)->run();

=head1 DESCRIPTION

  Epp callback for accessing the 'Gatekeeper' tag plate micro-service to validate tag
  plates and marks them as used.

=head1 SUBROUTINES/METHODS

=head2 BUILD

  Post-constructor Moose hook - checks consistency of options.

=head2 run

  Executes the callback.

=head2 validate

  Boolean flag; validation is perfomed by the run method.

=head2 exhaust

  Boolean flag; plate is marked as used by the run method.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item wtsi_clarity::util::error_reporter

=item wtsi_clarity::tag_plate::service

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
