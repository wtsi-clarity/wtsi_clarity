package wtsi_clarity::epp::sm::worksheet;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use PDF::API2;
use PDF::Table;
use File::Temp ();
use File::Tempdir ();
use Data::Dumper;
use wtsi_clarity::util::request;
use wtsi_clarity::util::well_mapper;
use Datetime;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_PATH      => q(/prc:process/input-output-map/input/@post-process-uri);
Readonly::Scalar my $PREVIOUS_PROC      => q(/prc:process/input-output-map/input/parent-process/@uri);
Readonly::Scalar my $OUTPUT_FILES       => q(/prc:process/input-output-map/output[@output-type='ResultFile']/@uri);
Readonly::Scalar my $PROCESS_ID_PATH    => q(/prc:process/@limsid);

Readonly::Scalar my $SAMPLE_PATH        => q(/art:artifact/sample/@uri);
Readonly::Scalar my $LOCATION_PATH      => q(/art:artifact/location/value);
Readonly::Scalar my $CONTAINER_URI_PATH => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $CONTAINER_ID_PATH  => q(/art:artifact/location/container/@limsid);

Readonly::Scalar my $CONTAINER_TYPE_URI => q{/con:container/type/@uri};
Readonly::Scalar my $CONTAINER_TYPE_NAME=> q{/con:container/type/@name};
Readonly::Scalar my $CONTAINER_TYPE_X   => q{/ctp:container-type/x-dimension/size};
Readonly::Scalar my $CONTAINER_TYPE_Y   => q{/ctp:container-type/y-dimension/size};

Readonly::Scalar my $PURPOSE_PATH       => q(WTSI Container Purpose Name);
Readonly::Scalar my $SAMPLE_VOLUME_PATH => q{Cherrypick Sample Volume};
Readonly::Scalar my $BUFFER_VOLUME_PATH => q{Cherrypick Buffer Volume};
Readonly::Scalar my $FREEZER_PATH       => q{WTSI Freezer};
Readonly::Scalar my $SHELF_PATH         => q{WTSI Shelf};
Readonly::Scalar my $TRAY_PATH          => q{WTSI Tray};
Readonly::Scalar my $RACK_PATH          => q{WTSI Rack};

## use critic
Readonly::Scalar my $col_width                => 40;
Readonly::Scalar my $nb_col                   => 12;
Readonly::Scalar my $nb_row                   => 8;
Readonly::Scalar my $left_margin              => 20;
Readonly::Scalar my $title_height             => 780;
Readonly::Scalar my $title_size               => 20;
Readonly::Scalar my $subtitle_shift           => 20;
Readonly::Scalar my $subtitle_size            => 12;
Readonly::Scalar my $source_table_height      => 700;
Readonly::Scalar my $destination_table_height => 450;
Readonly::Scalar my $buffer_table_height      => 350;
Readonly::Scalar my $A_CHAR_CODE              => 64;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::uploader_role';


our $VERSION = '0.0';

$File::Temp::KEEP_ALL = 1;
override 'run' => sub {
  my $self= shift;
  super();

  my $containers_data = $self->_get_containers_data();

  # pdf generation
  my $worksheet_filename = _create_worksheet_file($containers_data);

  # tecan file generation
  my $tecan_filename = _create_tecan_file($containers_data, $self->request->user, DateTime->now->strftime('%Y-%m-%d'));

  # uploading files
  my $outputs       = $self->fetch_targets_hash($OUTPUT_FILES);
  while (my ($uri, $output) = each %{$outputs} ) {
    my $name = ($self->find_elements($output,    q{/art:artifact/name}      ) )[0] ->textContent;
    if ($name eq 'Worksheet') {
      $self->addfile_to_resource($uri, $worksheet_filename)
        or croak qq[Could not add file $worksheet_filename to the resource $uri.];
    }
    if ($name eq 'Tecan File') {
      $self->addfile_to_resource($uri, $tecan_filename)
        or croak qq[Could not add file $tecan_filename to the resource $uri.];
    }
  }


  return 1;
};

