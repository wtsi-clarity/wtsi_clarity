package WWW::Clarity::Models::Process;

use Moose;
use DateTime::Format::Strptime;

extends 'WWW::Clarity::Models::Model';

has '_attributes' => (
    is      => 'ro',
    default => sub {
      return {
        type             => {
          xpath => 'type',
          isa   => 'text',
        },
        date             => {
          xpath  => 'date-run',
          isa    => 'text',
          getter => sub {
            my ($self, $date_string) = @_;
            my $format = DateTime::Format::Strptime->new(
              pattern => '%Y-%m-%d',
            );
            return $format->parse_datetime($date_string);
          },
          setter => sub {
            my ($self, $date) = @_;
            return $date->strftime('%Y-%m-%d');
          }
        },
        researcher       => {
          is     => 'ro',
          isa    => 'attr',
          cached => 1,
          xpath  => 'technician/@uri',
          getter => sub {
            my ($self, $uri) = @_;
            return $self->clarity->get_researcher($uri);
          }
        },
        input_artifacts  => {
          is     => 'ro',
          isa    => 'attrList',
          cached => 1,
          xpath  => 'input-output-map/input/@uri',
          getter => sub {
            my ($self, $uris) = @_;
            return $self->clarity->get_artifacts($uris);
          }
        },
        output_artifacts => {
          is     => 'ro',
          isa    => 'attrList',
          cached => 1,
          xpath  => 'input-output-map/output/@uri',
          getter => sub {
            my ($self, $uris) = @_;
            return $self->clarity->get_artifacts($uris);
          }
        },
      }
    }
  );

has 'input_samples' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    reader     => 'get_input_samples',
  );
sub _build_input_samples {
  my ($self) = @_;

  my @sample_uris = map {
    @{$_->get_sample_uris};
  } @{$self->get_input_artifacts};

  return $self->clarity->get_samples(\@sample_uris);
}

has 'output_samples' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
    reader     => 'get_output_samples',
  );
sub _build_output_samples {
  my ($self) = @_;

  my @sample_uris = map {
    @{$_->get_sample_uris};
  } @{$self->get_output_artifacts};

  return $self->clarity->get_samples(\@sample_uris);
}

=head1 SYNOPSIS



=head1 LICENSE AND COPYRIGHT

Copyright 2016 Sanger Insitute.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut

1;