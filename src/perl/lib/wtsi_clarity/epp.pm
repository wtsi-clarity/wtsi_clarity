package wtsi_clarity::epp;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

use wtsi_clarity::util::request;
use wtsi_clarity::util::types;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $BED_PATH => q{/prc:process/udf:field[starts-with(@name, "Bed") and contains(@name, "Plate")]};
Readonly::Scalar my $PLATE_PATH => q{/prc:process/udf:field[starts-with(@name, "Input Plate") or starts-with(@name, "Output Plate")]};
## use critic

with qw/MooseX::Getopt wtsi_clarity::util::configurable wtsi_clarity::util::roles::clarity_request/;

our $VERSION = '0.0';

has 'process_url'  => (
  isa             => 'Str',
  is              => 'ro',
  required        => 1,
);

has 'process_doc'  => (
  isa             => 'XML::LibXML::Document',
  is              => 'ro',
  required        => 0,
  traits          => [ 'NoGetopt' ],
  lazy_build      => 1,
  handles         => {'findnodes' => 'findnodes'},
);

sub _build_process_doc {
  my ($self) = @_;
  return $self->fetch_and_parse($self->process_url);
}

has 'beds' => (
  is => 'ro',
  isa => 'WtsiClarityProcessBeds',
  lazy_build => 1,
  coerce => 1,
  traits => [ 'NoGetopt' ],
);

sub _build_beds {
  my $self = shift;
  return $self->findnodes($BED_PATH);
}

has 'plates' => (
  is => 'ro',
  isa => 'WtsiClarityPlates',
  lazy_build => 1,
  coerce => 1,
  traits => [ 'NoGetopt' ],
);

sub _build_plates {
  my $self = shift;
  return $self->findnodes($PLATE_PATH);
}

sub run {
  my $self = shift;
  $self->epp_log('Run method is called for ' . $self->toString());
  return;
}

sub epp_log {
  my ($self, $message) = @_;
  warn "$message\n";
  return;
}

sub toString {
  my $self = shift;
  return sprintf 'class %s, process %s', ref $self, $self->process_url;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp

=head1 SYNOPSIS

  package wtsi_clarity::epp::child;
  use Moose;
  extends 'wtsi_clarity::epp';

  override 'run' => sub {
    my $self = shift;
    super(); #call parent's run method
    # the child's callback goes here
  };
  1;

=head1 DESCRIPTION

 Parent class for all Clarity callbacks

=head1 SUBROUTINES/METHODS

=head2 process_url - required attribute

=head2 run - executes the callback, should be implemented by child classes

=head2 epp_log - simple logging procedure

=head2 config

  A reference to wtsi_clarity::util::config object,
  access to configuration options for the package.

=head2 request

   A reference to wtsi_clarity::util::request object,
   which should be used to raise http requests

=head2 xml_parser - XML parser instance

=head2 process_doc - XML dom representation of process xml

=head2 fetch_and_parse - given url, fetches XML document and returns its XML dom representation

  my $dom = $self->fetch_and_parse($url);

=head2 toString

  Returns output about this class and the process

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::Getopt

=item Carp

=back

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Marina Gourtovaia

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
