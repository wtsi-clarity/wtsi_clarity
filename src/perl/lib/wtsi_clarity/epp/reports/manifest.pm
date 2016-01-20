package wtsi_clarity::epp::reports::manifest;

use Moose;
use Readonly;
use Carp;
use List::MoreUtils qw/uniq/;
use DateTime;

extends 'wtsi_clarity::epp::reports::report';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

Readonly::Scalar my $FILE_NAME => q{%s.%s.manifest.txt};

has '_containers' => (
    is      => 'ro',
    isa     => 'XML::LibXML::Document',
    lazy    => 1,
    builder => '_build__containers',
  );

has '_projects' => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => sub { {} },
    init_arg => undef,
  );

sub elements {
  my $self = shift;
  my $containers = $self->_containers->findnodes('/con:details/con:container');
  return sub {
    return $containers->pop();
  }
}

sub sort_by_column { return 'Sample/Well Location' }

sub file_name {
  my ($self, $container) = @_;
  return sprintf $FILE_NAME, $container->findvalue('@limsid'), $self->now();
}

sub get_metadatum {
  my ($self) = @_;

  my @metadatum = (
    {
      "attribute" => "type",
      "value"     => "manifest.txt",
    },
    {
      "attribute" => "time",
      "value"     => $self->now(),
    }
  );

  return @metadatum;
}

sub headers {
  return [
    'Sample/Well Location',
    'Container/Name',
    'Container/Type',
    'Sample/Name',
    'UDF/WTSI Supplier',
    'UDF/WTSI Supplier Gender - (SM)',
    'UDF/WTSI Supplier Volume',
    'UDF/WTSI Phenotype',
    'UDF/WTSI Donor ID',
    'UDF/WTSI Requested Size Range From',
    'UDF/WTSI Requested Size Range To',
    'UDF/WTSI Bait Library Name',
    'UDF/WTSI Organism',
    'UDF/WTSI Taxon ID',
    'Sample UUID',
    'Project Name',
    'Project ID',
  ]
}

sub file_content {
  my ($self, $container) = @_;
  my %file_content = ();

  my $container_lims_id = $container->findvalue('@limsid');

  $file_content{$container_lims_id}{'container_name'} = $container->findvalue('name');
  $file_content{$container_lims_id}{'container_type'} = $container->findvalue('type/@name');
  $file_content{$container_lims_id}{'wells'} = $self->_build_wells($container);

  my @sample_uris = sort map { $_->{'sample_uri'} } values $file_content{$container_lims_id}{'wells'};
  my $samples = $self->request->batch_retrieve('samples', \@sample_uris);

  $self->_set_projects($samples);

  my @rows = map {
    $self->_build_row($_, \%file_content, $container_lims_id, $samples);
  } keys $file_content{$container_lims_id}{'wells'};

  return \@rows;
}

sub irods_destination_path {
  my ($self) = @_;

  my @sample_limsids = sort values %{$self->_projects};

  my $destination = $sample_limsids[0]->{'product_destination'};
  return $self->config->irods->{$destination.'_manifest_path'}.q{/};
}

sub _find_project_limsid_by_sample_limsid {
  my ($self, $sample) = @_;

  return $sample->findvalue('./project/@limsid');
}

sub _build__containers {
  my $self = shift;

  if ($self->_has_process_url) {
    return $self->process_doc->containers;
  } elsif ($self->_has_container_id) {
    my @urls = map { $self->config->clarity_api->{'base_uri'}.'/containers/'.$_ } @{$self->container_id};
    return $self->request->batch_retrieve('containers', \@urls);
  }
}

sub _build_wells {
  my ($self, $container) = @_;
  my %wells = ();
  my @artifact_uris = $container->findnodes('placement/@uri')->to_literal_list;
  my $analytes = $self->request->batch_retrieve('artifacts', \@artifact_uris);

  %wells = map { $self->_get_sample_uri($_, $analytes) }
    $container->findnodes('./placement/value')->to_literal_list;

  return \%wells;
}

sub _get_sample_uri {
  my ($self, $placement, $analytes) = @_;
  my $sample = $analytes->findnodes("art:details/art:artifact[location/value='$placement']")->pop;
  return ( $placement => {'sample_uri' => $sample->findvalue('./sample/@uri')} );
}

sub _set_projects {
  my ($self, $samples) = @_;

  my %projects = map { $self->_build_project_hash($_) }
    uniq($samples->findnodes('/smp:details/smp:sample/project/@uri')->to_literal_list);

  $self->_projects(\%projects);

  return 1;
}

