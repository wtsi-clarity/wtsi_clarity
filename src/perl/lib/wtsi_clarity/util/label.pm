package wtsi_clarity::util::label;

use Moose::Role;
use Carp;
use Readonly;
use DateTime;

our $VERSION = '0.0';

Readonly::Scalar my $USER_NAME_LENGTH => 12;
Readonly::Scalar our $PLATE_96_WELL_CONTAINER_NAME  => q{96 Well Plate};
Readonly::Scalar our $ABGENE_800_CONTAINER_NAME     => q{ABgene 0800};
Readonly::Scalar our $ABGENE_765_CONTAINER_NAME     => q{ABgene 0765};
Readonly::Scalar our $FLUIDX_075_CONTAINER_NAME     => q{FluidX075};
Readonly::Scalar our $TUBE_CONTAINER_NAME           => q{Tube};

Readonly::Scalar our $PLATE_LABEL_TYPE              => q{plate};
Readonly::Scalar our $TUBE_LABEL_TYPE               => q{tube};

Readonly::Hash   our %LABEL_TYPES                   => {
  $PLATE_96_WELL_CONTAINER_NAME => $PLATE_LABEL_TYPE,
  $FLUIDX_075_CONTAINER_NAME    => $PLATE_LABEL_TYPE,
  $ABGENE_800_CONTAINER_NAME    => $PLATE_LABEL_TYPE,
  $ABGENE_765_CONTAINER_NAME    => $PLATE_LABEL_TYPE,
  $TUBE_CONTAINER_NAME          => $TUBE_LABEL_TYPE
};

sub label_type_by_container_name {
  my ($self, $container_name) = @_;

  return $LABEL_TYPES{$container_name};
}

has '_date' => (
  isa        => 'DateTime',
  is         => 'ro',
  required   => 0,
  default    => sub {
    return DateTime->now();
  },
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

  foreach my $container_url (sort keys %{$params->{'containers'}}) {
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
      'template'  => 'clarity_data_matrix_plate',
      'plate' => {
        'barcode' => $container->{'barcode'},
        'date_user'      => join(q[ ], $date, $user),
        'purpose'        => $container->{'purpose'},
        'signature'      => $container->{'signature'},
      }
    };

  } elsif ($type eq 'tube') {

    my ($lims, $project, $clarity_id, $count) = split /:/sxm, $container->{'barcode'};

    $label = {
      'template' => 'clarity_data_matrix_tube',
      'tube'     => {
        'barcode' => $container->{'barcode'},
        'date'                              => $date,
        'tube_signature_and_pooling_range'  => $container->{'tube_signature_and_pooling_range'},
        'original_plate_signature'          => $container->{'original_plate_signature'},
        'tube_lid' => {
          'prefix'  => $project,
          'number'  => $clarity_id
        },
      }
    };
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

=head2 label_type_by_container_name

  Returns the type of the label by container name.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Readonly

=item DataTime

=back

=head1 AUTHOR

Chris Smith E<lt>c24@sanger.ac.ukE<gt>

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
