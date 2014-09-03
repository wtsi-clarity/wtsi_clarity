package wtsi_clarity::epp::report;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection 'c';
use Data::Dumper;
use URI::Escape;
use List::Compare;
our $VERSION = '0.0';

extends 'wtsi_clarity::epp';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
# Readonly::Scalar my $OUTPUT_URI_PATH => q(/prc:process/input-output-map/output/@uri);
# Readonly::Scalar my $FILE_URI_PATH => q(/art:details/art:artifact/file:file/@uri);
# Readonly::Scalar my $IS_PUBLISHED_PATH => q(/file:details/file:file/is-published);
## use critic


override 'run' => sub {
  my $self= shift;
  super();

};

sub main{
  my ($self) = @_;
  return $self->_get_all_udf_values();
}

sub _get_all_udf_values {
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
    udf       => q{udf.$udf_name.min=0},
    type      => q{Analyte},
    step      => $step,
    });


  my @res = c->new($res_arts_doc->findnodes(q{/art:artifacts/artifact/@limsid})->get_nodelist())
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
  my ($self, $step, $udf_name) = @_;
  my $artifacts_ids = $self->_get_artifact_ids_with_udf($step, $udf_name);
  my $artifacts = $self->request->batch_retrieve('artifacts', $artifacts_ids);
  my $res = c->new($artifacts->findnodes(q{/art:details/art:artifact})->get_nodelist())
              ->reduce( sub {
                ## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
                my $sample_id      = $b->findvalue( q{./sample/@limsid}                       );
                my $udf_value  = $b->findvalue( qq{./udf:field[\@name="$udf_name"]} );
                ## use critic
                if (defined $a->{$sample_id} && defined $a->{$sample_id}->{$udf_name}) {
                  croak qq{The sample $sample_id possesses more than one value associated with "$udf_name". It is not currently possible to deal with it.};
                }
                $a->{ $sample_id } = { $udf_name => $udf_value };
                $a; } , {});
  return $res;
}


1;

__END__

=head1 NAME

wtsi_clarity::epp::report

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Getopt

=item Getopt::Long

=item Carp

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