sub _build_project_hash {
  my ($self, $project_uri) = @_;
  my $project = $self->fetch_and_parse($project_uri);

  my %project_data;
  $project_data{'product_destination'} = $project->findvalue('/prj:project/udf:field[@name="WTSI Product Destination"]');
  $project_data{'name'} = $project->findvalue('/prj:project/name');

  return ($project->findvalue('/prj:project/@limsid'), \%project_data );
}

sub _build_row {
  my ($self, $well, $file_content, $container_lims_id, $samples) = @_;

  my $sample_uri = $file_content->{$container_lims_id}{'wells'}{$well}{'sample_uri'};
  my $sample = $samples->findnodes("/smp:details/smp:sample[\@uri='$sample_uri']")->pop();

  return {
    'Sample/Well Location'               => $well,
    'Container/Name'                     => $file_content->{$container_lims_id}{'container_name'},
    'Container/Type'                     => $file_content->{$container_lims_id}{'container_type'},
    'Sample/Name'                        => $sample->findvalue('./udf:field[@name="WTSI Supplier Sample Name (SM)"]') // q{},
    'UDF/WTSI Supplier'                  => $sample->findvalue('./udf:field[@name="WTSI Supplier"]') // q{},
    'UDF/WTSI Supplier Gender - (SM)'    => $sample->findvalue('./udf:field[@name="WTSI Supplier Gender - (SM)"]') // q{},
    'UDF/WTSI Supplier Volume'           => $sample->findvalue('./udf:field[@name="WTSI Supplier Volume"]') // q{},
    'UDF/WTSI Phenotype'                 => $sample->findvalue('./udf:field[@name="WTSI Phenotype"]') // q{},
    'UDF/WTSI Donor ID'                  => $sample->findvalue('./udf:field[@name="WTSI Donor ID"]') // q{},
    'UDF/WTSI Requested Size Range From' => $sample->findvalue('./udf:field[@name="WTSI Requested Size Range From"]') // q{},
    'UDF/WTSI Requested Size Range To'   => $sample->findvalue('./udf:field[@name="WTSI Requested Size Range To"]') // q{},
    'UDF/WTSI Bait Library Name'         => $sample->findvalue('./udf:field[@name="WTSI Bait Library Name"]') // q{},
    'UDF/WTSI Organism'                  => $sample->findvalue('./udf:field[@name="WTSI Organism"]') // q{},
    'UDF/WTSI Taxon ID'                  => $sample->findvalue('./udf:field[@name="WTSI Taxon ID"]') // q{},
    'Sample UUID'                        => $sample->findvalue('./name') // q{},
    'Project Name'                       => $self->_projects->{$self->_find_project_limsid_by_sample_limsid($sample)}->{'name'} // q{},
    'Project ID'                         => $sample->findvalue('./project/@limsid') // q{},
  }
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::reports::manifest

=head1 SYNOPSIS

wtsi_clarity::epp::reports::manifest->new( container_id => ['24-123', '24-567'])->run()

# Files 24-123.manifest.txt and 24-567.manifest.txt will appear in the current directory

=head1 DESCRIPTION

 An EPP for creating a "manifest report". The EPP can be supplied with either a process_url, an
 array of container_ids, or a wtsi_clarity::mq::message object (which would come for the report
 queue). The report will be built and currently saved locally with the filename of
 {container_id}.{timestamp}.manifest.txt.

=head1 SUBROUTINES/METHODS

=head2 BUILD - checks the object post construction. One of either container_id, process_url, or
message must be supplied

=head2 run - Builds the report

=head2 elements

  Creating the elements/rows of the report file.

=head2 headers

  Returns the headers of the report file.

=head2 file_content

  Generating the content of the report file.

=head2 file_name

  Generating a file name based on the sample UUID and the current time stamp.
  The file name will be like {container_id}.{timestamp}.manifest.txt.

=head2 get_metadatum

  Returns the metadatum for the file publishing to iRODS.

=head2 sort_by_column

  Define the sorting criteria by column name.

=head2 set_publish_to_irods

  Checks whether the 'WTSI Send data to external iRODS' check box in project the sample relates to is checked or not.
  If it is checked then returns 1, otherwise 0.

=head2 irods_destination_path

  Returns the file's destination path on iRODS.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readnly

=item Carp

=item List::Util

=item List::MoreUtils

=item wtsi_clarity::util::csv::factory

=item wtsi_clarity::epp

=item wtsi_clarity::util::clarity_elements

=back

=head1 AUTHOR

Author: Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

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
