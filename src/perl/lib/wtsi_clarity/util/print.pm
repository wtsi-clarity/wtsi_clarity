package wtsi_clarity::util::print;

use Moose::Role;
use wtsi_clarity::util::error_reporter qw/croak/;
use JSON;

use wtsi_clarity::util::request;

requires 'config';

our $VERSION = '0.0';

has '_json_request' => (
  isa => 'wtsi_clarity::util::request',
  is  => 'ro',
  traits => [ 'NoGetopt' ],
  default => sub { return wtsi_clarity::util::request->new('content_type' => 'application/json'); },
);

sub print_labels {
  my ($self, $printer_name, $template) = @_;

  my $printer_url = $self->_get_printer_url($printer_name);

  $self->_json_request->post($printer_url, encode_json($template));

  return;
}

sub _get_printer_url {
  my ($self, $printer_name) = @_;

  my $print_service = $self->config->printing->{'service_url'};
  if (!$print_service) {
    croak( q[service_url entry should be defined in the printing section of the configuration file]);
  }
  my $url =  "$print_service/label_printers/page\=1";
  my $p;

  my $output = $self->_json_request->get($url);
  my $text = decode_json($output);

  foreach my $t ( @{$text->{'label_printers'}} ){
    if ($t->{'name'} && $t->{'name'} eq $printer_name){
      if (!$t->{'uuid'}) {
        croak ( qq[No uuid for printer $printer_name] );
      }
      $p = join q[/], $print_service, $t->{'uuid'};
    }
  }
  if (!$p) {
    croak ( qq[Failed to get printer $printer_name details from $url] ) ;
  }
  return $p;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::print

=head1 SYNOPSIS

    with wtsi_clarity::util::print;

    $self->print_labels($printer_name, $template);

=head1 DESCRIPTION

 Prints some labels to a printer

=head1 SUBROUTINES/METHODS

=head2 print_labels

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role;

=item wtsi_clarity::util::error_reporter;

=item JSON;

=item wtsi_clarity::util::request;

=back

=head1 AUTHOR

Carol Scott E<lt>ces@sanger.ac.ukE<gt>

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
