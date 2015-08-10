package wtsi_clarity::epp::reports::report;

use Moose;
use Carp;
use Readonly;
use List::Util qw/first/;

use wtsi_clarity::util::csv::factory;
use wtsi_clarity::irods::irods_publisher;

our $VERSION = '0.0';

Readonly::Scalar my $TWELVE => 12;

extends 'wtsi_clarity::epp';

# sub BUILD {
#   my $self = shift;

#   if (!$self->_has_process_url && !$self->_has_message) {
#     croak 'Either process_url, or message must be passed into generic::manifest';
#   }

#   return $self;
# }

override 'run' => sub {
  my $self = shift;
  super();

  $self->_create_reports();

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
  trigger   => \&_set_attributes,
  init_arg  => 'message',
  predicate => '_has_message',
);

has 'publish_to_irods' => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => '_has_publish_to_irods',
  default   => 0,
  required  => 0,
  writer    => 'write_publish_to_irods',
);

has '_irods_publisher' => (
  is        => 'ro',
  isa       => 'wtsi_clarity::irods::irods_publisher',
  required  => 0,
  lazy      => 1,
  builder   => '_build__irods_publisher',
);

has '_file_factory' => (
  is => 'ro',
  isa => 'wtsi_clarity::util::csv::factory',
  lazy => 1,
  builder => '_build__file_factory',
);

# Methods can
sub file_content {
  croak 'Method file_content must be overidden';
}

sub file_delimiter {
  return "\t";
}

sub sort_order {
  my $self = shift;
  my @wells = ();

  for my $column (1..$TWELVE) {
    for my $row (q{A}..q{H}) {
      push @wells, $row . q{:} . $column;
    }
  }

  return \@wells;
}

sub sort_by_column {
  croak 'Method sort_by_column must be overidden';
}

# Cheeky template method...
sub _create_reports {
  my $self = shift;

  my $iterator = $self->elements();

  while (my $model = $iterator->()) {
    my $file_content = $self->file_content($model);
    my @headers      = keys($file_content->[0]);

    $file_content = $self->_sort_file_content($file_content, $self->sort_order, $self->sort_by_column);

    my $file = $self->_file_factory->create(
      type      => 'report_writer',
      headers   => \@headers,
      data      => $file_content,
      delimiter => $self->file_delimiter,
    );

    if ($self->_has_publish_to_irods && $self->publish_to_irods) {
      my $file_path = $file->save_to_tmp(); # TODO
      $self->_publish_report_to_irods($file_path);
    } else {
      $file->saveas($self->file_name($model));
    }
  }

  return 1;
}

sub _build__file_factory {
  my $self = shift;
  return wtsi_clarity::util::csv::factory->new();
}

sub _build__irods_publisher {
  my ($self) = @_;
  return wtsi_clarity::irods::irods_publisher->new();
}

sub _set_attributes {
  my $self = shift;
  $self->write_process_url($self->_message->process_url);
  $self->write_publish_to_irods($self->_message->publish_to_irods);
  return 1;
}

sub _publish_report_to_irods {
  my ($self, $report_path) = @_;

  my $destination_base_path = $self->config->irods->{'14m_manifest_path'} . q{/};

  my @file_paths = split /\//sxm, $report_path;
  my $report_filename = pop @file_paths;
  $self->_irods_publisher->publish($report_path, $destination_base_path . $report_filename, 1, $self->get_metadatum);

  return 1;
}

sub _sort_file_content {
  my ($self, $file_content, $sort_order, $sort_by_column) = @_;
  my @rows = sort { $self->_comparator($sort_order, $sort_by_column, $a, $b) } @{$file_content};
  return \@rows;
}

sub _comparator {
  my ($self, $sort_order, $sort_by_column, $row_a, $row_b) = @_;

  my @sort_order = @{$sort_order};

  my $location_index_a = first { $sort_order[$_] eq $row_a->{$sort_by_column} } 0..$#sort_order;
  my $location_index_b = first { $sort_order[$_] eq $row_b->{$sort_by_column} } 0..$#sort_order;

  return $location_index_a <=> $location_index_b;
}

1;