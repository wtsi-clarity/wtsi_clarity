package wtsi_clarity::epp::sm::worksheet;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use PDF::API2;
use PDF::Table;

use wtsi_clarity::util::request;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_PATH      => q(/prc:process/input-output-map/input/@post-process-uri);
Readonly::Scalar my $PREVIOUS_PROC      => q(/prc:process/input-output-map/input/parent-process/@uri);
Readonly::Scalar my $PROCESS_ID_PATH    => q(/prc:process/@limsid);

Readonly::Scalar my $SAMPLE_PATH        => q(/art:artifact/sample/@uri);
Readonly::Scalar my $LOCATION_PATH      => q(/art:artifact/location/value);
Readonly::Scalar my $CONTAINER_URI_PATH => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $CONTAINER_ID_PATH  => q(/art:artifact/location/container/@limsid);

Readonly::Scalar my $CONTAINER_TYPE_URI => q{/con:container/type/@uri};
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

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_elements';


our $VERSION = '0.0';

my $width = 40 ;
my $nb_col = 12;
my $nb_row = 8;

override 'run' => sub {
  my $self= shift;
  super();

  my $containers_data = $self->_get_containers_data();
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

  $pdf->saveas("new.pdf");
  return 1;
};

sub _add_title_to_page {
  my ($page, $font, $containers_data, $uri) = @_;
  _add_text_to_page($page, $font, _get_title($containers_data, $uri, "Cherrypicking"), 20, 780, 20);
}

sub _add_sources_to_page {
  my ($pdf, $page, $font, $containers_data, $uri) = @_;
  my $y = 700;
  my $data = _get_source_plate_data($containers_data, $uri);
  _add_text_to_page($page, $font, "Source plates", 20, $y+20, 12);
  _add_table_to_page($pdf, $page, $data,           20, $y);
}

sub _add_destinations_to_page {
  my ($pdf, $page, $font, $containers_data, $uri) = @_;
  my $y = 450;
  my $data = _get_destination_plate_data($containers_data, $uri);
  _add_text_to_page($page, $font, "Destination plates", 20, $y+20, 12);
  _add_table_to_page($pdf, $page, $data,                20, $y);
}

sub _add_buffer_to_page {
    my ($pdf, $page, $font, $table_data, $table_properties) = @_;
    my $y = 350;

    _add_text_to_page($page, $font, "Buffer required", 20, $y+20, 12);
    _add_buffer_table_to_page($pdf, $page, $table_data, $table_properties, $y);
}

sub _add_buffer_table_to_page {
    my ($pdf, $page, $table_data, $table_properties, $y) = @_;
    my $pdftable = new PDF::Table;

    $pdftable->table(
      # required params
      $pdf, $page, $table_data,
      x => 20,
      w => ($nb_col + 1)*$width,
      start_y => $y,
      start_h => 600,
      padding => 2,
      font  =>      $pdf->corefont("Courier-Bold", -encoding => "latin1"),
      cell_props => $table_properties,
      column_props => [ 
        { min_w => $width/2, max_w => $width/2, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width, max_w => $width, },
        { min_w => $width/2, max_w => $width/2, },
      ]
    );
}

sub _add_text_to_page {
  my ($page, $font, $content, $x, $y, $font_size) = @_;
  my $text = $page->text();
  $text->font($font, $font_size);
  $text->translate($x, $y);
  $text->text($content);
}

sub _add_table_to_page {
  my ($pdf, $page, $data, $x, $y) = @_;
  my $pdftable_source = new PDF::Table;
  $pdftable_source->table(
    $pdf, $page, $data,
    x => $x, w => 400,
    start_y    => $y,
    start_h    => 600,
    font_size  => 9,
    padding    => 4,        
    font       => $pdf->corefont("Helvetica", -encoding => "latin1"),
  );
}

sub _get_title {
  my ($data, $uri, $action) = @_;
  my $purpose = $data->{'output_container_info'}->{$uri}->{'purpose'};
  my $process = $data->{'process_id'};
  return "Process ".$process." - ".$purpose." - ".$action;
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

  foreach $uri (sort keys %{$input_plates} ) {
    my $plate_name = $data->{'input_container_info'}->{$uri}->{'plate_name'};
    my $barcode = $data->{'input_container_info'}->{$uri}->{'barcode'};
    my $freezer = $data->{'input_container_info'}->{$uri}->{'freezer'};
    my $shelf = $data->{'input_container_info'}->{$uri}->{'shelf'};
    my $rack = $data->{'input_container_info'}->{$uri}->{'rack'};
    my $tray = $data->{'input_container_info'}->{$uri}->{'tray'};
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

  for (my $j=0; $j <= $nb_row+1; $j++) {
    my $row = [];
    my $row_properties = [];
    for (my $i=0; $i <= $nb_col+1; $i++) {
      my ($content, $properties) = _get_cell($data, $colours, $i, $j, $nb_col, $nb_row);
      push $row, $content;
      push $row_properties, $properties;
    }
    push $table_data, $row;
    push $table_properties, $row_properties;
  }

  return ($table_data, $table_properties);
}

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

sub _get_cell_content {
  my ($data, $pos) = @_;
  my $cell = $data->{$pos};
  if ($cell) {
    my $container_id = $cell->{'input_id'};
    $container_id =~ s/\-//;

    my $id = $container_id;
    my $loc = $cell->{'input_location'};
    my $v = $cell->{'sample_volume'};
    my $b = $cell->{'buffer_volume'};
    return $loc."\n".$id."\nv".int($v)." b".int($b);
  }
  return "";
}

sub _get_legend_content {
  my ($i, $j, $nb_col, $nb_row) = @_;
  if (0 == $i || $nb_col < $i ){
    if (0 == $j || $nb_row < $j ){
      return "";
    }
    return ".\n".chr(64+$j)."\n.";
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
      justify => "center",
    };
  } else {
    return {
      background_color => 'white',
      font_size=> 7,
      justify => "center",
    }
  }
}

