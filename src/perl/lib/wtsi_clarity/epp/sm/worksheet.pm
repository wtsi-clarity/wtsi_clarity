package wtsi_clarity::epp::sm::worksheet;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;
use DateTime;
use Data::Dumper;
use PDF::API2;
use PDF::Table;

use wtsi_clarity::util::request;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACT_PATH   => q(/prc:process/input-output-map/input/@post-process-uri);
Readonly::Scalar my $PREVIOUS_PROC   => q(/prc:process/input-output-map/input/parent-process/@uri);
Readonly::Scalar my $SAMPLE_PATH     => q(/art:artifact/sample/@uri);
Readonly::Scalar my $CONTAINER_PATH  => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $TARGET_NAME     => q(QC Complete);


Readonly::Scalar my $PURPOSE_PATH    => q(WTSI Container Purpose Name);

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

  my $containers_data = $self->get_containers_data();
  my $pdf = PDF::API2->new();


  #
  while (my ($uri, $data) = each %{$containers_data->{'output_container_info'}} ) {

    my ($table_data, $table_properties) = get_table_data($data->{'container_details'}, $nb_col, $nb_row);
  #
    my $page = $pdf->page();
    $page->mediabox('A4');
    my $font = $pdf->corefont('Helvetica-Bold');
    my $title = $page->text();
    $title->font($font, 20);
    $title->translate(20, 700);
    $title->text(get_title($containers_data, $uri));




    my $pdftable = new PDF::Table;

    my $left_edge_of_table = 20;

    $pdftable->table(
      # required params
      $pdf,
      $page,
      $table_data,
      x => $left_edge_of_table,
      w => ($nb_col + 1)*$width,
      start_y => 400,
      # next_y  => 720,
      start_h => 600,
      # next_h  => 350,
      # font_size      => 6,
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
  #
  }
  #
  $pdf->saveas("new.pdf");


  return 1;
};

sub get_table_data {
  my ($data, $nb_col, $nb_row) = @_;

  my $table_data = [];
  my $table_properties = [];
  my @list_of_colours = ('#F5BA7F', '#F5E77D', '#7DD3F5', '#DB7DF5');

  my $colours = get_colour_data($data, @list_of_colours);

  for (my $j=0; $j <= $nb_row+1; $j++) {
    my $row = [];
    my $row_properties = [];
    for (my $i=0; $i <= $nb_col+1; $i++) {
      my ($content, $properties) = get_cell($data, $colours, $i, $j, $nb_col, $nb_row);
      push $row, $content;
      push $row_properties, $properties;
    }
    push $table_data, $row;
    push $table_properties, $row_properties;
  }

  return ($table_data, $table_properties);
}

sub get_cell {
  my ($data, $colours, $i, $j, $nb_col, $nb_row) = @_;

  my $content;
  my $properties;

  if (my $pos = get_location($i,$j, $nb_col, $nb_row)) {
    $content = get_cell_content($data, $pos);
    $properties = get_cell_properties($data, $colours, $pos);

  } else {
    $content = get_legend_content($i,$j, $nb_col, $nb_row);
    $properties = get_legend_properties($i,$j, $nb_col, $nb_row);
  }

  #
  # my $content = get_cell_content($data, $i, $j);
  # my $properties = get_cell_properties($data, $i, $j);

  return ($content, $properties);
}