################# tecan file #################

sub _create_tecan_file {
  my ($containers_data, $username, $date) = @_;

  my $file_content = _get_TECAN_file_content($containers_data, $username, $date);

  my $tmpdirname = File::Temp->newdir(CLEANUP => 1)->dirname();
  my $full_filename = qq{$tmpdirname/tecan.gwl};

  open my $fh, '>', $full_filename
    or croak qq{Could not create/open file '$full_filename'.};
  foreach my $line (@{$file_content})
  {
      ## no critic(InputOutput::RequireCheckedSyscalls)
      print {$fh} qq{$line\n}; # Print each entry in our array to the file
      ## use critic
  }
  close $fh
    or croak qq{ Unable to close $full_filename.};
  return $full_filename;
}

sub _get_TECAN_file_content {
  my ($containers_data, $username, $date) = @_;

  my $content_output = [];
  my $buffer_output = [];

  # creating the comments at the top of the file

  push $content_output, 'C;' ;
  push $content_output, 'C; This file created by '.$username.' on '.$date ;
  push $content_output, 'C;' ;

  # creating main content

  foreach my $uri (sort keys %{$containers_data->{'output_container_info'}} ) {
    my ($samples, $buffers) = _get_TECAN_file_content_per_URI($containers_data, $uri);
    push $content_output, @{$samples};
    push $buffer_output, @{$buffers};
  }
  push $content_output, @{$buffer_output};

  # creating the comments in the end of the file

  push $content_output, 'C;' ;
  my $n = 1;
  foreach my $input (sort keys %{$containers_data->{'input_container_info'}} ) {
    my $barcode = $containers_data->{'input_container_info'}->{$input}->{'barcode'};
    push $content_output, qq{C; SRC$n = $barcode} ;
    $n++;
  }
  push $content_output, 'C;' ;
  $n = 1;
  foreach my $output (sort keys %{$containers_data->{'output_container_info'}} ) {
    my $barcode = $containers_data->{'output_container_info'}->{$output}->{'barcode'};
    push $content_output, qq{C; DEST$n = $barcode} ;
    $n++;
  }
  push $content_output, 'C;' ;
  return $content_output;
}

sub _get_TECAN_file_content_per_URI {
  my ($data, $uri) = @_;
  my $sample_output = [];
  my $buffer_output = [];
  my $output_container = $data->{'output_container_info'}->{$uri};
  my $output_type   = $data->{'output_container_info'}->{$uri}->{'type'};
  my $output_barcode= $data->{'output_container_info'}->{$uri}->{'barcode'};
  # keys are sorted to facilitate testing!
  foreach my $out_loc (sort keys %{$output_container->{'container_details'}} ) {
    my $in_details  = $output_container->{'container_details'}->{$out_loc};
    if ( scalar keys %{$in_details}  ) {
      my $out_loc_dec = wtsi_clarity::util::well_mapper::get_location_in_decimal($out_loc);
      my $inp_loc_dec = wtsi_clarity::util::well_mapper::get_location_in_decimal($in_details->{'input_location'});
      my $sample_volume = $in_details->{'sample_volume'};
      my $buffer_volume = $in_details->{'buffer_volume'};
      my $input_uri = $in_details->{'input_uri'};
      my $input_type    = $data->{'input_container_info'}->{$input_uri}->{'type'};
      my $input_barcode = $data->{'input_container_info'}->{$input_uri}->{'barcode'};

      # print "$input_barcode;;$input_type;$inp_loc_dec;;$sample_volume\n";

      my $input_sample_string  = qq{A;$input_barcode;;$input_type;$inp_loc_dec;;$sample_volume};
      my $output_sample_string = qq{D;$output_barcode;;$output_type;$out_loc_dec;;$sample_volume};
      my $w_string = q{W;};

      my $input_buffer_string  = qq{A;BUFF;;96-TROUGH;$inp_loc_dec;;$buffer_volume};
      my $output_buffer_string = qq{D;$output_barcode;;$output_type;$out_loc_dec;;$buffer_volume};

      push $sample_output, $input_sample_string;
      push $sample_output, $output_sample_string;
      push $sample_output, $w_string;
      push $buffer_output, $input_buffer_string;
      push $buffer_output, $output_buffer_string;
      push $buffer_output, $w_string;
    }
  }
  return ($sample_output, $buffer_output);
}

