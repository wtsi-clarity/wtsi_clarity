package wtsi_clarity::epp::isc::calliper_analyser;

use Moose;
use Carp;
use Readonly;
use Mojo::Collection;

use wtsi_clarity::util::textfile;
use wtsi_clarity::util::calliper;

##no critic ValuesAndExpressions::RequireInterpolationOfMetachars
Readonly::Scalar my $FIRST_ANALYTE_PATH => q{/prc:process/input-output-map[1]/input/@uri};
Readonly::Scalar my $OUTPUT_ANALYTES    => q{/prc:process/input-output-map/output[@output-type='Analyte']/@uri};
Readonly::Scalar my $CONTAINER_PATH     => q{/art:artifact/location/container/@uri};
Readonly::Scalar my $CONTAINER_NAME     => q{/con:container/name};
Readonly::Scalar my $ARTIFACTS          => q{/art:details/art:artifact};
##use critic

extends 'wtsi_clarity::epp';
with 'wtsi_clarity::util::clarity_elements_fetcher_role_util';
with 'wtsi_clarity::util::clarity_elements';

our $VERSION = '0.0';

override 'run' => sub {
  my $self = shift;
  super();
  return $self->_main();
};

sub _main {
  my $self = shift;

  $self->_text_file->read_content($self->_file_path);

  my $output = $self->_calliper->interpret(
    $self->_text_file->content,
    $self->_plate_barcode,
  );

  my $output_collection = Mojo::Collection->new(@{$output});

  $self->_update_analytes($output_collection);

  $self->_text_file->saveas(q{./} . $self->calliper_file_name);

  return 1;
}

sub _update_analytes {
  my ($self, $output) = @_;
  $self->_add_molarity_to_analytes($output);
  $self->request->batch_update('artifacts', $self->_output_analytes);
  return 1;
}

sub _add_molarity_to_analytes {
  my ($self, $output) = @_;
  my $analytes = $self->_output_analytes->findnodes($ARTIFACTS);

  foreach my $analyte ($analytes->get_nodelist) {
    my $well = $analyte->findvalue('location/value');
    $well =~ s/://sxmg;
    my $result = $output->first(sub { $_->{'Well Label'} eq $well });
    my $udf = $self->create_udf_element($self->_output_analytes, 'Molarity', $result->{'Region[200-1400] Molarity (nmol/l)'});
    $analyte->appendChild($udf);
  }

  return 1;
}

### Attributes ###

has 'calliper_file_name' => (
  isa      => 'Str',
  is       => 'ro',
  required => 1,
);

has '_text_file' => (
  isa => 'wtsi_clarity::util::textfile',
  is  => 'ro',
  required  => 0,
  default => sub { return wtsi_clarity::util::textfile->new(); },
);

has '_calliper' => (
  isa      => 'wtsi_clarity::util::calliper',
  is       => 'ro',
  required => 0,
  default  => sub { return wtsi_clarity::util::calliper->new(); },
);

has '_output_analytes' => (
  isa        => 'XML::LibXML::Document',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__output_analytes {
  my $self = shift;
  my @uri_nodes = $self->process_doc->findnodes($OUTPUT_ANALYTES);
  my @uris = map { $_->getValue() } @uri_nodes;
  return $self->request->batch_retrieve('artifacts', \@uris);
}

has '_plate_barcode' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__plate_barcode {
  my $self = shift;
  my $container_hash = $self->fetch_targets_hash($FIRST_ANALYTE_PATH, $CONTAINER_PATH);
  my $container = (values $container_hash)[0];
  return $container->findvalue($CONTAINER_NAME);
}

has '_file_path' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 0,
  lazy_build => 1,
);

sub _build__file_path {
  my $self = shift;
  my $path = join q{/}, $self->config->robot_file_dir->{'post_lib_pcr_qc'}, $self->_plate_barcode;
  my $ext  = '.csv';
  return $path . $ext;
}

1;

__END__

=head1 NAME

wtsi_clarity::epp::isc::calliper_analyser

=head1 SYNOPSIS

  wtsi_clarity::epp::isc::calliper_analyser
    ->new(
      process_url        => 'http://clarity_url/processes/1234',
      calliper_file_name => 'abcd_file',
    )
    ->run()

=head1 DESCRIPTION

  Finds a calliper file from a process. Extracts molarity from that file and updates molarity on artifacts.
  Saves the calliper file.

=head1 SUBROUTINES/METHODS

=head2 run - runs the script

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item Readonly

=item wtsi_clarity::util::textfile

=item wtsi_clarity::util::calliper

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