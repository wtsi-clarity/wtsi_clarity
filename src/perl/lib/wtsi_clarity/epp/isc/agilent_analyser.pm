package wtsi_clarity::epp::isc::agilent_analyser;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';

use wtsi_clarity::isc::agilent::analyser;
use wtsi_clarity::isc::agilent::file_validator;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $BATCH_CONTAINER_PATH           => q{ /art:details/art:artifact/location/container/@limsid };
Readonly::Scalar my $BATCH_ARTIFACTS_SAMPLE_ID_PATH => q{ /art:details/art:artifact/sample/@limsid };
Readonly::Scalar my $BATCH_ARTIFACTS_PATH           => q{ /art:details/art:artifact };
Readonly::Scalar my $BATCH_SAMPLES_PATH             => q{ /smp:details/smp:sample };
Readonly::Scalar my $CONTAINER_NAMES_PATH           => q{ /con:details/con:container/name/text() };
Readonly::Scalar my $OUTPUT_IDS_PATH                => q{ /prc:process/input-output-map/output[@output-type='Analyte']/@limsid};
Readonly::Scalar my $BATCH_CONTAINER_PLACEMENT_PATH => q{ /con:details/con:container/placement };

Readonly::Scalar my $CONCENTRATION_UDF         => q{Concentration};
Readonly::Scalar my $MOLARITY_UDF              => q{WTSI Molarity};
Readonly::Scalar my $SIZE_UDF                  => q{WTSI Lib Size};

Readonly::Scalar my $CONCENTRATION_MAX_PATH    => q{./udf:field[@name='WTSI Lib QC Conc Max']/text()};
Readonly::Scalar my $CONCENTRATION_MIN_PATH    => q{./udf:field[@name='WTSI Lib QC Conc Min']/text()};
Readonly::Scalar my $MOLARITY_MAX_PATH         => q{./udf:field[@name='WTSI Pre Cap Lib Pool Molarity Max']/text()};
Readonly::Scalar my $MOLARITY_MIN_PATH         => q{./udf:field[@name='WTSI Pre Cap Lib Pool Min']/text()};
Readonly::Scalar my $SIZE_MAX_PATH             => q{./udf:field[@name='WTSI Pre Cap Lib Pool Size Max']/text()};
Readonly::Scalar my $SIZE_MIN_PATH             => q{./udf:field[@name='WTSI Pre Cap Lib Pool Size Min']/text()};
Readonly::Scalar my $DEFAULT_CONCENTRATION_MAX => 250.00;
Readonly::Scalar my $DEFAULT_CONCENTRATION_MIN => 310.00;
Readonly::Scalar my $DEFAULT_SIZE_MAX          => 0.0;
Readonly::Scalar my $DEFAULT_MOLARITY_MAX      => 0.0;
Readonly::Scalar my $DEFAULT_MOLARITY_MIN      => 1_000_000;
## use critic

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;
  super();
  return $self->_main_method();
};

sub _main_method {
  my $self = shift;
  $self->_precheck();
  $self->_update_output_details();
  $self->_check_range();
  return $self->request->batch_update('artifacts', $self->_output_details);
}

# members

has '_output_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has '_output_container_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has '_sample_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has '_source_barcode' => (
  isa => 'Str',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

has '_map_artid_sampleid' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

has '_map_artid_range' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

has '_map_artid_location' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

has '_files_content' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

has '_analysis_results' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

has '_mapping_details' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);


# builders

sub _build__output_details {
 my $self = shift;
 return $self->build_details($self->process_doc, 'artifacts', $OUTPUT_IDS_PATH);
}

sub _build__output_container_details {
  my $self = shift;
 return $self->build_details($self->_output_details, 'containers', $BATCH_CONTAINER_PATH);
}

sub _build__sample_details {
  my $self = shift;
 return $self->build_details($self->_output_details, 'samples', $BATCH_ARTIFACTS_SAMPLE_ID_PATH);
}

sub _build__source_barcode {
  my $self = shift;

  my $names = $self->grab_values($self->_output_container_details, $CONTAINER_NAMES_PATH);

  if ( @{$names} > 1 ) {
    croak qq{It appears that there is more than one plate! This behaviour is not supported.};
  }
  if ( @{$names} < 1 ) {
    croak qq{It appears that there no plate barcode!};
  }
  return @{$names}[0];
}