################# worksheet #################

sub _create_worksheet_file {
  my ($containers_data) = @_;
  my $pdf = PDF::API2->new();

  # for each output container, we produce a new page...
  while (my ($uri, $data) = each %{$containers_data->{'output_container_info'}} ) {
    my $page = $pdf->page();
    $page->mediabox('A4');
    my $font = $pdf->corefont('Helvetica-Bold');
    my ($table_data, $table_properties) = _get_table_data($data->{'container_details'}, $nb_col, $nb_row);

    _add_title_to_page($page, $font, $containers_data, $uri);

    _add_sources_to_page($pdf, $page, $font, $containers_data, $uri);
    _add_destinations_to_page($pdf, $page, $font, $containers_data, $uri);
    _add_buffer_to_page($pdf, $page, $font, $table_data, $table_properties);
  }

  my $tmpdir = File::Temp->newdir(CLEANUP => 1);
  my $filename = $tmpdir->dirname().'/worksheet.pdf';
  $pdf->saveas($filename);
}

sub _add_title_to_page {
  my ($page, $font, $containers_data, $uri) = @_;
  _add_text_to_page($page, $font, _get_title($containers_data, $uri, 'Cherrypicking'), $left_margin, $title_height, $title_size);
  return;
}

sub _add_sources_to_page {
  my ($pdf, $page, $font, $containers_data, $uri) = @_;
  my $data = _get_source_plate_data($containers_data, $uri);
  _add_text_to_page($page, $font, 'Source plates', $left_margin, $source_table_height+$subtitle_shift, $subtitle_size);
  _add_table_to_page($pdf, $page, $data,           $left_margin, $source_table_height);
  return;
}

sub _add_destinations_to_page {
  my ($pdf, $page, $font, $containers_data, $uri) = @_;
  my $data = _get_destination_plate_data($containers_data, $uri);
  _add_text_to_page($page, $font, 'Destination plates', $left_margin, $destination_table_height+$subtitle_shift, $subtitle_size);
  _add_table_to_page($pdf, $page, $data,                $left_margin, $destination_table_height);
  return;
}

sub _add_buffer_to_page {
  my ($pdf, $page, $font, $table_data, $table_properties) = @_;
  _add_text_to_page($page, $font, 'Buffer required', $left_margin, $buffer_table_height+$subtitle_shift, $subtitle_size);
  _add_buffer_table_to_page($pdf, $page, $table_data, $table_properties, $buffer_table_height);
  return;
}

sub _add_buffer_table_to_page {
  my ($pdf, $page, $table_data, $table_properties, $y) = @_;
  my $pdftable = PDF::Table->new();

  $pdftable->table(
    # required params
    $pdf, $page, $table_data,

    x => $left_margin,
    w => ($nb_col + 1)*$col_width,
    start_y => $y,
    start_h => 600,
    padding => 2,
    font  =>      $pdf->corefont('Courier-Bold', -encoding => 'latin1'),
    cell_props => $table_properties,
    column_props => [
      { min_w => $col_width/2, max_w => $col_width/2, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width, max_w => $col_width, },
      { min_w => $col_width/2, max_w => $col_width/2, },
    ]
  );
  return;
}

## no critic(Subroutines::ProhibitManyArgs)
sub _add_text_to_page {
  my ($page, $font, $content, $x, $y, $font_size) = @_;
  my $text = $page->text();
  $text->font($font, $font_size);
  $text->translate($x, $y);
  $text->text($content);
  return;
}
## use critic

