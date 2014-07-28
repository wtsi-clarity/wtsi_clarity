package wtsi_clarity::util::label;

use Moose::Role;
use Carp;
use Readonly;

our $VERSION = '0.0';

Readonly::Scalar my $USER_NAME_LENGTH => 12;

has '_date' => (
  isa        => 'DateTime',
  is         => 'ro',
  required   => 0,
  default    => sub { return DateTime->now(); },
);

sub generateLabels {
  my ($self, $params) = @_;
  my $h = {};

  $h->{'label_printer'}->{'header_text'} = {
    header_text1 => 'header by ' . $params->{'user'},
    header_text2 => $self->_date->strftime('%a %b %d %T %Y'),
  };

  $h->{'label_printer'}->{'footer_text'} = {
    footer_text1 => 'footer by ' . $params->{'user'},
    footer_text2 => $self->_date->strftime('%a %b %d %T %Y'),
  };

  my @labels = ();

  foreach my $container_url (keys %{$params->{'containers'}}) {
    my $count = 0;
    while ($count < $params->{'number'}) {
      my $container = $params->{'containers'}->{$container_url};
      push @labels, $self->_format_label($container, $params);
      $count++;
    }
  }

  $h->{'label_printer'}->{'labels'} = \@labels;

  return $h;
}

sub _format_label {
  my ($self, $container, $params) = @_;

  my $label;

  my $type = $params->{'type'};
  my $date = $self->_date->strftime('%d-%b-%Y');
  my $user = $params->{'source_plate'} ? q[] : $params->{'user'}; #no user for sample management stock plates  

  if ($user && length $user > $USER_NAME_LENGTH) {
    $user = substr $user, 0, $USER_NAME_LENGTH;
  }
  if ($type eq 'plate') {

    $label = {
        'template'  => 'plate',
        'plate' => {
          'ean13' => $container->{'barcode'},
          'sanger' => join(q[ ], $date, $user),
          'label_text' => {
            'role'  => $container->{'purpose'},
            'text5' => $container->{'num'},
            'text6' => $container->{'signature'}
          }
        }
    };

  } elsif ($type eq 'tube') { #tube labels have not been tested yet
    $label = {
      'template' => 'tube',
      'tube'     => {
        'ean13' => $container->{'barcode'},
        'sanger' => $container->{'lims_id'},
        'label_text' => {
          'role' => $user,
        },
    }};
  } else {
    croak qq[Unknown container type $type, known types: tube, plate];
  }

  return $label;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::label

=head1 SYNOPSIS

    use wtsi_clarity::epp::label qw/generateLabels/;

    generateLabels({
      'number'       => $num_copies, 
      'type'         => $container_type,
      'user'         => $user,
      'containers'   => $container,
      'source_plate' => $source_plate,
    })

=head1 DESCRIPTION

 Label generation for plates and tubes

=head1 SUBROUTINES/METHODS

=head2 generateLabels

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

=back

=head1 AUTHOR

Carol Scott E<lt>ces@sanger.ac.ukE<gt>

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