sub get_cell_content {
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

sub get_legend_content {
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

sub get_cell_properties {
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

sub get_legend_properties {
  my ($i, $j, $nb_col, $nb_row) = @_;
  
  return {
    background_color => 'white',
    font_size=> 7,
    justify => "center",
  }
}

sub get_colour_data {
  my ($data, @list_of_colours) = @_;
  # my @list_of_colours = ('red', 'green', 'blue', 'yellow', 'orange');
  my $hash_colour = {};

  foreach my $key (sort keys %{$data}) {
    my $id = $data->{$key}->{'input_id'};
    if (defined $id && !defined $hash_colour->{$id}){
      $hash_colour->{$id} = shift @list_of_colours;
    }
  }
  return $hash_colour; 
}

sub get_location {
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

sub get_containers_data {
  my ($self) = @_;

  my $artifacts_tmp       = $self->fetch_targets_hash($ARTIFACT_PATH);
  my $previous_processes  = $self->fetch_targets_hash($PREVIOUS_PROC);
  my $previous_artifacts  = $self->fetch_targets_hash($PREVIOUS_PROC, q(/prc:process/input-output-map/input/@post-process-uri));



  my $oi_map = {};

  while (my ($uri, $proc) = each %{$previous_processes} ) {
    my $proc_io_maps = $self->find_elements($proc, q{./input-output-map});
    foreach my $proc_io_map (@{$proc_io_maps}){
      my $in  = $proc_io_map->findnodes(q{./input/@uri});
      my $out = $proc_io_map->findnodes(q{./output/@uri});
      $oi_map->{$out} = $in;
    }
  }

  my $all_data = {};

  my $process_id  = ($self->find_elements($self->process_doc, q{/prc:process/@limsid}))[0]->getValue();
  $process_id =~ s/\-//;
  $all_data->{'process_id'} = $process_id;

  while (my ($uri, $out_artifact) = each %{$artifacts_tmp} ) {
    if ($uri =~ /(.*)\?.*/){
      my $in_artifact = $previous_artifacts->{$oi_map->{$uri}};

      my $out_location      = ($self->find_elements($out_artifact,    q{/art:artifact/location/value})             )[0] ->textContent;
      my $out_container_uri = ($self->find_elements($out_artifact,    q{/art:artifact/location/container/@uri})    )[0] ->getValue();
      my $sample_volume     = ($self->find_udf_element($out_artifact, q{Cherrypick Sample Volume})                 )    ->textContent;
      my $buffer_volume     = ($self->find_udf_element($out_artifact, q{Cherrypick Buffer Volume})                 )    ->textContent;
      my $in_location       = ($self->find_elements($in_artifact,     q{/art:artifact/location/value})             )[0] ->textContent;
      my $in_container_uri  = ($self->find_elements($in_artifact,     q{/art:artifact/location/container/@uri})    )[0] ->getValue();
      my $in_container_id   = ($self->find_elements($in_artifact,     q{/art:artifact/location/container/@limsid}) )[0] ->getValue();

      if (!defined $all_data->{'output_container_info'}->{$out_container_uri}) 
      {
        my $out_container= $self->fetch_and_parse($out_container_uri);
        my $purpose      = $self->find_udf_element($out_container,    $PURPOSE_PATH)  ->textContent;
        my $name         = $self->find_clarity_element($out_container, "name")->textContent;
        $name =~ s/\-//;
        print " >> ",$purpose,"\n";
        print " >> ",$name,"\n";
        $all_data->{'output_container_info'}->{$out_container_uri}->{'purpose'}    = $purpose;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'plate_name'} = $name;
        $all_data->{'output_container_info'}->{$out_container_uri}->{'barcode'}    = 'barcode';
        $all_data->{'output_container_info'}->{$out_container_uri}->{'wells'}      = 'wells';
      }

      if (!defined $all_data->{'input_container_info'}->{$in_container_uri})
      {
        $all_data->{'input_container_info' }->{$in_container_uri }->{'purpose'}    = 'purpose';
        $all_data->{'input_container_info' }->{$in_container_uri }->{'plate_name'} = 'another name';
        $all_data->{'input_container_info' }->{$in_container_uri }->{'barcode'}    = 'barcode';
      }

      $all_data->{'output_container_info'}->{$out_container_uri}->{'container_details'}->{$out_location} = {
                            'input_id'             => $in_container_id,
                            'input_location'       => $in_location,
                            'sample_volume'        => $sample_volume,
                            'buffer_volume'        => $buffer_volume,
                          };



    }
  }

  # print Dumper $all_data;

  return $all_data;
}

sub get_title {
  my ($data, $uri) = @_;
  my $purpose = $data->{'output_container_info'}->{$uri}->{'purpose'};
  my $process = $data->{'process_id'};
  return "Process ".$process." - ".$purpose." - Cherrypicking";
}

sub get_inputs_data {
  my ($data, $uri) = @_;
  my $purpose = $data->{'output_container_info'}->{$uri}->{'purpose'};
  my $process = $data->{'process_id'};
  return "Process ".$process." - ".$purpose." - Cherrypicking";
}

# sub get_targets_uri {
#   return ( $ARTIFACT_PATH , $SAMPLE_PATH);
# };
#
# sub update_one_target_data {
#   my ($self, $targetDoc, $targetURI, $value) = @_;
#
#   $self->set_udf_element_if_absent($targetDoc, $TARGET_NAME, $value);
#
#   return $targetDoc->toString();
# };
#
# sub get_data {
#   my ($self, $targetDoc, $targetURI) = @_;
#   return DateTime->now->strftime('%Y-%m-%d');
# };



# my @nodeList = $xml->findnodes($first)->get_nodelist();
# my @found_targets = ();
#
# if (scalar @xpaths != 0)
# {
#   foreach my $element (@nodeList)
#   {
#     my $partial_xml = $self->fetch_and_parse($element->getValue());
#     my @new_targets   = $self->_find_xml_recursively($partial_xml->getDocumentElement() , @xpaths);
#     push @found_targets, @new_targets;
#   }
#   return @found_targets;
# }
#

1;

__END__