sub _build__map_artid_sampleid {
  my $self = shift;

  return c->new($self->_output_details->findnodes($BATCH_ARTIFACTS_PATH)->get_nodelist())
            ->reduce( sub {
                my $node = $b;
                my @samples_ids  = $node->find( qq{./sample/\@limsid} )->get_nodelist();
                my @artifact_ids = $node->find( qq{./\@limsid}        )->get_nodelist();

                if (scalar @samples_ids != 1) {
                  croak qq{The number of 'samples' tag is not correct.};
                }
                if (scalar @artifact_ids != 1) {
                  croak qq{The number of 'artifact_ids' tag is not correct.};
                }

                my $sample =$samples_ids[0]->textContent();
                $a->{ $artifact_ids[0]->textContent() } = $sample;
                return $a;
              }, {} );
}

sub _build__map_artid_range {
  my $self = shift;

  return c->new($self->_sample_details->findnodes($BATCH_SAMPLES_PATH)->get_nodelist())
            ->reduce( sub {
                my $node = $b;

                my $sample_id      = _extract_value($node, qq{./\@limsid},  'samples');

                # my @sample_ids          = $node->find( qq{./\@limsid}          )->get_nodelist();
                # if (scalar @sample_ids != 1) {
                #   croak qq{The number of 'samples' tag is not correct.};
                # }
                # my $sample_id =$sample_ids[0]->textContent();


                my $conc_max      = _extract_value($node, $CONCENTRATION_MAX_PATH,  'max concentration', $DEFAULT_CONCENTRATION_MAX, );
                my $conc_min      = _extract_value($node, $CONCENTRATION_MIN_PATH,  'min concentration', $DEFAULT_CONCENTRATION_MIN, );
                my $molarity_max  = _extract_value($node, $MOLARITY_MAX_PATH,       'max molarity',      $DEFAULT_MOLARITY_MAX,      );
                my $molarity_min  = _extract_value($node, $MOLARITY_MIN_PATH,       'min molarity',      $DEFAULT_MOLARITY_MIN,      );
                my $size_max      = _extract_value($node, $SIZE_MAX_PATH,           'max lib size',        $DEFAULT_SIZE_MAX,          );
                my $size_min      = _extract_value($node, $SIZE_MIN_PATH,           'min lib size',        $DEFAULT_SIZE_MAX,          );

                my $artifact_id = c->new(keys %{$self->_map_artid_sampleid})->first(sub{
                  return $self->_map_artid_sampleid->{$_} eq $sample_id;
                });
                $a->{ $artifact_id } = {
                              'conc_max' => $conc_max,
                              'conc_min' => $conc_min,
                              'size_max' => $size_max,
                              'size_min' => $size_min,
                              'molarity_max' => $molarity_max,
                              'molarity_min' => $molarity_min,
                            };
                return $a;
              }, {} );
}

sub _build__map_artid_location {
  my $self = shift;

  return c->new($self->_output_container_details->findnodes($BATCH_CONTAINER_PLACEMENT_PATH)->get_nodelist())
            ->reduce( sub {
                my $node = $b;
                my @locations    = $node->find( qq{./value/text()}   )->get_nodelist();
                my @artifact_ids = $node->find( qq{./\@limsid} )->get_nodelist();

                if (scalar @locations != 1) {
                  croak qq{The number of 'locations' tag is not correct.};
                }
                if (scalar @artifact_ids != 1) {
                  croak qq{The number of 'artifact_ids' tag is not correct.};
                }

                my $well =$locations[0]->textContent();
                $well =~ s/://xms;
                $a->{ $artifact_ids[0]->textContent() } = $well;
                return $a;
              }, {} );
}

sub _build__mapping_details{
  my $self = shift;

  my @filenames = $self->_get_filenames_available_for_parsing();
  my $validation = wtsi_clarity::isc::agilent::file_validator->new(file_names => \@filenames);
  return $validation->files_by_well();
}

sub _build__files_content {
  my $self = shift;
  my $parser = XML::LibXML->new();

  my $files_content = c->new(keys %{$self->_mapping_details})
               ->map(sub{
                  return $self->_mapping_details->{$_}{'file_path'};
                })
               ->uniq()
               ->reduce(sub{
                  my $file = $b;
                  my $content = $parser->load_xml(location => $file)
                    or croak 'File can not be found at ' . $file;
                  $a->{$file} = $content;
                  return $a;
                }, {});
  return $files_content;
}

sub _build__analysis_results {
  my $self = shift;
  my $analyser = wtsi_clarity::isc::agilent::analyser->new( mapping_details => $self->_mapping_details,
                                                            files_content   => $self->_files_content   );
  return $analyser->get_analysis_results();
}

# main methods

