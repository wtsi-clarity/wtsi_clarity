package wtsi_clarity::epp::sm::cherrypick_volume;

use Moose;
use Carp;
use XML::LibXML;
use Readonly;

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $OUTPUT_PATH          => q(/prc:process/input-output-map/input/@post-process-uri);
Readonly::Scalar my $SAMPLE_PATH          => q(/art:artifact/sample/@uri);
Readonly::Scalar my $ARTIFACT_PATH        => q{/smp:sample/artifact/@uri};
Readonly::Scalar my $SAMPLE_VOLUME_NAME   => q(Cherrypick Sample Volume);
Readonly::Scalar my $BUFFER_VOLUME_NAME   => q(Cherrypick Buffer Volume);
Readonly::Scalar my $CONCENTRATION_PATH   => q{/smp:sample/udf:field[@name="Sample Conc. (ng\µL) (SM)"]};
Readonly::Scalar my $AVAILABLE_VOL_PATH   => q{/smp:sample/udf:field[@name="WTSI Working Volume (µL) (SM)"]};

Readonly::Scalar my $MODE_SELECTOR                             => q(/prc:process/udf:field[@name="Pick by"]);
Readonly::Scalar my $REQUIRED_CONCENTRATION_FOR_CONCENTRATION  => q(/prc:process/udf:field[@name="(1) Required Concentration"]);
Readonly::Scalar my $REQUIRED_VOLUME_FOR_CONCENTRATION         => q(/prc:process/udf:field[@name="(1) Required Volume"]);
Readonly::Scalar my $REQUIRED_AMOUNT_FOR_NG_MIN_MAX            => q(/prc:process/udf:field[@name="(2) Required ng Amount"]);
Readonly::Scalar my $MIN_VOLUME_FOR_NG_MIN_MAX                 => q(/prc:process/udf:field[@name="(2) Minimum Volume"]);
Readonly::Scalar my $MAX_VOLUME_FOR_NG_MIN_MAX                 => q(/prc:process/udf:field[@name="(2) Maximum Volume"]);
Readonly::Scalar my $REQUIRED_VOLUME_FOR_VOLUME                => q(/prc:process/udf:field[@name="(3) Required Volume"]);
## use critic

extends 'wtsi_clarity::util::clarity_elements_fetcher';
with 'wtsi_clarity::util::clarity_elements';
with 'wtsi_clarity::util::clarity_elements_fetcher_role';

our $VERSION = '0.0';

sub get_targets_uri {
  return ( $OUTPUT_PATH );
};

sub update_one_target_data {
  my ($self, $targetDoc, $targetURI, $result) = @_;
  my ($sample, $buffer) = @{$result};

  $self->update_udf_element($targetDoc, $SAMPLE_VOLUME_NAME, $sample);
  $self->update_udf_element($targetDoc, $BUFFER_VOLUME_NAME, $buffer);

  return $targetDoc->toString();
};

sub get_data {
  my ($self, $targetDoc, $targetURI) = @_;
  my $mode = $self->process_doc->findvalue($MODE_SELECTOR);
  my ($concentration, $avail_volume) = @{$self->data_source->{$targetURI}};

  my $result;

  if ( $mode eq '(1) Concentration & volume') {
    my $required_concentration = $self->process_doc->findvalue($REQUIRED_CONCENTRATION_FOR_CONCENTRATION);
    my $required_volume        = $self->process_doc->findvalue($REQUIRED_VOLUME_FOR_CONCENTRATION);
    $result = _concentration_and_volume_calculation($required_concentration, $required_volume, $concentration, $avail_volume);
  }
  elsif ($mode eq '(2) ng in a Min and Max volume') {
    my $required_amount = $self->process_doc->findvalue($REQUIRED_AMOUNT_FOR_NG_MIN_MAX);
    my $min_volume      = $self->process_doc->findvalue($MIN_VOLUME_FOR_NG_MIN_MAX);
    my $max_volume      = $self->process_doc->findvalue($MAX_VOLUME_FOR_NG_MIN_MAX);
    $result = _ng_min_max_calculation($required_amount, $min_volume, $max_volume, $concentration, $avail_volume);
  }
  elsif ($mode eq '(3) Volume'){
    my $volume = $self->process_doc->findvalue($REQUIRED_VOLUME_FOR_VOLUME);
    $result = _volume_calculation($volume, $avail_volume);
  }
  else{
    croak q/Unknown option!/;
  }
  return $result;
};

#### private members and methods...

has 'data_source' => (
  isa => 'HashRef',
  is => 'ro',
  required => 0,
  lazy_build => 1,
);

sub _build_data_source {
  my ($self) = @_;

  my $hash_artifact = $self->fetch_targets_hash( ( $OUTPUT_PATH, ) );
  my $hash_samples  = $self->fetch_targets_hash( ( $OUTPUT_PATH, $SAMPLE_PATH ) );

  my $data_hash = {}; # for each artifact uri as a key, we save an array of concentration and volume
                      # { 'http://clari ... /artifacts/00001' => [ 100, 10 ],
                      #   'http://clari ... /artifacts/00002' => [ 100, 35 ],
                      #   'http://clari ... /artifacts/00003' => [ 100, 25 ] }

  while (my ($uri, $doc) = each %{$hash_samples} ) {
    my @artifact = $doc->findnodes( $ARTIFACT_PATH )->get_nodelist();
    my @concentration = $doc->findnodes( $CONCENTRATION_PATH )->get_nodelist();
    my @volume        = $doc->findnodes( $AVAILABLE_VOL_PATH )->get_nodelist();

    # we have to associate the correct uri with the correct data...
    $data_hash->{$artifact[0]->getValue()} = [$concentration[0]->textContent , $volume[0]->textContent];
  }

  return $data_hash;
}

sub _concentration_and_volume_calculation {
  my ($required_concentration, $required_volume, $concentration, $avail_volume) = @_;
  my $vs = $required_concentration * $required_volume / $concentration ;
  if ($vs > $avail_volume) {
    $vs = $avail_volume;
  }
  my $vb = $required_volume - $vs;
  my @output = ($vs, $vb);
  return \@output;
}

sub _ng_min_max_calculation {
  my ($required_amount, $min_volume, $max_volume, $concentration, $avail_volume) = @_;
  my $vs = $required_amount / $concentration ;
  my $vb;

  if ($vs < $min_volume) {
    $vb = $min_volume - $vs;
  }
  elsif ($vs > $max_volume) {
    $vs = $max_volume;
    $vb = 0;
  }
  else {
    $vb = 0;
  }
  my @output = ($vs, $vb);
  return \@output;
}

sub _volume_calculation {
  my ($volume_required, $avail_volume) = @_;
  my @output;
  if ($volume_required > $avail_volume) {
    @output = ($avail_volume, undef );
  }
  else {
    @output = ($volume_required, undef );
  }
  return \@output;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::sm::cherrypick_volume

=head1 SYNOPSIS

  wtsi_clarity::epp:sm::cherrypick_volume->new(process_url => 'http://my.com/processes/3345')->run();

=head1 DESCRIPTION

  Updates the 'Cherrypick sample volume' field of all analytes with the
  'Cherrypick Sample Volume' and 'Cherrypick Buffer Volume' UDFs on the process.

=head1 SUBROUTINES/METHODS

=head2 get_targets_uri
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets are the artifacts of the process.

=head2 update_one_target_data
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The targets should be updated regardless of the presence of an old tag.

=head2 get_data
  Implementation needed by wtsi_clarity::util::clarity_elements_fetcher_role.
  The value used to update the target can be found on the sample of the
  artifact, found on the process.

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
