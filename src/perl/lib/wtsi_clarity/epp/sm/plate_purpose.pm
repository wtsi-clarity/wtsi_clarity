package wtsi_clarity::epp::sm::plate_purpose;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_PATH          => q(/prc:process/input-output-map/output/@uri);
Readonly::Scalar my $PROCESS_PURPOSE_PATH => q(/prc:process/udf:field[@name="Plate Purpose"]);
Readonly::Scalar my $CONTAINER_PATH       => q(/art:artifact/location/container/@uri);
Readonly::Scalar my $TARGET_NAME          => q(WTSI Container Purpose Name);
## use critic

extends 'wtsi_clarity::util::clarity_elements_fetcher';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role';


our $VERSION = '0.0';

sub get_targets_uri {
  return ( $OUTPUT_PATH, $CONTAINER_PATH );
};

sub update_one_target_data {
  my ($self, $targetDoc, $targetURI, $value) = @_;

  $self->set_udf_element_if_absent($targetDoc, $TARGET_NAME, $value);

  return $targetDoc->toString();
};

sub get_data {
  my ($self, $targetDoc, $targetURI) = @_;
  return $self->process_doc->findvalue($PROCESS_PURPOSE_PATH);
};

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::plate_purpose

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::plate_purpose->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'purpose' field of all WTSI Containers in the process to the plate purpose field.

=head1 SUBROUTINES/METHODS

=head2 get_targets_uri
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets are the containers find inside each artifact of the process.

=head2 update_one_target_data
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets should only be updated if the target value is not present.

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
