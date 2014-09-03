package wtsi_clarity::epp::report;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use URI::Escape;
use List::Compare;

our $VERSION = '0.0';

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_ID_PATH          => q(/prc:process/@limsid);
Readonly::Scalar my $INPUT_ARTIFACTS_IDS_PATH => q(/prc:process/input-output-map/input/@limsid);
Readonly::Scalar my $ART_DETAIL_SAMPLE_IDS_PATH => q{/art:details/art:artifact/sample/@limsid};
Readonly::Scalar my $ARTEFACTS_ARTEFACT_IDS_PATH => q{/art:artifacts/artifact/@limsid};
Readonly::Scalar my $THOUSANDTH  => 0.001;
## use critic


override 'run' => sub {
  my $self= shift;
  super();
  _main_method();
  return;
};

sub _main_method{
  my ($self) = @_;
  my $data = $self->_generate_csv_content();
  my $process_id  = $self->find_elements_first_value($self->process_doc, $PROCESS_ID_PATH);
  _saveas($data, q{./}.$process_id);
  return;
}

#######################################################
# WIP : should use a CSV class to deal with this !!
sub _saveas {
  my ($content, $path) = @_;

  open my $fh, '>', $path
    or croak qq{Could not create/open file '$path'.};
  foreach my $line (@{$content})
  {
      ## no critic(InputOutput::RequireCheckedSyscalls)
      print {$fh} qq{$line\n}; # Print each entry in our array to the file
      ## use critic
  }
  close $fh
    or croak qq{ Unable to close $path.};

  return $path;
};

sub _generate_csv_content {
  my ($self) = @_;
  my @headers =("Status",
                "Study",
                "Supplier",
                "Sanger Sample Name",
                "Supplier Sample Name",
                "Plate",
                "Well",
                "Supplier Volume",
                "Supplier Gender",
                "Concentration",
                "Measured Volume",
                "Total micrograms",
                "Sequenome Count",
                "Sequenome Gender",
                "Pico",
                "Gel",
                "Qc Status",
                "QC started date",
                "Pico date",
                "Gel QC date",
                "Seq stamp date",
                "Genotyping Status",
                "Genotyping Chip",
                "Genotyping Infinium Barcode",
                "Genotyping Barcode",
                "Genotyping Well Cohort",
                "Country of Origin",
                "Geographical Region",
                "Ethnicity",
                "DNA Source",
                "Is Resubmitted",
                "Control",);

  my $headers_line = join ', ', @headers;

  my @content =c->new(@{$self->_sample_ids})
                ->map( sub {
                  my $sample_id = $_;
                  return c->new(@headers)
                          ->map( sub {
                            my $method = $self->_get_nethod_from_header($_);
                            return $self->$method($sample_id);
                          })
                          ->join( q{, } );
                })
                ->each();
  unshift @content, $headers_line;

  return \@content;
}
# WIP
#######################################################


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
  my $res  =qq{No idea $sample_id};
  return $res;
}

sub _get_sanger_sample_name {
  my ($self, $sample_id) = @_;
  return $self->find_elements_first_value($self->_sample_details,
            qq{/smp:details/smp:sample[\@limsid='$sample_id']/name/text()});
}

sub _get_concentration {
  my ($self, $sample_id) = @_;
  my $data = $self->_all_udf_values->{$sample_id};
  return $data->{'Concentration'} ;
}

sub _get_measured_volume {
  my ($self, $sample_id) = @_;
  my $data = $self->_all_udf_values->{$sample_id};
  return $data->{'Cherrypick Sample Volume'} ;
}

sub _get_total_micrograms {
  my ($self, $sample_id) = @_;
  my $data = $self->_all_udf_values->{$sample_id};
  return $data->{'Concentration'} * $data->{'Cherrypick Sample Volume'} * $THOUSANDTH ;
}

sub _get_not_implemented_yet {
  my ($self, $sample_id) = @_;
  return qq{Not implemented yet};
}