sub _get_filenames_available_for_parsing {
  my $self = shift;
  my $dir = $self->config->robot_file_dir->{'isc_cap_lib_qc'};
  my $source_barcode = $self->_source_barcode;
  my $pattern = qq{$dir/$source_barcode*.*};
  my @files = glob $pattern;
  if ( scalar @files == 0 ){
    croak qq{Impossible to find any file matching the pattern "$pattern"};
  }
  return @files;
}

sub _check_range {
  my $self = shift;
  my %map_location_artid = reverse %{$self->_map_artid_location};
  my $checked_res = c ->new(keys %{$self->_analysis_results})
                      ->reduce(sub {
                        my $loc = $b;
                        my $results = $self->_analysis_results->{$loc};

                        my $artifact_id = $map_location_artid{$loc};
                        my $range = $self->_map_artid_range->{$artifact_id};
                        my $error = _check_range_for_one_result($loc, $results, $range);
                        if ($error) {
                          $a->{$loc} = $error;
                        }
                        return $a;
                      }, {});

  if ( scalar keys %{$checked_res} != 0) {
    my $error_message = _make_error_report($checked_res);
    croak $error_message;
  }
  return qq{Everything is fine\n};
}

sub _precheck {
  my $self = shift;
  my $nb_of_artifacts = scalar keys %{$self->_map_artid_sampleid};
  my $nb_of_results = scalar keys %{$self->_analysis_results};

  if ($nb_of_results != $nb_of_artifacts) {
    croak qq{The number of results found ($nb_of_results) is not compatible with the number of wells on the input plate ($nb_of_artifacts)!};
  }
  return;
}

sub _check_range_for_one_result {
  my ($location, $results, $range) = @_;

  if (! defined $results->{'concentration'}) {
    croak qq{'concentration' is missing from the analysis results for well $location.};
  }
  if (! defined $results->{'molarity'}) {
    croak qq{'molarity' is missing from the analysis results for well $location.};
  }
  if (! defined $results->{'size'}) {
    croak qq{'lib size' is missing from the analysis results for well $location.};
  }

  if ($results->{'concentration'} < $range->{'conc_min'} || $results->{'concentration'} > $range->{'conc_max'}) {
    return qq{Concentration is out of range for well $location.};
  }
  if ($results->{'molarity'} < $range->{'molarity_min'} || $results->{'molarity'} > $range->{'molarity_max'}) {
    return qq{Molarity is out of range for well $location.};
  }
  if ($results->{'size'} < $range->{'size_min'} || $results->{'size'} > $range->{'size_max'}) {
    return qq{Size is out of range for well $location.};
  }
  return q{};
}

sub _make_error_report {
  my $errors = shift;
  my $joined_keys = join ', ', keys %{$errors};
  return qq{The wells [$joined_keys] are out of range!};
}

sub _update_output_details {
  my $self = shift;
  c ->new(keys %{$self->_map_artid_location})
    ->each(sub{
      my $limsid = $_;
      my $well = $self->_map_artid_location->{$limsid};
      my $values = $self->_analysis_results->{$well};
      if ($values) {
        $self->update_nodes(document => $self->_output_details,
                            xpath    => qq{/art:details/art:artifact[\@limsid='$limsid']},
                            type     => qq{Text},
                            udf_name => $CONCENTRATION_UDF,
                            value    => $values->{'concentration'});
        $self->update_nodes(document => $self->_output_details,
                            xpath    => qq{/art:details/art:artifact[\@limsid='$limsid']},
                            type     => qq{Text},
                            udf_name => $MOLARITY_UDF,
                            value    => $values->{'molarity'});
        $self->update_nodes(document => $self->_output_details,
                            xpath    => qq{/art:details/art:artifact[\@limsid='$limsid']},
                            type     => qq{Text},
                            udf_name => $SIZE_UDF,
                            value    => $values->{'size'});
        }
      });
  return $self->_output_details;
}


# helpers

sub _extract_value {
  my ($node, $xpath, $name, $default) = @_;

  my @values  = $node->find( $xpath )->get_nodelist();
  my $value = $default;

  if (scalar @values > 1) {
    croak qq{The number of <'$name'> tag is not correct.};
  }
  if (scalar @values == 1) {
      return $values[0]->textContent();
  }
  if (!defined $default){
    croak qq{There is no <'$name'> tag in the processed data.};
  }
  return $value;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::agilent_analyser

=head1 SYNOPSIS

  wtsi_clarity::epp:isc::agilent_analyser->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will extract the filepath for a agilent results directory, parse the necessary files inside,
  and update the analytes with analysed values.

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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
