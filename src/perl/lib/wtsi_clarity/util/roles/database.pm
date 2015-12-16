package wtsi_clarity::util::roles::database;

use Moose::Role;
use DBI;

with qw/wtsi_clarity::util::configurable/;

our $VERSION = '0.0';

has 'database' => (
    is        => 'ro',
    lazy      => 1,
    builder   => '_build_database',
    predicate => 'has_database',
  );

sub _build_database {
  my ($self) = @_;

  if($self->config->database->{'use_database'}) {
    my $dsn = $self->config->database->{'dsn'};
    my $user = $self->config->database->{'user'};
    my $password = $self->config->database->{'pass'};
    return DBI->connect($dsn, $user, $password, {
        PrintError       => 0,
        RaiseError       => 1,
        AutoCommit       => 1,
        FetchHashKeyName => 'NAME_lc',
      });
  }
}

sub DEMOLISH() {
  my ($self) = @_;
  super();

  if($self->has_database) {
    $self->database->disconnect();
  }

  return;
}

sub insert_hash_to_database {
  my ($self, $filename, $hash, $location) = @_;

  if($self->database) {
    $self->database->do('INSERT INTO hash (filename, hash, location) VALUES (?, ?, ?)',
      undef,
      $filename, $hash, $location
    );
  }

  return;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::roles::database

=head1 SYNOPSIS

  with 'wtsi_clarity::util::roles::clarity_request';
  $self->insert_hash_to_database('test.txt', 'd8e8fca2dc0f896fd7cb4cb0031ba249', 'irods');

=head1 DESCRIPTION

  A role for accessing the gclp private database.

=head1 SUBROUTINES/METHODS

=head2 insert_hash_to_database

  Insert hash records into the database.

=head2 DEMOLISH

  Called when the role leaves scope.
  Closes the connection to the database.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item DBI

=item wtsi_clarity::util::configurable

=back

=head1 AUTHOR

Ronan Forman E<lt>rf9@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Genome Research Ltd.

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