sub _add_table_to_page {
  my ($pdf, $page, $data, $x, $y) = @_;
  my $pdftable_source = PDF::Table->new();
  $pdftable_source->table(
    $pdf, $page, $data,
    x => $x, w => 400,
    start_y    => $y,
    start_h    => 600,
    font_size  => 9,
    padding    => 4,
    font       => $pdf->corefont('Helvetica', -encoding => 'latin1'),
  );
  return;
}

sub _get_title {
  my ($data, $uri, $action) = @_;
  my $purpose = $data->{'output_container_info'}->{$uri}->{'purpose'};
  my $process = $data->{'process_id'};
  return 'Process '.$process.' - '.$purpose.' - '.$action;
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
  my $table_data = [];

  push $table_data , ['Plate name', 'Barcode', 'Freezer', 'Shelf', 'Rack', 'Tray'];

  foreach my $key (sort keys %{$input_plates} ) {
    my $plate_name = $data->{'input_container_info'}->{$key}->{'plate_name'};
    my $barcode = $data->{'input_container_info'}->{$key}->{'barcode'};
    my $freezer = $data->{'input_container_info'}->{$key}->{'freezer'};
    my $shelf = $data->{'input_container_info'}->{$key}->{'shelf'};
    my $rack = $data->{'input_container_info'}->{$key}->{'rack'};
    my $tray = $data->{'input_container_info'}->{$key}->{'tray'};
    push $table_data, [$plate_name, $barcode, $freezer, $shelf, $rack, $tray];
  }
  return $table_data;
}

sub _get_destination_plate_data {
  my ($data, $uri) = @_;

  my $table_data = [];
  push $table_data , ['Plate name', 'Barcode', 'Wells'];

  my $plate_name = $data->{'output_container_info'}->{$uri}->{'plate_name'};
  my $barcode = $data->{'output_container_info'}->{$uri}->{'barcode'};
  my $wells = $data->{'output_container_info'}->{$uri}->{'wells'};
  push $table_data, [$plate_name, $barcode, $wells];
  return $table_data;
}

sub _get_table_data {
  my ($data, $nb_col, $nb_row) = @_;

  my $table_data = [];
  my $table_properties = [];
  my @list_of_colours = ('#F5BA7F', '#F5E77D', '#7DD3F5', '#DB7DF5');

  my $colours = _get_colour_data($data, @list_of_colours);

  foreach my $j (0..$nb_row+1) {
    my $row = [];
    my $row_properties = [];
    foreach my $i (0..$nb_col+1) {
      my ($content, $properties) = _get_cell($data, $colours, $i, $j, $nb_col, $nb_row);
      push $row, $content;
      push $row_properties, $properties;
    }
    push $table_data, $row;
    push $table_properties, $row_properties;
  }

  return ($table_data, $table_properties);
}

## no critic(Subroutines::ProhibitManyArgs)
sub _get_cell {
  my ($data, $colours, $i, $j, $nb_col, $nb_row) = @_;

  my $content;
  my $properties;

  if (my $pos = _get_location($i,$j, $nb_col, $nb_row)) {
    $content = _get_cell_content($data, $pos);
    $properties = _get_cell_properties($data, $colours, $pos);

  } else {
    $content = _get_legend_content($i,$j, $nb_col, $nb_row);
    $properties = _get_legend_properties($i,$j, $nb_col, $nb_row);
  }
  return ($content, $properties);
}
## use critic

sub _get_cell_content {
  my ($data, $pos) = @_;
  my $cell = $data->{$pos};
  if ($cell) {
    my $container_id = $cell->{'input_id'};
    $container_id =~ s/\-//xms;

    my $id = $container_id;
    my $loc = $cell->{'input_location'};
    my $v = $cell->{'sample_volume'};
    my $b = $cell->{'buffer_volume'};
    return $loc."\n".$id."\nv".(int $v).' b'.(int $b);
  }
  return q{};
}

