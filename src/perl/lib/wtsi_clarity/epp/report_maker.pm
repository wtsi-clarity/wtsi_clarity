package wtsi_clarity::epp::report_maker;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use URI::Escape;
use List::Compare;
use Try::Tiny;
use wtsi_clarity::util::textfile;
use wtsi_clarity::util::report;

our $VERSION = '0.0';

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_ID_PATH                        => q(/prc:process/@limsid);
Readonly::Scalar my $INPUT_ARTIFACTS_IDS_PATH               => q(/prc:process/input-output-map/input/@limsid);
Readonly::Scalar my $ART_DETAIL_SAMPLE_IDS_PATH             => q{/art:details/art:artifact/sample/@limsid};
Readonly::Scalar my $SMP_DETAIL_ARTIFACTS_IDS_PATH          => q{/smp:details/smp:sample/artifact/@limsid};
Readonly::Scalar my $ARTEFACTS_ARTEFACT_CONTAINTER_IDS_PATH => q{/art:details/art:artifact/location/container/@limsid};
Readonly::Scalar my $ARTEFACTS_ARTEFACT_IDS_PATH            => q{/art:artifacts/artifact/@limsid};
Readonly::Scalar my $THOUSANDTH                             => 0.001;
Readonly::Scalar my $DILUTION_COMPENSATION_FACTOR           => 50;

Readonly::Scalar my $UDF_VOLUME         => qq{Volume};
Readonly::Scalar my $UDF_CONCENTRATION  => qq{Concentration};
Readonly::Scalar my $PRC_VOLUME         => qq{Volume Check (SM)};
Readonly::Scalar my $PRC_CONCENTRATION  => qq{Picogreen Analysis (SM)};
## use critic

has 'report_file' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::textfile',
  required => 0,
  lazy_build => 1,
);

sub _build_report_file {
  my ($self) = @_;
  my $files = [];
  return wtsi_clarity::util::report->new()->get_file($self->internal_csv_output);
}

has 'internal_csv_output' => (
  is => 'ro',
  isa => 'ArrayRef',
  required => 0,
  lazy_build => 1,
);

override 'run' => sub {
  my $self= shift;
  super();
  _main_method();
  return;
};

sub _main_method{
  my ($self) = @_;
  my $data = $self->internal_csv_output();

  my $missing_data = $self->_get_first_missing_necessary_data();
  if ($missing_data) {
    confess qq{Impossible to produce the report: "$missing_data" could not be found on the genealogy of some samples. Have you run all the necessary steps on the samples? };
  }

  my $process_id  = $self->find_elements_first_value($self->process_doc, $PROCESS_ID_PATH);
  $self->report_file->saveas(q{./}.$process_id);
  return;
}

sub _build_internal_csv_output {
  my ($self) = @_;
  my $report = wtsi_clarity::util::report->new();
  my @content =c->new(@{$self->_sample_ids})
                ->map( sub {
                  my $sample_id = $_;
                  return c->new(@{$report->headers})
                          ->reduce( sub {
                            my $method = $self->_get_nethod_from_header($b);
                            my $value = $self->$method($sample_id);
                            $a->{$b} = $value;
                            $a;
                          }, {});
                })
                ->each();
  return \@content;
}

sub _get_nethod_from_header {
  my ($self,$header) = @_;
  my $name = _get_nethod_name_from_header($header);
  if ($self->can($name)) {
    return $name;
  }
  return q{_get_not_implemented_yet};
}

sub _get_nethod_name_from_header {
  my ($header) = @_;
  $header =~ s/^\s+|\s+$//gxms; # trim
  $header =~ s/\s/_/gxms;       # replace space with underscore
  return q{_get_} . lc $header; # lower case
}

########################################################
# methods implementing the columns of the report
########################################################

## no critic(Subroutines::ProhibitUnusedPrivateSubroutines)

sub _get_status {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Status"]/text()} );
}

sub _get_study {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Study ID"]/text()} );
}

sub _get_supplier {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Supplier"]/text()} );
}

sub _get_sanger_sample_name {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/name/text()} );
}

sub _get_supplier_sample_name {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Supplier Sample Name (SM)"]/text()} );
}

sub _get_well {
  my ($self, $sample_id) = @_;
  return $self->_location_of_samples->{$sample_id}->{'well'};
}

sub _get_plate {
  my ($self, $sample_id) = @_;
  return $self->_location_of_samples->{$sample_id}->{'plate'};
}

sub _get_supplier_volume {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Supplier Volume"]/text()} );
}