sub _get_legend_properties {
  my ($i, $j, $nb_col, $nb_row) = @_;
  
  return {
    background_color => 'white',
    font_size=> 7,
    justify => "center",
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
  return chr(64+$j).":".($i);
}

sub _get_containers_data {
  my ($self) = @_;

  my $artifacts_tmp       = $self->fetch_targets_hash($ARTIFACT_PATH);
  my $previous_processes  = $self->fetch_targets_hash($PREVIOUS_PROC);
  my $previous_artifacts  = $self->fetch_targets_hash($PREVIOUS_PROC, $ARTIFACT_PATH);

  my $oi_map = $self->_get_oi_map($previous_processes);

  my $all_data = {};

  my $process_id  = ($self->find_elements($self->process_doc, $PROCESS_ID_PATH))[0]->getValue();
  $process_id =~ s/\-//;
  $all_data->{'process_id'} = $process_id;

  while (my ($uri, $out_artifact) = each %{$artifacts_tmp} ) {
    if ($uri =~ /(.*)\?.*/){
      my $in_artifact = $previous_artifacts->{$oi_map->{$uri}};



      my $out_location      = ($self->find_elements($out_artifact,    $LOCATION_PATH      ) )[0] ->textContent;
      my $out_container_uri = ($self->find_elements($out_artifact,    $CONTAINER_URI_PATH ) )[0] ->getValue();
      my $out_container_id  = ($self->find_elements($out_artifact,    $CONTAINER_ID_PATH  ) )[0] ->getValue();
      my $sample_volume     = ($self->find_udf_element($out_artifact, $SAMPLE_VOLUME_PATH ) )    ->textContent;
      my $buffer_volume     = ($self->find_udf_element($out_artifact, $BUFFER_VOLUME_PATH ) )    ->textContent;
      my $in_location       = ($self->find_elements($in_artifact,     $LOCATION_PATH      ) )[0] ->textContent;
      my $in_container_uri  = ($self->find_elements($in_artifact,     $CONTAINER_URI_PATH ) )[0] ->getValue();
      my $in_container_id   = ($self->find_elements($in_artifact,     $CONTAINER_ID_PATH  ) )[0] ->getValue();

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'output_container_info'}->{$out_container_uri}) 
      {
        my $out_container = $self->fetch_and_parse($out_container_uri);

        my $barcode       = $self->find_clarity_element($out_container, "name")->textContent;
        my $purpose       = $self->find_udf_element($out_container,    $PURPOSE_PATH)  ->textContent;
        if (!defined $purpose) { $purpose = " Unknown " ; }
        my $name          = $out_container_id; 
        $name =~ s/\-//;

        # to get the wells
        my $out_container_type_uri  = ($self->find_elements($out_container, $CONTAINER_TYPE_URI) )[0] ->getValue();
        my $out_container_type      = $self->fetch_and_parse($out_container_type_uri);
        my $x  = ($self->find_elements($out_container_type,    $CONTAINER_TYPE_Y) )[0] ->textContent;
        my $y  = ($self->find_elements($out_container_type,    $CONTAINER_TYPE_Y) )[0] ->textContent;

        $all_data->{'output_container_info'}->{$out_container_uri}->{'purpose'}    = $purpose;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'plate_name'} = $name;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'barcode'}    = $barcode;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'wells'}      = $x*$y;
      }

      # we only do this part when it's a container that we don't know yet...
      if (!defined $all_data->{'input_container_info'}->{$in_container_uri})
      {
        my $in_container= $self->fetch_and_parse($in_container_uri);

        my $freezer     = $self->find_udf_element($in_container,    $FREEZER_PATH)->textContent;
        my $shelf       = $self->find_udf_element($in_container,    $SHELF_PATH)  ->textContent;
        my $tray        = $self->find_udf_element($in_container,    $TRAY_PATH)   ->textContent;
        my $rack        = $self->find_udf_element($in_container,    $RACK_PATH)   ->textContent;
        my $barcode     = $self->find_clarity_element($in_container, "name")      ->textContent;
        my $name        = $in_container_id; 
        $name =~ s/\-//;

        $all_data->{'input_container_info' }->{$in_container_uri }->{'plate_name'} = $name;
        $all_data->{'input_container_info' }->{$in_container_uri }->{'barcode'}    = $barcode;
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

  # print Dumper $all_data;

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

  while (my ($uri, $proc) = each %{$previous_processes} ) {
    my $proc_io_maps = $self->find_elements($proc, q{./input-output-map});
    foreach my $proc_io_map (@{$proc_io_maps}){
      my $in  = $proc_io_map->findnodes(q{./input/@uri});
      my $out = $proc_io_map->findnodes(q{./output/@uri});
      $oi_map->{$out} = $in;
    }
  }

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

  Creates a pdf document describing the plates.

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