sub _get_legend_content {
  my ($i, $j, $nb_col, $nb_row) = @_;
  if (0 == $i || $nb_col < $i ){
    if (0 == $j || $nb_row < $j ){
      return q{};
    }
    return ".\n".chr($A_CHAR_CODE+$j)."\n.";
  }
  if (0 == $j || $nb_row < $j ){
    return $i;
  }
  return;
}

sub _get_cell_properties {
  my ($data, $colours, $pos) = @_;
  my $id = $data->{$pos}->{'input_id'};
  if (defined $id){
    my $col = $colours->{$id};
    return {
      background_color => $col,
      font_size=> 7,
      justify => 'center',
    };
  } else {
    return {
      background_color => 'white',
      font_size=> 7,
      justify => 'center',
    }
  }
}

sub _get_legend_properties {
  my ($i, $j, $nb_col, $nb_row) = @_;

  return {
    background_color => 'white',
    font_size=> 7,
    justify => 'center',
  }
}

sub _get_colour_data {
  my ($data, @list_of_colours) = @_;
  my $hash_colour = {};

  foreach my $key (sort keys %{$data}) {
    my $id = $data->{$key}->{'input_id'};
    if (defined $id && !defined $hash_colour->{$id}){
      $hash_colour->{$id} = shift @list_of_colours;
    }
  }
  return $hash_colour;
}

sub _get_location {
  my ($i, $j, $nb_col, $nb_row) = @_;
  if (0 == $i || $nb_col < $i ){
    # top or bottom row
    return;
  }
  if (0 == $j || $nb_row < $j ){
    # top or bottom row
    return;
  }
  return (chr $A_CHAR_CODE+$j).q{:}.$i;
}