## use critic

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
  my $node_list = $self->process_doc->findnodes($INPUT_ARTIFACTS_IDS_PATH);
  my @ids = map { $_->getValue() } $node_list->get_nodelist();
  return \@ids;
}

has '_input_artifacts_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__input_artifacts_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'}.q{/};

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
  my @ids =  c->new($self->_input_artifacts_details->findnodes($ART_DETAIL_SAMPLE_IDS_PATH)->get_nodelist())
              ->map( sub { $_->getValue(); } )
              ->each();

  return \@ids;
}

has '_sample_details' => (
  isa => 'XML::LibXML::Document',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__sample_details {
  my $self = shift;
  my $base_url = $self->config->clarity_api->{'base_uri'}.q{/};

  my @uris = c->new(@{$self->_sample_ids})
              ->map( sub {
                  return $base_url.'/samples/'.$_;
                } )
              ->each;

  return $self->request->batch_retrieve('samples', \@uris );
};

has '_all_udf_values' => (
  isa => 'HashRef',
  is  => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build__all_udf_values {
  my ($self) = @_;

  my $src_data = {
    q{concentration} => {
      src_process => q{Picogreen Analysis (SM)},
      src_udf_name=> q{Concentration},
    },
    q{cherry_volume} => {
      src_process => q{Process2001},
      src_udf_name=> q{Cherrypick Sample Volume},
    },
  };

  while (my ($param_name, $parameter) = each %{$src_data} ) {
    $parameter->{'results'} = $self->_get_udf_values($parameter->{'src_process'}, $parameter->{'src_udf_name'});
  };

  my $data = {};

  while (my ($param_name, $parameter) = each %{$src_data} ) {
    my @sample_ids = sort keys $parameter->{'results'};
    my $name = $parameter->{'src_udf_name'};
    foreach my $sample_id (@sample_ids) {
      $data->{$sample_id}->{$name} = $parameter->{'results'}->{$sample_id}->{$name};
    }
  }

  return $data;
}

sub _get_artifact_ids_with_udf
{
  my ($self, $step, $udf_name) = @_;

  my $res_arts_doc = $self->request->query_artifacts({
    udf       => qq{udf.$udf_name.min=0},
    type      => qq{Analyte},
    step      => $step,
    sample_id => $self->_sample_ids(),
    });


  my @res = c->new($res_arts_doc->findnodes($ARTEFACTS_ARTEFACT_IDS_PATH)->get_nodelist())
              ->map( sub {
                  my $el = $_;
                  return $el->getValue();
                } )
              ->each();
  return \@res;
};

sub _get_udf_values {
  # NB: This method assumes that there is only one id corresponding to one udf
  # i.e. that the sample has only been run once through the step producing this udf.
  my ($self, $step, $udf_name, $sample_id) = @_;
  my $artifacts_ids = $self->_get_artifact_ids_with_udf($step, $udf_name, $sample_id);
  my $artifacts = $self->request->batch_retrieve('artifacts', $artifacts_ids);
  my $res = c->new($artifacts->findnodes(q{/art:details/art:artifact})->get_nodelist())
              ->reduce( sub {
                ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
                my $found_sample_id      = $b->findvalue( q{./sample/@limsid}                 );
                my $udf_value            = $b->findvalue( qq{./udf:field[\@name="$udf_name"]} );
                ## use critic
                if (defined $a->{$found_sample_id} && defined $a->{$found_sample_id}->{$udf_name}) {
                  croak qq{The sample $found_sample_id possesses more than one value associated with "$udf_name". It is not currently possible to deal with it.};
                }
                $a->{ $found_sample_id } = { $udf_name => $udf_value };
                $a; } , {});
  return $res;
}


1;

__END__

=head1 NAME

wtsi_clarity::epp::report

=head1 SYNOPSIS

  wtsi_clarity::epp::report->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Creates a csv QC report, and upload it on the server, as an output for the step.
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
