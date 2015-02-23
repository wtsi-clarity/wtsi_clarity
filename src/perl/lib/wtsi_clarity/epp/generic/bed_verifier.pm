package wtsi_clarity::epp::generic::bed_verifier;

use Moose;
use Carp;
use Readonly;
use File::Spec::Functions;
use File::Slurp;
use English qw( -no_match_vars );
use JSON;
use Try::Tiny;

use wtsi_clarity::util::config;
use wtsi_clarity::process_checks::bed_verifier;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $EVERYTHING => q[ /prc:process/udf:field[contains(@name, "Input Plate") or contains(@name, "Output Plate")] ];
## use critic

Readonly::Scalar my $BED_VERIFICATION_CONFIG => q[bed_verification.json];

with 'wtsi_clarity::util::clarity_elements';
extends 'wtsi_clarity::epp';

# Required parameters
has 'step_name' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

# Optional parameters
has 'outputs' => (
  isa      => 'Bool',
  is       => 'ro',
  required => 0,
  default  => 1
);

# Main method
override 'run' => sub {
  my $self = shift;
  super();

  try {
    $self->_bed_verifier->verify($self);
  } catch {
    my $error = $_;
    $self->_punish_user_by_resetting_everything();
    croak "Bed verification has failed: $error";
  };

  return;
};

sub _punish_user_by_resetting_everything {
  my $self = shift;
  my $everything = $self->findnodes($EVERYTHING);

  map { $self->update_text($_, q{}); } $everything->get_nodelist();

  return $self->request->put($self->process_url, $self->process_doc->toString);
}

has '_bed_verifier' => (
  is => 'ro',
  isa => 'wtsi_clarity::process_checks::bed_verifier',
  lazy_build => 1,
);

sub _build__bed_verifier {
  my $self = shift;
  return wtsi_clarity::process_checks::bed_verifier->new(config => $self->_bed_config_file);
}

has '_bed_config_file' => (
  isa        => 'HashRef',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__bed_config_file {
  my $self = shift;
  my $file_path = catfile($self->config->dir_path, $BED_VERIFICATION_CONFIG);
  open my $fh, '<:encoding(UTF-8)', $file_path
    or croak qq[Could not retrive the configuration file at $file_path\n];
  local $RS = undef;
  my $json_text = <$fh>;
  close $fh
    or croak qq[Could not close handle to $file_path\n];
  return decode_json($json_text);
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::generic::bed_verifier

=head1 SYNOPSIS

  wtsi_clarity::epp:generic::bed_verifier->new(
    process_url => 'http://my.com/processes/3345',
    step_name   => 'working_dilution',
  )->run();

=head1 DESCRIPTION

  Checks that plates have been placed in the correct beds for various processes

=head1 SUBROUTINES/METHODS

=head2 run - callback for the bed_verifier action

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item File::Spec::Functions

=item File::Slurp

=item English qw( -no_match_vars )

=item JSON

=item Try::Tiny

=item wtsi_clarity::util::config

=item wtsi_clarity::process_checks::bed_verifier

=item wtsi_clarity::util::roles::clarity_process_io

=back

=head1 AUTHOR

Chris Smith E<lt>cs24@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Chris Smith

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
