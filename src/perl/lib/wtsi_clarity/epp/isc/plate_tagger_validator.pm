package wtsi_clarity::epp::isc::plate_tagger_validator;

use Moose;
use Carp;
use Readonly;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $ARTIFACTS_PATH     => q{/art:details/art:artifact};
Readonly::Scalar my $REAGENT_LABEL_PATH => q{reagent-label/@name};
## use critic

override 'run' => sub {
  my $self= shift;

  super();

  $self->_validate();

  return;
};

sub _validate {
  my ($self) = @_;

  my @analytes = $self->process_doc->output_analytes->findnodes($ARTIFACTS_PATH)->get_nodelist();

  my @analytes_with_tag =
    map { $_->findvalue($REAGENT_LABEL_PATH) ne q{} ? 1 : () } @analytes;

  my $analytes_with_tag_count = scalar @analytes_with_tag;

  if ($analytes_with_tag_count < 1 || $analytes_with_tag_count != scalar @analytes) {
    croak qq{None of not all of the analytes contains the 'reagent-label' tag.\nMight be the tags has not been added to the analytes, yet.};
  }

  return 1;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::plate_tagger_validator

=head1 SYNOPSIS

  my $plate_tagger_validator = wtsi_clarity::epp::isc::file_download->new(er
    process_url   => 'http://clarity.com/processes/1234',
  );

=head1 DESCRIPTION

  Validates if the tags has been added to all of the output analytes.

=head1 SUBROUTINES/METHODS


=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

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