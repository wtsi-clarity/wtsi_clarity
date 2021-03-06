package wtsi_clarity::epp::generic::worksheet_attacher;

use Moose;
use Carp;
use Readonly;
use DateTime;
use POSIX;
use Mojo::Collection;
use wtsi_clarity::util::request;
use wtsi_clarity::util::well_mapper;

extends qw/ wtsi_clarity::epp
  wtsi_clarity::util::pdf::pdf_generator
  /;
with qw/ wtsi_clarity::util::clarity_elements_fetcher_role_util
  wtsi_clarity::util::clarity_elements
  wtsi_clarity::util::uploader_role
  /;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_PATH             => q(/prc:process/input-output-map/input/@post-process-uri);
Readonly::Scalar my $PREVIOUS_PROC             => q(/prc:process/input-output-map/input/parent-process/@uri);
Readonly::Scalar my $PROCESS_ID_PATH           => q(/prc:process/@limsid);
Readonly::Scalar my $TECHNICIAN_FIRSTNAME_PATH => q(/prc:process/technician/first-name/text());
Readonly::Scalar my $TECHNICIAN_LASTNAME_PATH  => q(/prc:process/technician/last-name/text());
Readonly::Scalar my $LOCATION_PATH             => q(/art:artifact/location/value);
Readonly::Scalar my $CONTAINER_URI_PATH        => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $CONTAINER_ID_PATH         => q(/art:artifact/location/container/@limsid);

Readonly::Scalar my $CONTAINER_TYPE_URI        => q{/con:container/type/@uri};
Readonly::Scalar my $CONTAINER_TYPE_NAME       => q{/con:container/type/@name};
Readonly::Scalar my $CONTAINER_TYPE_X          => q{/ctp:container-type/x-dimension/size};
Readonly::Scalar my $CONTAINER_TYPE_Y          => q{/ctp:container-type/y-dimension/size};

Readonly::Scalar my $PURPOSE_PATH              => q(WTSI Container Purpose Name);
Readonly::Scalar my $SAMPLE_VOLUME_PATH        => q{Cherrypick Sample Volume};
Readonly::Scalar my $BUFFER_VOLUME_PATH        => q{Cherrypick Buffer Volume};
Readonly::Scalar my $FREEZER_PATH              => q{WTSI Freezer};
Readonly::Scalar my $SHELF_PATH                => q{WTSI Shelf};
Readonly::Scalar my $TRAY_PATH                 => q{WTSI Tray};
Readonly::Scalar my $RACK_PATH                 => q{WTSI Rack};
## use critic

Readonly::Scalar my $NUMBER_OF_COLUMNS        => 12;
Readonly::Scalar my $NUMBER_OF_ROWS           => 8;
Readonly::Scalar my $A_CHAR_CODE              => 64;
Readonly::Scalar my $PLATE_NAME_START_INDEX   => 3;
Readonly::Scalar my $PLATE_NAME_START_LENGTH  => 7;
Readonly::Scalar my $EAN13_BARCODE_LENGTH     => 13;

Readonly::Scalar my $source_table_height      => 100;
Readonly::Scalar my $destination_table_height => 300;
Readonly::Scalar my $buffer_table_height      => 450;

has 'worksheet_filename' => (
  isa => 'Str',
  is => 'ro',
  required => 1,
);

has 'tecan_filename' => (
  isa => 'Str',
  is => 'ro',
  required => 1,
);

override 'run' => sub {
  my $self = shift;
  super();

  my $containers_data = $self->_get_containers_data();
  my $stamp = _get_stamp($containers_data, $self->request->user);

  # pdf generation
  my $pdf_data = _get_pdf_data($containers_data, $stamp);

  $self->_create_worksheet_file($pdf_data)->saveas(q{./}.$self->worksheet_filename);

  # tecan file generation
  # temp way to only create the worksheet
  if ($self->tecan_filename) {
    $self->_create_tecan_file($containers_data, $stamp, $self->tecan_filename);
  }

  return 1;
};

################# date & username ############

