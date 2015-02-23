package wtsi_clarity::epp::sm::proceed_sample_updater;

use Moose;
use Carp;
use Readonly;

use Data::Dumper;

use wtsi_clarity::util::textfile;
use wtsi_clarity::util::csv::factories::generic_csv_reader;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $CONTAINER_URI_PATH => q(/con:containers/container/@uri);
Readonly::Scalar my $PLACEMENT_URIS_PATH => q(/con:container/placement[value="%s"]/@uri);
Readonly::Scalar my $SAMPLE_URIS_PATH => q(/art:details/art:artifact/sample/@uri);
## use critic

Readonly::Scalar my $SAMPLE_NODE_PATH => q(/smp:details/smp:sample);
Readonly::Scalar my $UDF_WTSI_PROCEED_TO_SEQUENCING_NAME => q(WTSI Proceed To Sequencing?);
Readonly::Scalar my $PROCEED_TO_SEQUENCING_VALUE => q(Yes);

has 'qc_file_name' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has '_file_path' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__file_path {
  my $self = shift;
  my $path = join q{/}, $self->config->robot_file_dir->{'proceed'}, $self->qc_file_name;
  my $ext  = '.csv';
  return $path . $ext;
}

override 'run' => sub {
  my $self= shift;
  super();

  my $wells_to_proceed = $self->_plate_and_wells_to_proceed();
  my $placement_uris = $self->_placements_to_mark_proceed($wells_to_proceed);
  my $sample_uris = $self->_sample_uris_to_mark_proceed($placement_uris);
  $self->_update_samples_to_proceed($sample_uris);

  return;
};

sub _update_samples_to_proceed {
  my ($self, $sample_uris) = @_;

  my $samples_xml = $self->request->batch_retrieve('samples', $sample_uris);

  $self->update_nodes(document => $samples_xml,
                      xpath    => $SAMPLE_NODE_PATH,
                      type     => qq{Text},
                      udf_name => $UDF_WTSI_PROCEED_TO_SEQUENCING_NAME,
                      value    => $PROCEED_TO_SEQUENCING_VALUE);

  $self->request->batch_update('samples', $samples_xml);

  return;
}

sub _sample_uris_to_mark_proceed {
  my ($self, $artifact_uris) = @_;

  my $sample_artifacts = $self->request->batch_retrieve('artifacts', $artifact_uris);

  my $samples_uris = $self->grab_values($sample_artifacts, $SAMPLE_URIS_PATH);

  return $samples_uris;
}

sub _placements_to_mark_proceed {
  my ($self, $wells_to_proceed) = @_;

  my $placements_uris = ();

  while ( my ($container_name, $wells) = each %{$wells_to_proceed} )
  {
    my $container_result = $self->request->query_resources(
                              q{containers},
                              {
                                name => $container_name
                              }
    );
    my $container_uri = pop $self->grab_values($container_result, $CONTAINER_URI_PATH);

    my $container_xml = $self->fetch_and_parse($container_uri);

    foreach my $well (@{$wells}) {
      my $xpath = sprintf $PLACEMENT_URIS_PATH, $well;
      my @sorted_ids = sort @{$self->grab_values($container_xml, $xpath)};
      push @{$placements_uris}, $sorted_ids[0];
    }
  }

  return $placements_uris;
}

sub _plate_and_wells_to_proceed {
  my $self = shift;

  my $wells_to_proceed = ();
  foreach my $row (@{$self->_read_qc_file}) {
    if (uc($row->{'Proceed'}) =~ /Y|YES/sxm) {
      $wells_to_proceed->{$row->{'Plate'}} ||= [];
      push @{$wells_to_proceed->{$row->{'Plate'}}}, $row->{'Well'};
    }
  }

  return $wells_to_proceed;
}

sub _read_qc_file {
  my $self = shift;

  my $file = wtsi_clarity::util::textfile->new();
  $file->read_content($self->_file_path);

  my $reader = wtsi_clarity::util::csv::factories::generic_csv_reader->new();

  my $content = $reader->build(
    file_content => $file->content,
  );

  return $content;
}



1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::proceed_sample_updater

=head1 SYNOPSIS

  my $gk = wtsi_clarity::epp::sm::proceed_sample_updater->new(process_url => '');

=head1 DESCRIPTION

  Cherry pick a plate from the QC report list (coming back from from customer)
  to task work to sequencing (Cherry pick to Shear step).
  Parse the 'Proceed' column of the provided QC report and update the sample's related UDF field,
  which are marked to proceed, them stamping those samples to a new plate
  and put the original one to a freezer.

=head1 SUBROUTINES/METHODS


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item JSON

=item Readonly

=item wtsi_clarity::util::request

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

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