sub _get_supplier_gender {
  my ($self, $sample_id) = @_;
  return $self->_extract_from_sample_directly( qq{/smp:details/smp:sample[\@limsid='$sample_id']/udf:field[\@name="WTSI Supplier Gender - (SM)"]/text()} );
}

sub _get_concentration {
  my ($self, $sample_id) = @_;

  return $self->_get_value_from_data($UDF_CONCENTRATION, $sample_id) * $DILUTION_COMPENSATION_FACTOR;
}

sub _get_measured_volume {
  my ($self, $sample_id) = @_;
  return $self->_get_value_from_data($UDF_VOLUME, $sample_id) ;
}

sub _get_total_micrograms {
  my ($self, $sample_id) = @_;
  return $self->_get_concentration($sample_id) * $self->_get_measured_volume($sample_id) * $THOUSANDTH ;
}

sub _get_genotyping_status {
  my ($self, $sample_id) = @_;
  return q{};
}

sub _get_genotyping_chip {
  my ($self, $sample_id) = @_;
  return q{};
}

sub _get_genotyping_infinium_barcode {
  my ($self, $sample_id) = @_;
  return q{};
}

sub _get_genotyping_barcode {
  my ($self, $sample_id) = @_;
  return q{};
}

sub _get_genotyping_well_cohort {
  my ($self, $sample_id) = @_;
  return q{};
}

sub _get_not_implemented_yet {
  my ($self, $sample_id) = @_;
  return qq{*} ; #qq{Not implemented yet};
}

## use critic

sub _extract_from_sample_directly {
  my ($self, $xpath) = @_;
  return $self->find_elements_first_value($self->_sample_details, $xpath, qq{[Value not present]});
}

sub _get_value_from_data {
  my ($self, $udf_name, $sample_id) = @_;
  my $data = $self->_all_udf_values->{$sample_id};
  if (!defined $data) {
    return qq{[Sample id not present ($sample_id)]} ;
  }
  if (!defined $data->{$udf_name}) {
    return qq{[UDF not present ($udf_name)]} ;
  }
  return $data->{$udf_name} ;
}

########################################################
# end of methods implementing the columns of the report
########################################################

has '_input_artifacts_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifacts_ids {
  my ($self) = @_;
  return $self->grab_values($self->process_doc, $INPUT_ARTIFACTS_IDS_PATH);
}

has '_input_artifacts_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifacts_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris = c->new(@{$self->_input_artifacts_ids})
              ->map( sub {
                  return $base_url.'/artifacts/'.$_;
                } )
              ->each;
  return $self->request->batch_retrieve('artifacts', \@uris );
};

has '_sample_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__sample_ids {
  my ($self) = @_;
  return $self->grab_values($self->_input_artifacts_details, $ART_DETAIL_SAMPLE_IDS_PATH);
}

has '_sample_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__sample_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris = c->new(@{$self->_sample_ids})
              ->map( sub {
                  return $base_url.'/samples/'.$_;
                } )
              ->each;

  return $self->request->batch_retrieve('samples', \@uris );
};

has '_required_sources' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  default => sub {
      return {
        q{concentration} => {
          src_process => $PRC_CONCENTRATION,
          src_udf_name=> $UDF_CONCENTRATION,
        },
        q{cherry_volume} => {
          src_process => $PRC_VOLUME,
          src_udf_name=> $UDF_VOLUME,
        },
      };
    },
);

has '_extra_sources' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  default => sub {
      return { };
    },
);

has '_all_udf_values' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _get_first_missing_necessary_data {
  my($self) = @_;
  my $c_udfs = c->new( keys $self->_required_sources )
                ->map( sub { $self->_required_sources->{$_}->{'src_udf_name'}; });

  my $notfound = $c_udfs->first(sub {
                    my $udf_name = $_;
                    return c->new( @{$self->_sample_ids} )
                            ->first(sub {
                                my $sample_id = $_;
                                return !defined $self->_all_udf_values->{$sample_id}->{$udf_name};
                            });
                  });
  return $notfound;
}

sub _build__all_udf_values {
  my ($self) = @_;

  my %src_data = (%{$self->_extra_sources}, %{$self->_required_sources});

  while (my ($param_name, $parameter) = each %src_data ) {
    $parameter->{'results'} = $self->_get_udf_values($parameter->{'src_process'}, $parameter->{'src_udf_name'});
  };

  my $data = {};

  while (my ($param_name, $parameter) = each %src_data ) {
    my @sample_ids = sort keys $parameter->{'results'};
    my $name = $parameter->{'src_udf_name'};
    foreach my $sample_id (@sample_ids) {
      $data->{$sample_id}->{$name} = $parameter->{'results'}->{$sample_id}->{$name};
    }
  }

  return $data;
}