sub _get_username {
  my ($data, $realuser) = @_;
  my $firstname = $data->{'user_first_name'};
  my $lastname = $data->{'user_last_name'};
  return qq{$firstname $lastname (via $realuser)};
}

sub _get_stamp {
  my ($data, $realuser) = @_;
  my $username = _get_username($data, $realuser);
  my $date = DateTime->now->strftime('%A %d-%B-%Y at %H:%M:%S');

  return qq{This file was created by $username on $date};
}

################# tecan file #################

sub _create_tecan_file {
  my ($self, $containers_data, $stamp, $full_filename) = @_;

  my $file_content = $self->_get_TECAN_file_content($containers_data, $stamp);

  open my $fh, '>', $full_filename
    or croak qq{Could not create/open file '$full_filename'.};
  foreach my $line (@{$file_content})
  {
    print {$fh} qq{$line\n} or croak qq[Failed to write to the file: $fh]; # Print each entry in our array to the file
  }
  close $fh
    or croak qq{ Unable to close $full_filename.};
  return $full_filename;
}

sub _get_TECAN_file_content {
  my ($self, $containers_data, $stamp) = @_;

  my @content_output = ();
  my @buffer_output = ();

  # creating the comments at the top of the file

  push @content_output, 'C;';
  push @content_output, 'C; '.$stamp;
  push @content_output, 'C;';

  # creating main content

  foreach my $uri (sort keys %{$containers_data->{'output_container_info'}}) {
    my ($samples, $buffers) = $self->_get_TECAN_file_content_per_URI($containers_data, $uri);
    push @content_output, @{$samples};
    push @buffer_output, @{$buffers};
  }

  push @content_output, @buffer_output;

  # creating the comments in the end of the file

  push @content_output, 'C;';
  my $n = 1;
  foreach my $input (sort keys %{$containers_data->{'input_container_info'}}) {
    my $barcode = $containers_data->{'input_container_info'}->{$input}->{'barcode'};
    push @content_output, qq{C; SRC$n = $barcode};
    $n++;
  }
  push @content_output, 'C;';
  $n = 1;
  foreach my $output (sort keys %{$containers_data->{'output_container_info'}}) {
    my $barcode = $containers_data->{'output_container_info'}->{$output}->{'barcode'};
    push @content_output, qq{C; DEST$n = $barcode};
    $n++;
  }
  push @content_output, 'C;';
  return \@content_output;
}

sub _get_well_position {
  my ($self, $well_position) = @_;
  return wtsi_clarity::util::well_mapper->well_location_index($well_position, $NUMBER_OF_ROWS, $NUMBER_OF_COLUMNS);
}

sub _is_integer {
  my $x = shift;
  return ($x =~ /^-?\d+\z/sxm) ? 1 : 0;
}

sub _get_TECAN_file_content_per_URI {
  my ($self, $data, $uri) = @_;
  my @sample_output = ();
  my @buffer_output = ();
  my $output_container = $data->{'output_container_info'}->{$uri};
  my $output_type = $data->{'output_container_info'}->{$uri}->{'type'};
  my $output_barcode = $data->{'output_container_info'}->{$uri}->{'barcode'};
  # keys are sorted to facilitate testing!
  foreach my $out_loc (sort keys %{$output_container->{'container_details'}}) {
    my $in_details = $output_container->{'container_details'}->{$out_loc};
    if (scalar keys %{$in_details}) {
      my $out_loc_dec = $self->_get_well_position($out_loc);

      if (!_is_integer($out_loc_dec)) {
        croak "Output location is not an integer: " . $out_loc_dec;
      }

      my $inp_loc_dec = $self->_get_well_position($in_details->{'input_location'});

      if (!_is_integer($inp_loc_dec)) {
        croak "Input location is not an integer: " . $inp_loc_dec;
      }

      my $sample_volume = $in_details->{'sample_volume'};
      my $buffer_volume = $in_details->{'buffer_volume'};
      my $input_uri = $in_details->{'input_uri'};
      my $input_type = $data->{'input_container_info'}->{$input_uri}->{'type'};
      my $input_barcode = $data->{'input_container_info'}->{$input_uri}->{'barcode'};

      my $input_sample_string = qq{A;$input_barcode;;$input_type;$inp_loc_dec;;$sample_volume};
      my $output_sample_string = qq{D;$output_barcode;;$output_type;$out_loc_dec;;$sample_volume};
      my $w_string = q{W;};

      push @sample_output, {
        output_location => $out_loc_dec,
        output          => join "\n", $input_sample_string, $output_sample_string, $w_string,
      };

      if ($buffer_volume != 0) {
        my $input_buffer_string = qq{A;BUFF;;96-TROUGH;$inp_loc_dec;;$buffer_volume};
        my $output_buffer_string = qq{D;$output_barcode;;$output_type;$out_loc_dec;;$buffer_volume};

        push @buffer_output, {
          output_location => $out_loc_dec,
          output => join "\n", $input_buffer_string, $output_buffer_string, $w_string,
        };
      }
    }
  }

  @sample_output = map {
    $_->{'output'}
  } sort {
    $a->{'output_location'} <=> $b->{'output_location'}
  } @sample_output;

  @buffer_output = map {
    $_->{'output'}
  } sort {
    $a->{'output_location'} <=> $b->{'output_location'}
  } @buffer_output;

  return (\@sample_output, \@buffer_output);
}

