package wtsi_clarity::epp::sm::fluidigm_request_volume;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_PATH   => q(/prc:process/input-output-map/output[@output-type='Analyte']/@uri);
Readonly::Scalar my $TARGET_NAME   => q(Cherrypick Sample Volume);
Readonly::Scalar my $DATA_SOURCE   => q(/prc:process/udf:field[@name="Required Volume"]);
## use critic

extends 'wtsi_clarity::util::clarity_elements_fetcher';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role';

our $VERSION = '0.0';

sub get_targets_uri {
  return ( $OUTPUT_PATH );
};

sub update_one_target_data {
  my ($self, $targetDoc, $targetURI, $value) = @_;

  $self->update_udf_element($targetDoc, $TARGET_NAME, $value);

  return $targetDoc->toString();
};

sub get_data {
  my ($self, $targetDoc, $targetURI) = @_;
  return $self->process_doc->findvalue($DATA_SOURCE);
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::fluidigm_request_volume

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::fluidigm_request_volume->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'Cherrypick sample volume' field of all analytes with the 'Required volume' UDF on the process.

=head1 SUBROUTINES/METHODS

=head2 get_targets_uri
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets are the artifacts of the process.

=head2 update_one_target_data
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets should be updated regardless of the presence of an old tag.

=head2 get_data
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The value used to update the target can be found on the process.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item XML::LibXML

=item Readonly

=item JSON

=back

=head1 AUTHOR

Benoit Mangili E<lt>bm10@sanger.ac.ukE<gt>

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
