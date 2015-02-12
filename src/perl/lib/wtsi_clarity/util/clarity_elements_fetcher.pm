package wtsi_clarity::util::clarity_elements_fetcher;

use Moose;

use wtsi_clarity::util::request;
use wtsi_clarity::util::clarity_elements;

extends 'wtsi_clarity::epp';

our $VERSION = '0.0';

override 'run' => sub {
  my $self= shift;
  super();

  $self->fetch_and_update_targets($self->process_doc->xml);

  $self->put_changes();

  return 1;
};


1;

__END__

=head1 NAME

wtsi_clarity::util::clarity_elements_fetcher

=head1 SYNOPSIS

  Readonly::Scalar my $OUTPUT_PATH          => q(/prc:process/input-output-map/output/@uri);
  Readonly::Scalar my $CONTAINER_PATH       => q(/art:artifact/location/container/@uri);
  Readonly::Scalar my $PROCESS_PURPOSE_PATH => q(/prc:process/udf:field[@name="Plate Purpose"]);
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
    my ($self,$targetDoc, $targetURI) = @_;
    return $self->process_doc->findvalue($PROCESS_PURPOSE_PATH);
  };


=head1 DESCRIPTION

  Offers an abstract class to find and update resources (called 'targets' in this
  context) in XML files, using XPath to find the files. It implements the run
  methods of wtsi_clarity::epp.

  wtsi_clarity::util::clarity_elements and wtsi_clarity::util::clarity_elements_fetcher_role
  must be used in the derived instances.

=head1 SUBROUTINES/METHODS

=head2 run - main callback implementation. Called automatically.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

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