################# worksheet #################

sub _create_worksheet_file {
  my ($self, $pdf_data) = @_;

  my $pdf_generator = wtsi_clarity::util::pdf::pdf_generator->new(stamp => $pdf_data->{'stamp'});

  # for each output container, we produce a new page...
  foreach my $page_data (@{$pdf_data->{'pages'}}) {
    my $page = $self->pdf->page();
    $page->mediabox('A4');

    $pdf_generator->add_title_to_page($page, $page_data->{'title'});
    $pdf_generator->add_timestamp($page);

    $pdf_generator->add_io_block_to_page($self->pdf, $page, $page_data->{'input_table'}, $page_data->{'input_table_title'}, $source_table_height);
    $pdf_generator->add_io_block_to_page($self->pdf, $page, $page_data->{'output_table'}, $page_data->{'output_table_title'}, $destination_table_height);

    $pdf_generator->add_buffer_block_to_page($self->pdf, $page, $page_data->{'plate_table'}, $page_data->{'plate_table_title'}, $page_data->{'plate_table_cell_styles'}, $buffer_table_height);
  }

  return $self->pdf;
}

sub _get_pdf_data {
  my ($containers_data, $stamp) = @_;
  my $pdf_data = {};
  $pdf_data->{'stamp'} = $stamp;
  $pdf_data->{'pages'} = [];

  while (my ($uri, $data) = each %{$containers_data->{'output_container_info'}} ) {
    my $page = {};
    $page->{'title'} = _get_title($containers_data, $uri);
    $page->{'input_table_title'} = q{Source plates};
    $page->{'input_table'} = _get_source_plate_data($containers_data, $uri);

    $page->{'output_table_title'} = q{Destination plates};
    $page->{'output_table'} = _get_destination_plate_data($containers_data, $uri);

    my ($table_data, $table_properties) = _get_table_data($data->{'container_details'});

    $page->{'plate_table_title'} = q{Required buffer};
    $page->{'plate_table'} = $table_data;
    $page->{'plate_table_cell_styles'} = $table_properties;

    push @{$pdf_data->{'pages'}}, $page;
  }

  return $pdf_data;
}

sub _get_title {
  my ($data, $out_uri) = @_;

  my $out_purpose = $data->{ q{output_container_info} }->{$out_uri}->{ q{purpose} };

  my @wells = values %{$data->{ q{output_container_info} }->{$out_uri}->{ q{container_details} }};
  my @input_ids = grep {
    $_->{'input_id'}
  } @wells;
  @input_ids = map {
    $_->{'input_id'}
  } @input_ids;
  @input_ids = sort @input_ids;

  my $an_input_id = $input_ids[0];

  my $in_purpose = $data->{ q{input_container_info} }->{$an_input_id}->{ q{purpose} };

  my $process = $data->{ q{process_id} };
  return qq{Process $process - $in_purpose -> $out_purpose};
}

