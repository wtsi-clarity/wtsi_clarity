package wtsi_clarity::epp::sm::pico_analyser;

use Moose;
use Carp;
use Readonly;
use File::Temp qw/ tempdir /;
use wtsi_clarity::file_parsing::dtx_concentration_calculator;
use wtsi_clarity::file_parsing::dtx_parser;
use wtsi_clarity::util::pdf::factory;
use Mojo::Collection 'c';

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar our $IN_OUT_PATH           => q(/prc:process/input-output-map/output[@output-type='Analyte']/..);
Readonly::Scalar our $INPUT_URIS_PATH       => q(/prc:process/input-output-map/input/@uri);
Readonly::Scalar our $OUTPUT_IDS_PATH       => q(/prc:process/input-output-map/output[@output-type='Analyte']/@limsid);
Readonly::Scalar our $ARTIFACT_PATH         => q(/art:details/art:artifact);
Readonly::Scalar our $ARTIFACT_NAME_PATH    => q(/art:artifact/name);
Readonly::Scalar our $CONTAINER_LIMSID_PATH => q(location/container/@limsid);
Readonly::Scalar our $FIRST_OUTPUT          => q(/prc:process/input-output-map[1]/output/@uri);
Readonly::Scalar our $SECOND_OUTPUT         => q(/prc:process/input-output-map[2]/output/@uri);
Readonly::Scalar our $FILE_URL_PATH         => q(/art:artifact/file:file/@uri);
Readonly::Scalar our $FILE_CONTENT_LOCATION => q(/file:file/content-location);
Readonly::Scalar our $ARTIFACT_LIMSID_PATH  => q(@limsid);
Readonly::Scalar our $STANDARD_PLATE_NAME   => q(StandardPlate);
Readonly::Scalar our $PICO_ASSAY_PLATE_NAME => q(PicoAssay);
Readonly::Scalar our $PROCESS_NAME          => q(Pico DTX (SM));
## use critic

our $VERSION = '0.0';

has 'analysis_file' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

override 'run' => sub {
  my $self= shift;
  super();

  # Fetch the files
  my ($dtx1, $dtx2, $standard) = $self->_get_dtx_files();

  # Do the analysis
  my $calculator = wtsi_clarity::file_parsing::dtx_concentration_calculator->new(
    standard_doc => $self->_dtx_parser->parse($standard),
    plateA_doc   => $self->_dtx_parser->parse($dtx1),
    plateB_doc   => $self->_dtx_parser->parse($dtx2),
  );

  my $results = $calculator->get_analysis_results();

  # Pass the results to the PDF generator
  my $pdf = wtsi_clarity::util::pdf::factory->createPDF('pico_analysis_results', $results);

  # Attach PDF to process
  $pdf->saveas(q{./} . $self->analysis_file);

  $self->_update_output_artifacts($results);

  # Pushes the updated version of the output artifacts onto the server
  my $response = $self->request->batch_update('artifacts', $self->_output_artifact_details);

  return;
};

has '_dtx_parser' => (
  isa      => 'wtsi_clarity::file_parsing::dtx_parser',
  is       => 'ro',
  required => 0,
  default  => sub { return wtsi_clarity::file_parsing::dtx_parser->new(); },
);

has '_output_ids' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__output_ids {
  my ($self) = @_;
  my $node_list = $self->process_doc->findnodes($OUTPUT_IDS_PATH);
  my @ids = map { $_->getValue() } $node_list->get_nodelist();
  return \@ids;
}

has '_output_artifact_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__output_artifact_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris = c->new(@{$self->_output_ids})
              ->map( sub {
                  return $base_url.'/artifacts/'.$_;
                } )
              ->each;

  return $self->request->batch_retrieve('artifacts', \@uris );
};

has '_input_to_output_map' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__input_to_output_map {
  my $self = shift;
  my %input_to_output_map = ();

  # we make this
  # {
  #   input_id => {
  #     'input_id'     => lims id of the input artifact
  #     'container_id' => container id of the input artifact (which is the same than for the output)
  #     'location'     => location of the input artifact (which is the same than for the output)
  #   }
  # }
  my $input_containers_map = c->new($self->_input_artifact_details->findnodes(q{/art:details/art:artifact})->get_nodelist())
              ->reduce( sub {
                ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
                my $input_id      = $b->findvalue( q{./@limsid}                       );
                my $container_id  = $b->findvalue( q{./location[1]/container/@limsid} );
                my $location      = $b->findvalue( q{./location[1]/value}             );
                ## use critic
                $a->{ $input_id } = { 'input_id' => $input_id, 'container_id' => $container_id, 'location' => $location };
                $a; } , {});

  my $c_in_out = c->new($self->process_doc->findnodes($IN_OUT_PATH)->get_nodelist());


  # then we add the output lims id using the input-output-map
  # {
  #   input_id => {
  #     'input_id'     => ...
  #     'container_id' => ...
  #     'location'     => ...
  #     'output_id'    => lims id of the output artifact
  #   }
  # }
  $input_containers_map = $c_in_out->reduce( sub {
    ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    my $input_id  = $b->findvalue ( q{input/@limsid}  );
    my $output_id = $b->findvalue ( q{output/@limsid} );
    ## use critic
    if (!defined $a->{$input_id} ) {
      croak qq{ There is a missing source artifacts in the input-output-map! ( $input_id )};
    }
    $a->{$input_id}->{'output_id'} = $output_id;
    return $a;
  }, $input_containers_map );

  # then we flip the input and output keys the output lims id using the input-output-map
  # {
  #   output_id => {
  #     'input_id'     => ...
  #     'container_id' => ...
  #     'location'     => ...
  #   }
  # }
  foreach my $input_id (keys %{$input_containers_map}) {
    my $output_id = $input_containers_map->{$input_id}->{'output_id'};
    delete $input_containers_map->{$input_id}->{'output_id'};
    $input_containers_map->{$output_id} = $input_containers_map->{$input_id};
    delete $input_containers_map->{$input_id};
  }

  return $input_containers_map;
}

