package wtsi_clarity::epp::generic::manifest;

use Moose;
use Readonly;
use Carp;
use List::Util qw/first/;
use List::MoreUtils qw/uniq/;
use wtsi_clarity::util::csv::factory;

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

Readonly::Scalar my $FILE_NAME => q{%s.manifest.txt};
Readonly::Scalar my $TWELVE    => 12;

sub BUILD {
  my $self = shift;

  if (!$self->_has_process_url && !$self->_has_container_id && !$self->_has_message) {
    croak 'Either process_url, container_id, or message must be passed into generic::manifest';
  }

  return $self;
}

override 'run' => sub {
  my $self = shift;
  super();

  my $reports = $self->_create_reports();

  foreach my $container_id (keys %{$reports}) {
    $reports->{$container_id}->saveas(q{./} . $self->_get_file_name($container_id));
  }

  return 1;
};

has '+process_url' => (
  required  => 0,
  predicate => '_has_process_url',
  writer    => 'write_process_url',
);

has '_message' => (
  is        => 'ro',
  isa       => 'wtsi_clarity::mq::message',
  required  => 0,
  trigger   => \&_set_process_url,
  init_arg  => 'message',
  predicate => '_has_message',
);

has 'container_id' => (
  is        => 'ro',
  isa       => 'ArrayRef',
  predicate => '_has_container_id',
  required  => 0,
);

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

sub _create_reports {
  my $self = shift;

  my %files = map { $self->_create_report_hash($_) }
    $self->_containers->findnodes('/con:details/con:container');

  return \%files;
}

sub _create_report_hash {
  my ($self, $container) = @_;
  return { $_->findvalue('@limsid') => $self->_create_file($container) };
}

sub _create_file {
  my ($self, $container) = @_;
  my $data = $self->_file_content($container);

  return wtsi_clarity::util::csv::factory->new()
           ->create(
             type      => 'report_writer',
             headers   => keys $data->[0],
             data      => $self->_file_content($container),
             delimiter => "\t",
           );
}

sub _file_content {
  my ($self, $container) = @_;
  my %file_content = ();

  my $container_lims_id = $container->findvalue('@limsid');

  $file_content{$container_lims_id}{'container_name'} = $container->findvalue('name');
  $file_content{$container_lims_id}{'container_type'} = $container->findvalue('type/@name');
  $file_content{$container_lims_id}{'wells'} = $self->_build_wells($container);

  my @sample_uris = map { $_->{'sample_uri'} } values $file_content{$container_lims_id}{'wells'};
  my $samples = $self->request->batch_retrieve('samples', \@sample_uris);

  $self->_set_projects($samples);

  my @rows = map {
    $self->_build_row($_, \%file_content, $container_lims_id, $samples);
  } keys $file_content{$container_lims_id}{'wells'};

  @rows = sort { $self->_sort_analyte($self->_sort_by(), $a, $b) } @rows;

  return \@rows;
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
  return ( $placement => { 'sample_uri' => $sample->findvalue('./sample/@uri') } );
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
  return ($project->findvalue('/prj:project/@limsid'), $project->findvalue('/prj:project/name') );
}

sub _build_row {
  my ($self, $well, $file_content, $container_lims_id, $samples) = @_;

  my $sample_uri = $file_content->{$container_lims_id}{'wells'}{$well}{'sample_uri'};
  my $sample     = $samples->findnodes("/smp:details/smp:sample[\@uri='$sample_uri']")->pop();

  return {
    'Sample/Well Location'                => $well,
    'Container/Name'                      => $file_content->{$container_lims_id}{'container_name'},
    'Container/Type'                      => $file_content->{$container_lims_id}{'container_type'},
    'Sample/Name'                         => $sample->findvalue('./name') // q{},
    'UDF/WTSI Supplier'                   => $sample->findvalue('./udf:field[@name="WTSI Supplier Sample Name (SM)"]') // q{},
    'UDF/WTSI Supplier Gender - (SM)'     => $sample->findvalue('./udf:field[@name="WTSI Supplier Gender - (SM)"]') // q{},
    'UDF/WTSI Supplier Volume'            => $sample->findvalue('./udf:field[@name="WTSI Supplier Volume"]') // q{},
    'UDF/WTSI Phenotype'                  => $sample->findvalue('./udf:field[@name="WTSI Phenotype"]') // q{},
    'UDF/WTSI Donor ID'                   => $sample->findvalue('./udf:field[@name="WTSI Donor ID"]') // q{},
    'UDF/WTSI Requested Size Range From'  => $sample->findvalue('./udf:field[@name="WTSI Requested Size Range From"]') // q{},
    'UDF/WTSI Requested Size Range To'    => $sample->findvalue('./udf:field[@name="WTSI Requested Size Range To"]') // q{},
    'UDF/WTSI Bait Library Name'          => $sample->findvalue('./udf:field[@name="WTSI Bait Library Name"]') // q{},
    'UDF/WTSI Organism'                   => $sample->findvalue('./udf:field[@name="WTSI Organism"]') // q{},
    'UDF/WTSI Taxon ID'                   => $sample->findvalue('./udf:field[@name="WTSI Taxon ID"]') // q{},
    'Sample UUID'                         => $sample->findvalue('./name') // q{},
    'Project Name'                        => $self->_projects->{$sample->findvalue('./project/@limsid')} // q{},
    'Project ID'                          => $sample->findvalue('./project/@limsid') // q{},
  }
}

sub _set_process_url {
  my $self = shift;
  return $self->write_process_url($self->_message->process_url);
}

sub _build__containers {
  my $self = shift;

  if ($self->_has_process_url) {
    return $self->process_doc->containers;
  } elsif ($self->_has_container_id) {
    my @urls = map { $self->config->clarity_api->{'base_uri'} . '/containers/' . $_ } @{$self->container_id};
    return $self->request->batch_retrieve('containers', \@urls);
  }
}

sub _get_file_name {
  my ($self, $container_id) = @_;
  return sprintf $FILE_NAME, $container_id;
}

sub _sort_by {
  my $self = shift;
  my @wells = ();

  for my $column (1..$TWELVE) {
    for my $row (q{A}..q{H}) {
      push @wells, $row . q{:} . $column;
    }
  }

  return \@wells;
}

sub _sort_analyte {
  my ($self, $sort_by, $analyte_a, $analyte_b) = @_;

  my @sort_by = @{$sort_by};

  my $location_index_a = first { $sort_by[$_] eq $analyte_a->{'Sample/Well Location'} } 0..$#sort_by;
  my $location_index_b = first { $sort_by[$_] eq $analyte_b->{'Sample/Well Location'} } 0..$#sort_by;

  return $location_index_a <=> $location_index_b;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::manifest

=head1 SYNOPSIS

wtsi_clarity::epp::generic::manifest->new( container_id => ['24-123', '24-567'])->run()

# Files 24-123.manifest.txt and 24-567.manifest.txt will appear in the current directory

=head1 DESCRIPTION

 An EPP for creating a "manifest report". The EPP can be supplied with either a process_url, an
 array of container_ids, or a wtsi_clarity::mq::message object (which would come for the report
 queue). The report will be built and currently saved locally with the filename of
 {container_id}.manifest.txt.

=head1 SUBROUTINES/METHODS

=head2 BUILD - checks the object post construction. One of either container_id, process_url, or
message must be supplied

=head2 run - Builds the report

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