sub _get_source_plate_data {
  my ($data, $uri) = @_;
  my $input_plates = {};

  while (my ($pos, $info) = each %{$data->{'output_container_info'}
    ->{$uri}
    ->{'container_details'}    } ) {
    if (defined $info->{'input_uri'}) {
      $input_plates->{$info->{'input_uri'}} = 1;
    }
  }
  my @table_data = ();

  push @table_data, ['Plate name', 'Barcode', 'Freezer', 'Shelf', 'Rack', 'Tray'];

  foreach my $key (sort keys %{$input_plates}) {
    my $plate_name = $data->{'input_container_info'}->{$key}->{'plate_name'};
    my $barcode = $data->{'input_container_info'}->{$key}->{'barcode'};
    my $freezer = $data->{'input_container_info'}->{$key}->{'freezer'};
    my $shelf = $data->{'input_container_info'}->{$key}->{'shelf'};
    my $rack = $data->{'input_container_info'}->{$key}->{'rack'};
    my $tray = $data->{'input_container_info'}->{$key}->{'tray'};
    push @table_data, [$plate_name, $barcode, $freezer, $shelf, $rack, $tray];
  }
  return \@table_data;
}

sub _get_destination_plate_data {
  my ($data, $uri) = @_;

  my @table_data = ();
  push @table_data, ['Plate name', 'Barcode', 'Wells'];

  my $plate_name = $data->{'output_container_info'}->{$uri}->{'plate_name'};
  my $barcode = $data->{'output_container_info'}->{$uri}->{'barcode'};
  my $wells = $data->{'output_container_info'}->{$uri}->{'occ_wells'};
  push @table_data, [$plate_name, $barcode, $wells];
  return \@table_data;
}

sub _get_table_data {
  my ($data) = @_;

  my @table_data = ();
  my @table_properties = ();

  my $colour_indexes = _get_colour_indexes($data);

  foreach my $j (0..$NUMBER_OF_ROWS + 1) {
    my @row = ();
    my @row_properties = ();
    foreach my $i (0..$NUMBER_OF_COLUMNS + 1) {
      my ($content, $properties) = _get_cell($data, $colour_indexes, $i, $j);
      push @row, $content;
      push @row_properties, $properties;
    }
    push @table_data, \@row;
    push @table_properties, \@row_properties;
  }

  return (\@table_data, \@table_properties);
}

sub _get_cell {
  my ($data, $colour_indexes, $i, $j) = @_;

  my $content;
  my $properties;

  if (my $pos = _get_location($i, $j)) {
    $content = _get_cell_content($data, $pos);
    $properties = _get_cell_properties($data, $colour_indexes, $pos);

  } else {
    $content = _get_legend_content($i, $j);
    $properties = _get_legend_properties();
  }
  return ($content, $properties);
}

sub _get_cell_content {
  my ($data, $pos) = @_;
  my $cell = $data->{$pos};
  if ($cell and %{$cell}) {
    my $container_id = $cell->{'input_id'};
    $container_id =~ s/\-//xms;

    my $id = $container_id;
    my $loc = $cell->{'input_location'};
    my $sample_volume = $cell->{'sample_volume'};
    my $buffer_volume = $cell->{'buffer_volume'};
    return $loc."\n".$id."\nv".(ceil($sample_volume)).' b'.(ceil($buffer_volume));
  }

  return q{};
}

sub _get_legend_content {
  my ($i, $j) = @_;
  if ($i == 0 || $i > $NUMBER_OF_COLUMNS) {
    if ($j == 0 || $j > $NUMBER_OF_ROWS) {
      return q{};
    }
    return ".\n".chr($A_CHAR_CODE + $j)."\n.";
  }
  if ($j == 0 || $j > $NUMBER_OF_ROWS) {
    return $i;
  }
  return;
}

sub _get_cell_properties {
  my ($data, $colour_indexes, $pos) = @_;
  my $id = $data->{$pos}->{'input_id'};
  if (defined $id) {
    my $col = $colour_indexes->{$id};
    return "COLOUR_$col";
  } else {
    return 'EMPTY_STYLE'
  }
}

