package wtsi_clarity::epp::sm::reactivate_stock_plate;

use Moose;
use Carp;
use Readonly;

use wtsi_clarity::epp::sm::assign_to_workflow;

extends 'wtsi_clarity::epp';

with 'wtsi_clarity::util::clarity_process';

our $VERSION = '0.0';

has 'from_process' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

has 'to_workflow' => (
  isa => 'Str',
  is  => 'ro',
  required => 1,
);

override 'run' => sub {
  my $self= shift;
  super();

  # Get all input artifacts' parent process URIs
  my $parent_processes = $self->find_parent($self->from_process, $self->process_url);

  if (scalar @{ $parent_processes } == 0) {
    croak 'None of the samples in these plates seem to have gone through Working Dilution (SM)';
  }

  foreach my $parent_process_url (@{ $parent_processes }) {
    wtsi_clarity::epp::sm::assign_to_workflow->new(
      new_wf => $self->to_workflow,
      process_url => $parent_process_url,
    )->run();
  }
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::reactivate_stock_plate

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::reactivate_stock_plate->new(
    process_url => 'http://my.com/processes/3345'
  )->run();

=head1 DESCRIPTION

  Will search for the Working Dilution of the inputs in the process XML, and then assign
  them to Sequencing workflow (Cherrypick Submission is the first step)

=head1 SUBROUTINES/METHODS

=head2 run - executes the callback

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

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