sub _get_artifact_ids_with_udf {
  my ($self, $step, $udf_name) = @_;

  my $res_arts_doc = $self->request->query_artifacts({
    udf       => qq{udf.$udf_name.min=0},
    type      => qq{Analyte},
    step      => $step,
    sample_id => $self->_sample_ids(),
    });

  return $self->grab_values($res_arts_doc, $ARTEFACTS_ARTEFACT_IDS_PATH);
};

sub _get_udf_values {
  # NB: This method assumes that there is only one id corresponding to one udf
  # i.e. that the sample has only been run once through the step producing this udf.
  my ($self, $step, $udf_name, $sample_id) = @_;
  my $artifacts_ids = $self->_get_artifact_ids_with_udf($step, $udf_name, $sample_id);
  my $artifacts = $self->request->batch_retrieve('artifacts', $artifacts_ids);
  my @nodes;
  try {
    @nodes = $artifacts->findnodes(q{/art:details/art:artifact})->get_nodelist();
  } catch {
    @nodes = ();
  };

  use Encode qw/encode decode/;

  my $res = c->new(@nodes)
              ->reduce( sub {
                ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
                my $found_sample_id      = $b->findvalue( q{./sample/@limsid}                 );
                my $udf_value            = $b->findvalue( qq{./udf:field[\@name="$udf_name"]} );
                ## use critic
                if (defined $a->{$found_sample_id} && defined $a->{$found_sample_id}->{$udf_name}) {
                  confess qq{The sample $found_sample_id possesses more than one value associated with "$udf_name". It is not currently possible to deal with it.};
                }

                $a->{ $found_sample_id } = { $udf_name => $udf_value };
                $a; } , {});
  return $res;
}

has '_original_artifact_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__original_artifact_ids {
  my $self = shift;
  return $self->grab_values($self->_sample_details, $SMP_DETAIL_ARTIFACTS_IDS_PATH);
}

has '_original_artifact_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__original_artifact_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris =  c->new(@{$self->_original_artifact_ids})
              ->map( sub { return $base_url . '/samples/' . $_; } )
              ->each();

  return $self->request->batch_retrieve('artifacts', \@uris );
};

has '_original_container_ids' => (
  isa => 'ArrayRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__original_container_ids {
  my $self = shift;
  return $self->grab_values($self->_original_artifact_details, $ARTEFACTS_ARTEFACT_CONTAINTER_IDS_PATH);
}

has '_original_container_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__original_container_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'};

  my @uris =  c->new(@{$self->_original_container_ids})
              ->uniq()
              ->map( sub { $base_url . '/containers/' . $_; } )
              ->each();
  return $self->request->batch_retrieve('containers', \@uris );
};

has '_original_container_map' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__original_container_map {
  my $self = shift;
  return  c->new(@{$self->_original_container_ids})
            ->reduce( sub {
                  my $container_id = $b;
                  $a->{$container_id} = $self->find_elements_first_value($self->_build__original_container_details,
                                            qq{/con:details/con:container[\@limsid='$container_id']/name/text()}, qq{[Value not present]});
                  $a;
                }, {});
};

has '_location_of_samples' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__location_of_samples {
  my $self = shift;
  return c->new(@{$self->_sample_ids})
            ->reduce( sub {
                  my $sample_id = $b;
                  my $container_id = $self->find_elements_first_value($self->_original_artifact_details,
                                            qq{/art:details/art:artifact/sample[\@limsid='$sample_id']/../location/container/\@limsid}, qq{[Value not present]});
                  $a->{$sample_id}->{'plate'} = $self->_original_container_map->{$container_id};
                  $a->{$sample_id}->{'well'} = $self->find_elements_first_value($self->_original_artifact_details, qq{/art:details/art:artifact/sample[\@limsid='$sample_id']/../location/value/text()}, qq{[Value not present]});
                  $a;
                }, {});
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::report_maker

=head1 SYNOPSIS

  wtsi_clarity::epp::report_maker->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a QC report, and upload it on the server, as an output for the step.
  Activate the stock plate corresponding to the sample that went through the QC process.

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item Mojo::Collection

=item Data::Dumper

=item URI::Escape

=item List::Compare

=item Try::Tiny

=item wtsi_clarity::util::textfile

=item wtsi_clarity::util::report

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