sub _get_legend_properties {
  return 'HEADER_STYLE';
}

sub _get_colour_indexes {
  my ($data) = @_;
  my $hash_colour = {};
  my $colour_index = 0;
  foreach my $key (sort keys %{$data}) {
    my $id = $data->{$key}->{'input_id'};
    if (defined $id && !defined $hash_colour->{$id}) {
      $hash_colour->{$id} = $colour_index++;
    }
  }
  return $hash_colour;
}

sub _get_location {
  my ($i, $j) = @_;
  if ($i == 0 || $i > $NUMBER_OF_COLUMNS) {
    # top or bottom row
    return;
  }
  if ($j == 0 || $j > $NUMBER_OF_ROWS) {
    # top or bottom row
    return;
  }
  return (chr $A_CHAR_CODE + $j).q{:}.$i;
}


sub _get_containers_data {
  my ($self) = @_;

  my $artifacts_tmp = $self->fetch_targets_hash($ARTIFACT_PATH);
  my $previous_processes = $self->fetch_targets_hash($PREVIOUS_PROC);
  my $previous_artifacts = $self->fetch_targets_hash($PREVIOUS_PROC, $ARTIFACT_PATH);

  my $oi_map = $self->_get_oi_map($previous_processes);

  my $all_data = {};
  my $process_id = $self->find_elements_first_value($self->process_doc->xml, $PROCESS_ID_PATH);
  $process_id =~ s/\-//xms;
  $all_data->{ q{process_id} } = $process_id;

  $all_data->{ q{user_first_name} } = $self->find_elements_first_value($self->process_doc->xml, $TECHNICIAN_FIRSTNAME_PATH);
  $all_data->{ q{user_last_name}  } = $self->find_elements_first_value($self->process_doc->xml, $TECHNICIAN_LASTNAME_PATH);

  while (my ($uri, $out_artifact) = each %{$artifacts_tmp} ) {
    if ($uri =~ /(.*)[?].*/xms) {
      my $in_artifact = $previous_artifacts->{$oi_map->{$uri}};

      my $out_location = $self->find_elements_first_textContent( $out_artifact, $LOCATION_PATH         );
      my $out_container_uri = $self->find_elements_first_value      ( $out_artifact, $CONTAINER_URI_PATH    );
      my $out_container_id = $self->find_elements_first_value      ( $out_artifact, $CONTAINER_ID_PATH     );
      my $sample_volume = $self->find_udf_element_textContent   ( $out_artifact, $SAMPLE_VOLUME_PATH, 0 );
      my $buffer_volume = $self->find_udf_element_textContent   ( $out_artifact, $BUFFER_VOLUME_PATH, 0 );
      my $in_location = $self->find_elements_first_textContent( $in_artifact, $LOCATION_PATH         );
      my $in_container_uri = $self->find_elements_first_value      ( $in_artifact, $CONTAINER_URI_PATH    );

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'output_container_info'}->{$out_container_uri})
      {
        my $out_container = $self->fetch_and_parse($out_container_uri);

        my $barcode = $self->find_clarity_element_textContent($out_container, q{name}                   );
        my $purpose = $self->find_udf_element_textContent    ($out_container, $PURPOSE_PATH, q{Unknown} );
        my $name = $out_container_id;
        $name =~ s/\-//xms;

        # to get the wells
        my $out_container_type_uri = $self->find_elements_first_value($out_container, $CONTAINER_TYPE_URI );
        my $out_container_type_name = $self->find_elements_first_value($out_container, $CONTAINER_TYPE_NAME);
        my $out_container_type = $self->fetch_and_parse($out_container_type_uri);
        my $x = $self->find_elements_first_textContent($out_container_type, $CONTAINER_TYPE_X);
        my $y = $self->find_elements_first_textContent($out_container_type, $CONTAINER_TYPE_Y);

        $all_data->{ q{output_container_info} }->{ $out_container_uri }->{ q{purpose}    } = $purpose;
        $all_data->{ q{output_container_info} }->{ $out_container_uri }->{ q{plate_name} } = $name;
        $all_data->{ q{output_container_info} }->{ $out_container_uri }->{ q{barcode}    } = $barcode;
        $all_data->{ q{output_container_info} }->{ $out_container_uri }->{ q{type}       } = $out_container_type_name;
        $all_data->{ q{output_container_info} }->{ $out_container_uri }->{ q{wells}      } = $x * $y;
      }

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'input_container_info'}->{$in_container_uri}) {
        my $in_container = $self->fetch_and_parse($in_container_uri);

        my $freezer = $self->find_udf_element_textContent( $in_container, $FREEZER_PATH, q{Unknown} );
        my $shelf = $self->find_udf_element_textContent( $in_container, $SHELF_PATH, q{Unknown} );
        my $tray = $self->find_udf_element_textContent( $in_container, $TRAY_PATH, q{Unknown} );
        my $rack = $self->find_udf_element_textContent( $in_container, $RACK_PATH, q{Unknown} );
        my $purpose = $self->find_udf_element_textContent( $in_container, $PURPOSE_PATH, q{Unknown} );

        my $barcode = $self->find_clarity_element_textContent($in_container, q{name});
        my $type_name = $self->find_elements_first_value($in_container, $CONTAINER_TYPE_NAME);

        my $plate_name;
        if (length $barcode == $EAN13_BARCODE_LENGTH) {
          $plate_name = substr $barcode, $PLATE_NAME_START_INDEX, $PLATE_NAME_START_LENGTH;
          $plate_name =~ s/^0*//xms;
        } else {
          $plate_name = $barcode;
        }

        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{plate_name} } = $plate_name;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{barcode}    } = $barcode;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{type}       } = $type_name;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{freezer}    } = $freezer;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{shelf}      } = $shelf;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{rack}       } = $rack;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{tray}       } = $tray;
        $all_data->{ q{input_container_info} }->{ $in_container_uri }->{ q{purpose}    } = $purpose;
      }

      my $plate_name = $all_data->{q{input_container_info}}->{ $in_container_uri }->{q{plate_name}};
      $all_data->{ q{output_container_info} }->{$out_container_uri}->{ q{container_details} }->{$out_location} = {
        q{input_id}             => $plate_name,
        q{input_location}       => $in_location,
        q{sample_volume}        => $sample_volume,
        q{buffer_volume}        => $buffer_volume,
        q{input_uri}            => $in_container_uri,
      };
    }
  }

  while (my ($uri, $out_artifact) = each %{$all_data->{ q{output_container_info} }}) {
    $out_artifact->{ q{occ_wells} } = scalar keys %{$out_artifact->{ q{container_details} }};
  }

  return $all_data;
}