sub _get_containers_data {
  my ($self) = @_;

  my $artifacts_tmp       = $self->fetch_targets_hash($ARTIFACT_PATH);
  my $previous_processes  = $self->fetch_targets_hash($PREVIOUS_PROC);
  my $previous_artifacts  = $self->fetch_targets_hash($PREVIOUS_PROC, $ARTIFACT_PATH);

  my $oi_map = $self->_get_oi_map($previous_processes);

  my $all_data = {};
  my $process_id  = ($self->find_elements($self->process_doc, $PROCESS_ID_PATH))[0]->getValue();
  $process_id =~ s/\-//xms;
  $all_data->{'process_id'} = $process_id;

  while (my ($uri, $out_artifact) = each %{$artifacts_tmp} ) {
    if ($uri =~ /(.*)[?].*/xms){
      my $in_artifact = $previous_artifacts->{$oi_map->{$uri}};


      my $buffer_volume = 0;
      my $out_location      = ($self->find_elements($out_artifact,    $LOCATION_PATH      ) )[0] ->textContent;
      my $out_container_uri = ($self->find_elements($out_artifact,    $CONTAINER_URI_PATH ) )[0] ->getValue();
      my $out_container_id  = ($self->find_elements($out_artifact,    $CONTAINER_ID_PATH  ) )[0] ->getValue();
      my $sample_volume     = ($self->find_udf_element($out_artifact, $SAMPLE_VOLUME_PATH ) )    ->textContent;
      my $buffer_volume_elmt= ($self->find_udf_element($out_artifact, $BUFFER_VOLUME_PATH ) ) ;
      if ($buffer_volume_elmt) {
        $buffer_volume      = ($buffer_volume_elmt)->textContent;
      }
      my $in_location       = ($self->find_elements($in_artifact,     $LOCATION_PATH      ) )[0] ->textContent;
      my $in_container_uri  = ($self->find_elements($in_artifact,     $CONTAINER_URI_PATH ) )[0] ->getValue();
      my $in_container_id   = ($self->find_elements($in_artifact,     $CONTAINER_ID_PATH  ) )[0] ->getValue();

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'output_container_info'}->{$out_container_uri})
      {
        my $out_container = $self->fetch_and_parse($out_container_uri);

        my $barcode       = $self->find_clarity_element($out_container, 'name')->textContent;
        my $purpose       = $self->find_udf_element($out_container,    $PURPOSE_PATH)  ->textContent;
        if (!defined $purpose) { $purpose = ' Unknown ' ; }
        my $name          = $out_container_id;
        $name =~ s/\-//xms;

        # to get the wells
        my $out_container_type_uri  = ($self->find_elements($out_container, $CONTAINER_TYPE_URI) )[0] ->getValue();
        my $out_container_type_name = ($self->find_elements($out_container, $CONTAINER_TYPE_NAME) )[0] ->getValue();
        my $out_container_type      = $self->fetch_and_parse($out_container_type_uri);
        my $x  = ($self->find_elements($out_container_type,    $CONTAINER_TYPE_Y) )[0] ->textContent;
        my $y  = ($self->find_elements($out_container_type,    $CONTAINER_TYPE_Y) )[0] ->textContent;

        $all_data->{'output_container_info'}->{$out_container_uri}->{'purpose'}    = $purpose;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'plate_name'} = $name;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'barcode'}    = $barcode;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'type'}       = $out_container_type_name;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'wells'}      = $x*$y;
      }

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'input_container_info'}->{$in_container_uri})
      {
        my $in_container= $self->fetch_and_parse($in_container_uri);

        my $freezer = q{};
        my $shelf   = q{};
        my $tray    = q{};
        my $rack    = q{};

        my $freezer_elmt     = $self->find_udf_element($in_container,    $FREEZER_PATH) ;
        my $shelf_elmt       = $self->find_udf_element($in_container,    $SHELF_PATH);
        my $tray_elmt        = $self->find_udf_element($in_container,    $TRAY_PATH);
        my $rack_elmt        = $self->find_udf_element($in_container,    $RACK_PATH);

        if ($freezer_elmt) {   $freezer = $freezer_elmt->textContent; }
        if ($shelf_elmt)   {   $shelf = $shelf_elmt->textContent;     }
        if ($tray_elmt)    {   $tray = $tray_elmt->textContent;       }
        if ($rack_elmt)    {   $rack = $rack_elmt->textContent;       }

        my $barcode     = $self->find_clarity_element($in_container, 'name')      ->textContent;
        my $type_name   = ($self->find_elements($in_container, $CONTAINER_TYPE_NAME) )[0] ->getValue();
        my $name        = $in_container_id;
        $name =~ s/\-//xms;

        $all_data->{'input_container_info' }->{$in_container_uri }->{'plate_name'} = $name;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'barcode'}    = $barcode;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'type'}    = $type_name;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'freezer'}    = $freezer;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'shelf'}      = $shelf;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'rack'}       = $rack;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'tray'}       = $tray;
      }

      $all_data->{'output_container_info'}->{$out_container_uri}->{'container_details'}->{$out_location} = {
                            'input_id'             => $in_container_id,
                            'input_location'       => $in_location,
                            'sample_volume'        => $sample_volume,
                            'buffer_volume'        => $buffer_volume,
                            'input_uri'            => $in_container_uri,
                          };
    }
  }

  return $all_data;
}

has '_oi_map' => (
  isa        => 'HashRef',
  is         => 'rw',
  required   => 0,
  default => sub { {} },
);

sub _get_oi_map {
  my ($self, $previous_processes) = @_;

  if (keys $self->_oi_map) {
    return $self->_oi_map;
  }
  my $oi_map = {};
  ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  while (my ($uri, $proc) = each %{$previous_processes} ) {
    my $proc_io_maps = $self->find_elements($proc, q{./input-output-map});
    foreach my $proc_io_map (@{$proc_io_maps}){
      my $in  = $proc_io_map->findnodes( q{./input/@uri}  );
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

wtsi_clarity::epp::sm::worksheet

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::worksheet->new(process_url => 'http://my.com/processes/3345')->run();

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

=item XML::LibXML

=item Readonly

=item PDF::API2

=item PDF::Table

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

