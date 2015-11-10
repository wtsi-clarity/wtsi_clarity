package wtsi_clarity::clarity::step::programstatus;

use Moose;
use Carp;
use Readonly;
use Try::Tiny;

our $VERSION = '0.0';

with qw/wtsi_clarity::util::clarity_elements/;

Readonly::Scalar my $WARNING => q(WARNING);
Readonly::Scalar my $ERROR   => q(ERROR);
Readonly::Scalar my $OK      => q(OK);

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $URI_PATH => q{stp:step/@uri};
## use critic

has 'step' => (
  is       => 'ro',
  isa      => 'wtsi_clarity::clarity::step',
  required => 1,
);

sub uri {
  my $self = shift;
  return join q{/}, $self->step->xml->findvalue($URI_PATH), q{programstatus};
}

sub send_warning {
  my ($self, $message) = @_;
  return $self->_update_status($WARNING, $message);
}

sub send_error {
  my ($self, $message) = @_;
  return $self->_update_status($ERROR, $message);
}

sub send_ok {
  my ($self, $message) = @_;
  return $self->_update_status($OK, $message);
}

sub _update_status {
  my ($self, $status, $message) = @_;

  try {
    my $programstatus = $self->_get;
    $self->_set_status_message($programstatus, $status, $message);
    $self->_update($programstatus);
  } catch {
    carp "Can not get the `programstatus` of the step. `programstatus` can only be retrieved for automatically triggered EPPs";
  };

  return;
}

sub _set_status_message {
  my ($self, $xml, $status, $message) = @_;
  $self->add_clarity_element($xml, q{status}, $status);
  $self->add_clarity_element($xml, q{message}, $message);
  return $xml;
}

sub _get {
  my $self = shift;
  return $self->step->parent->fetch_and_parse($self->uri);
}

sub _update {
  my ($self, $programstatus) = shift;
  return $self->step->request->put($self->uri, $programstatus->toString);
}

1;

__END__

=head1 NAME

wtsi_clarity::clarity::step::programstatus

=head1 SYNOPSIS

  use wtsi_clarity::clarity::step::programstatus;
  wtsi_clarity::clarity::step::programstatus->new(step => $step);

=head1 DESCRIPTION

  Class to wrap a step XML from Clarity with some convinient attributes and methods

=head1 SUBROUTINES/METHODS

=head2 uri
  Returns the uri for the programstatus

=head2 send_warning($message)
  Updates the step with a status of WARNING and the message provided

=head2 send_error($message)
  Updates the step with a status of ERROR and the message provided

=head2 send_ok($message)
  Updates the step with a status of OK and the message provided

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item Try::Tiny

=item wtsi_clarity::util::clarity_elements

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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