has '_oi_map' => (
  isa        => 'HashRef',
  is         => 'rw',
  required   => 0,
  default => sub {
    {}
  },
);

sub _get_oi_map {
  my ($self, $previous_processes) = @_;

  if (keys %{$self->_oi_map}) {
    return $self->_oi_map;
  }
  my $oi_map = {};
  ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  while (my ($uri, $proc) = each %{$previous_processes} ) {
    my $proc_io_maps = $self->find_elements($proc, q{./input-output-map});
    foreach my $proc_io_map (@{$proc_io_maps}) {
      my $in = $proc_io_map->findnodes( q{./input/@uri}  );
      my $out = $proc_io_map->findnodes( q{./output/@uri} );
      $oi_map->{$out} = $in;
    }
  }
  ## use critic
  $self->_oi_map($oi_map);
  return $self->_oi_map;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::worksheet_attacher

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::worksheet_attacher->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a pdf document describing the plates, and upload it on the server, as an output for each output plate.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item DateTime

=item Mojo::Collection

=item POSIX

=item Mojo::Collection

=item wtsi_clarity::util::request;

=item wtsi_clarity::util::well_mapper;

=item wtsi_clarity::epp

=item wtsi_clarity::util::pdf::pdf_generator

=item wtsi_clarity::util::clarity_elements_fetcher_role_util

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::util::uploader_role

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

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

