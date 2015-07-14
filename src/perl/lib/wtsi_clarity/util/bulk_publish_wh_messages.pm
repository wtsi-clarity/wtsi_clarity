package wtsi_clarity::util::bulk_publish_wh_messages;

use Moose;
use Carp;
use Readonly;
use XML::LibXML;

use feature qw/switch/;

use wtsi_clarity::clarity::process;
use wtsi_clarity::epp::generic::messenger;

with qw/MooseX::Getopt
        wtsi_clarity::util::configurable
        wtsi_clarity::util::roles::clarity_request/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $PROCESS_URI_PATH      => q{/prc:processes/process/@uri};
## use critic

Readonly::Scalar my $PROCESS_TYPE_SAMPLE_RECEIPT      => q{Sample Receipt (SM)};
Readonly::Scalar my $PROCESS_TYPE_STUDY_RECEIPT       => q{Sample Receipt (SM)};
Readonly::Scalar my $PROCESS_TYPE_FLUIDIGM_ANALYSIS   => q{Fluidigm 96.96 IFC Analysis (SM)};
Readonly::Scalar my $PROCESS_TYPE_FLOWCELL_GENERATION => q{Cluster Generation};

has 'model'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'process_url' => (
  isa             => 'Str',
  is              => 'ro',
  required        => 0,
);

has 'project_name'  => (
  isa               => 'Str',
  is                => 'ro',
  required          => 0,
);

has '_process_type' => (
  isa         => 'Str',
  is          => 'ro',
  required    => 0,
  lazy_build  => 1,
);
sub _build__process_type {
  my $self = shift;

  my $process_type;

  given($self->model) {
    when (/sample/sm)   { $process_type = $PROCESS_TYPE_SAMPLE_RECEIPT }
    when (/study/sm)    { $process_type = $PROCESS_TYPE_STUDY_RECEIPT }
    when (/fluidigm/sm) { $process_type = $PROCESS_TYPE_FLUIDIGM_ANALYSIS }
    when (/flowcell/sm) { $process_type = $PROCESS_TYPE_FLOWCELL_GENERATION }
    default           { croak q{Not supported process type} }
  }

  return q{type=} . $process_type;
}

sub _process_urls_by_project_name {
  my ($self) = @_;

  my $process_urls_by_project_name_uri = join q{&}, $self->config->clarity_api->{'base_uri'} . q{/} . q{processes?} . $self->_process_type,
                                                    q{projectname=} . $self->project_name;
  my $process_urls_xml = $self->fetch_and_parse($process_urls_by_project_name_uri);
  my @process_urls = $process_urls_xml->findnodes($PROCESS_URI_PATH)->to_literal_list();

  return \@process_urls;
}

sub _publish_messages_to_wh {
  my ($self, $process_url) = @_;

  my $step_url = $process_url;
  $step_url =~ s/processes/steps/smxg;

  my $messanger  = wtsi_clarity::epp::generic::messenger->new(
    process_url => $process_url,
    step_url    => $step_url,
    purpose     => [$self->model]
  );

  $messanger->run();

  return;
}

sub run {
  my $self = shift;

  if (defined $self->process_url and length $self->process_url) {
    $self->_publish_messages_to_wh($self->process_url);
  } else {
    foreach my $process_url (@{$self->_process_urls_by_project_name}) {
      $self->_publish_messages_to_wh($process_url);
    }
  }

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::bulk_publish_wh_messages

=head1 SYNOPSIS

=head1 USAGE

  Publish the given model messages to the warehouse from just the given process (process_url):

  my $wh_publisher = wtsi_clarity::util::bulk_publish_wh_messages->new(
    process_url => $base_uri . '/processes/122-21977',
    model       => 'sample'
  )->run();

  Publish the given model messages to the warehouse from a given project:

  my $wh_publisher = wtsi_clarity::util::bulk_publish_wh_messages->new(
    project_name  => 'Test Project',
    model         => 'sample'
  )->run();

=head1 REQUIRED ARGUMENTS

  process_url
    The URL of the process
  model (mandatory)
    The name of the model, the data to be republish belongs to
  project_name
    The name of the project

=head1 OPTIONS

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 DESCRIPTION

  This script can republish warehouse messages.

=head2 run

  Execute the publishing of warehouse messages.

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item FindBin

=item lib 

=item Moose

=item Carp

=item Readonly


=item wtsi_clarity::clarity::process;

=item wtsi_clarity::util::configurable

=item wtsi_clarity::util::roles::clarity_request

=item wtsi_clarity::util::clarity_elements

=item wtsi_clarity::epp::generic::messenger

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
