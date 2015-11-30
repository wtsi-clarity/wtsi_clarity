package wtsi_clarity::epp::reports::report;

use Moose;
use Carp;
use Readonly;
use List::Util qw/first/;
use File::Temp qw/ tempdir /;

use wtsi_clarity::util::csv::factory;
use wtsi_clarity::irods::irods_publisher;

with 'wtsi_clarity::util::roles::database';

our $VERSION = '0.0';

Readonly::Scalar my $TWELVE => 12;

extends 'wtsi_clarity::epp';

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

sub headers {
  croak 'Method headers must be overidden';
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

sub irods_destination_path {
  croak 'Method irods_destination_path must be overidden';
}

sub now {
  return DateTime->now()->strftime('%Y%m%d%H%M%S');
}

# Cheeky template method...
sub _create_reports {
  my $self = shift;

  my $iterator = $self->elements();

  while (my $model = $iterator->()) {
    my $file_content = $self->file_content($model);

    # TODO: this should also take out from the base template
    # as not always needed it
    $file_content = $self->_sort_file_content($file_content, $self->sort_order, $self->sort_by_column);

    my $file = $self->_file_factory->create(
      type      => 'report_writer',
      headers   => $self->headers,
      data      => $file_content,
      delimiter => $self->file_delimiter,
    );

    my $filename = $self->file_name($model);

    if ($self->_has_publish_to_irods && $self->publish_to_irods) {
      my $dir = tempdir(CLEANUP => 1);
      my $file_path = $file->saveas(join q{/}, $dir, $filename);

      $self->_publish_report_to_irods($file_path);
      my $hash = $self->md5_hash;

      if ($hash) {
        $self->insert_hash_to_database($filename, $hash, $self->irods_destination_path())
      }
    } else {
      $file->saveas($filename);
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

  my $destination_base_path = $self->irods_destination_path;

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

__END__

=head1 NAME

wtsi_clarity::epp::reports::report

=head1 SYNOPSIS

base report class for irods related reports

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 BUILD

=head2 run - Builds the report

=head2 headers

  Returns the headers of the report file.

=head2 file_content

  An abstract method, what the child class should be override.
  Generating the content of the report file.

=head2 file_delimiter

  Returning the delimiter between the fields in the file.

=head2 sort_order

  Ordering the rows in the file.

=head2 now

  Returning the current date/time stamp in string format.

=head2 sort_by_column

  An abstract method, what the child class should be override.
  Define the sorting criteria by column name.

=head2 irods_destination_path

  An abstract method, what the child class should be override.
  Returns the file's destination path on iRODS.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readnly

=item Carp

=item List::Util

=item wtsi_clarity::util::csv::factory

=item wtsi_clarity::epp

=item wtsi_clarity::irods::irods_publisher

=item wtsi_clarity::util::roles::database

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