package wtsi_clarity::tag_plate::layout;

use Moose;
use Carp;
use Readonly;

with 'wtsi_clarity::util::well_mapper';

our $VERSION = '0.0';

Readonly::Scalar my $NB_ROWS_96      => 8;
Readonly::Scalar my $NB_COLS_96      => 12;
Readonly::Scalar my $KNOWN_DIRECTION => q[column];

has 'gatekeeper_info' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 1,
);

has 'tag_set_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  init_arg => undef,
  lazy_build => 1,
);
sub _build_tag_set_name {
  my $self = shift;
  my $name = $self->gatekeeper_info->{'tag_layout_template'}->{'tag_group'}->{'name'};
  return $name ? $name : undef; # force an error if empty string
}

has '_tags' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);
sub _build__tags {
  my $self = shift;

  if (!exists $self->gatekeeper_info->{'tag_layout_template'}) {
    croak 'Layout template is missing';
  }
  if (!$self->gatekeeper_info->{'tag_layout_template'}->{'direction'} ||
      $self->gatekeeper_info->{'tag_layout_template'}->{'direction'} ne $KNOWN_DIRECTION) {
    croak 'Missing or unexpected direction';
  }

  my $tags = $self->gatekeeper_info->{'tag_layout_template'}->{'tag_group'}->{'tags'};
  if (!$tags) {
    croak 'Tags section is missing in the layout';
  }

  my $plate_size = $NB_ROWS_96 * $NB_COLS_96;
  if (scalar keys %{$tags} < $plate_size) {
    croak "Less than $plate_size tags defined in the layout";
  }

  return $tags;
}

sub tag_info {
  my ($self, $well_address) = @_;

  my $tag_index = $self->well_location_index($well_address, $NB_ROWS_96, $NB_COLS_96);
  my $tag_sequence = $self->_tags->{$tag_index};
  if (!$tag_sequence) {
    croak "Failed to get tag sequence for $well_address (index $tag_index)";
  }
  return ($tag_index, $tag_sequence);
}

1;

__END__

=head1 NAME

  wtsi_clarity::tag_plate::layout

=head1 SYNOPSIS

  use wtsi_clarity::tag_plate::service;
  my $gatekeeper_layout =  wtsi_clarity::tag_plate::service->new(barcode => 'some')->get_layout();
  my $l = wtsi_clarity::tag_plate::layout->new(gatekeeper_info => $gatekeeper_layout);
  my $tag_set_name = $l->tag_set_name();
  my (tag_index, $tag_sequence) = $l->get_tag_info('A1');

=head1 DESCRIPTION

  Wrapper aroung Gatekeeper's tag plate layout document.

=head1 SUBROUTINES/METHODS

=head2 gatekeeper_info

  Gatekeeper tag layout info represented as a hash. Required attribute.
  See wtsi_clarity::tag_plate::service get_layout() method.

=head2 tag_set_name

  An attribute conaining the tag set name. Cannot be set via a constructor.

  my $tag_set_name = $l->tag_set_name();

=head2 tag_info
  
  Given well address, returns tag index and sequence.

  my (tag_index, $tag_sequence) = $l->get_tag_info('A1');

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

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