sub _update_output_artifacts {
  my ($self, $data) = @_;
    ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
  c ->new($self->_output_artifact_details->findnodes(q{/art:details/art:artifact})->get_nodelist())
    ->each(sub{
        my $artifact    = $_;
        my $artifact_id = $artifact->findvalue( q{@limsid} );
        my $loc         = $self->_input_to_output_map->{$artifact_id}->{'location'};
        my $udf = $self->create_udf_element($self->process_doc, 'Concentration', $data->{$loc}->{'concentration'});
        $artifact->appendChild($udf);
       } ) ;
  ## use critic
  return $self->_output_artifact_details;
}

has '_input_uris' => (
  isa        => 'ArrayRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__input_uris {
  my ($self) = @_;

  my $input_node_list = $self->process_doc->findnodes($INPUT_URIS_PATH);
  my @input_uris = map { $_->getValue() } $input_node_list->get_nodelist();

  return \@input_uris;
}

has '_input_artifact_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifact_details {
  my $self = shift;
  return $self->request->batch_retrieve('artifacts', $self->_input_uris);
};

has '_container_to_artifact_map' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__container_to_artifact_map {
  my $self = shift;
  my %container_to_artifact_map = ();

  my @artifacts = $self->_input_artifact_details->findnodes($ARTIFACT_PATH)->get_nodelist();

  foreach my $artifact (@artifacts) {
    my $container_limsid = $artifact->findvalue($CONTAINER_LIMSID_PATH);
    my $artifact_limsid  = $artifact->findvalue($ARTIFACT_LIMSID_PATH);

    if (!exists $container_to_artifact_map{$container_limsid}) {
      $container_to_artifact_map{$container_limsid} = $artifact_limsid;
    }
  }

  return \%container_to_artifact_map;
}

sub _get_dtx_files {
  my $self = shift;
  my %files = ();

  my @artifact_limsids = values $self->_container_to_artifact_map;

  foreach (0..1) {
    my $artifact_limsid = $artifact_limsids[$_];
    my $process_xml = $self->process_doc->find_previous_process($artifact_limsid, $PROCESS_NAME);
    my ($dtx, $standard) = $self->_get_files($process_xml);

    my $key_name = 'dtx' . ($_ + 1);
    $files{$key_name} = $dtx;

    $files{'standard'} = $standard;
  }

  $self->_fetch_files(\%files);

  return ($files{'dtx1'}, $files{'dtx2'}, $files{'standard'});
}

sub _fetch_files {
  my ($self, $files) = @_;
  my $tempdir = tempdir( CLEANUP => 1);

  foreach my $file_name (keys %{$files}) {
    my $temp_file_path = $tempdir . qq{/$file_name};
    my ($server, $remote_path) = _extract_locations($files->{$file_name});
    my $file = $self->request->download_file($server, $remote_path, $temp_file_path);

    $files->{$file_name} = $temp_file_path;
  }

  return;
}

sub _extract_locations {
  my $url = shift;
  return $url =~ /sftp:\/\/([^\/]+)(.*)/smx;
}

sub _get_files {
  my ($self, $process_xml) = @_;

  my @output_analyte_urls = (
    $process_xml->findvalue($FIRST_OUTPUT),
    $process_xml->findvalue($SECOND_OUTPUT),
  );

  my @output_analyte_xml = map { $self->fetch_and_parse($_); } @output_analyte_urls;

  my $dtx;
  my $standard;

  # Always two files...
  foreach (0..1) {
    my ($file_name, $file_location) = $self->_extract_file_info($output_analyte_xml[$_]);
    if ($file_name eq $STANDARD_PLATE_NAME) {
      $standard = $file_location;
    } elsif ($file_name eq $PICO_ASSAY_PLATE_NAME) {
      $dtx = $file_location;
    }
  }

  return ($dtx, $standard);
}

sub _extract_file_info {
  my ($self, $output_analyte) = @_;

  my $file_url = $self->_extract_file_url($output_analyte);
  my $file_xml = $self->fetch_and_parse($file_url);

  return ($self->_extract_file_name($output_analyte), $self->_extract_file_location($file_xml));
}

sub _extract_file_url {
  my ($self, $output_analyte) = @_;
  my $file_url = $output_analyte->findvalue($FILE_URL_PATH);
  return $file_url;
}

sub _extract_file_name {
  my ($self, $output_analyte) = @_;
  my $file_name = $output_analyte->findvalue($ARTIFACT_NAME_PATH);
  return $file_name;
}

sub _extract_file_location {
  my ($self, $file_xml) = @_;
  my $file_location = $file_xml->findvalue($FILE_CONTENT_LOCATION);
  return $file_location;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::pico_analyser

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::pico_analyser->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will find the DTX files for the 2 plates, fetch their standard file, run analysis and
  produce a PDF of the results

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item List::MoreUtils;

=item wtsi_clarity::util::batch

=item wtsi_clarity::util::clarity_elements

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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