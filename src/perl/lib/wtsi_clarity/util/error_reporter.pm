package wtsi_clarity::util::error_reporter;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(croak croak_with_stack);

our $VERSION = '0.0';

sub croak {
  my ($error) = @_;
  _croak(0, $error);
  return ;
}

sub croak_with_stack {
  my ($error) = @_;
  _croak(1, $error);
  return ;
}
## no critic (ValuesAndExpressions::ProhibitMagicNumbers, CodeLayout::ProhibitParensWithBuiltins)
sub _croak {
  my ($with_debug, $error) = @_;

  my $msg;
  if ($with_debug) {
    my $i = 0;
    my $stack_trace;
    while ( (my @call_details = (caller($i++))) ){
      my $detail1 = $call_details[1];
      my $detail2 = $call_details[2];
      my $detail3 = $call_details[3];
      $stack_trace .=  "$detail1:$detail2 in function $detail3\n";
    }
    $msg = "[ERROR]: " . _make_long_format_error( $error ."\n". $stack_trace );
  }
  else {
    $msg = "[ERROR]: Please contact support. Error detail: " .
    _make_short_format_error ( $error );
  }
  use Carp ();
  Carp::croak($msg);
}

sub _make_long_format_error {
  my $error = shift;

  my $msg = join " . . . . ", split /\R/smx, $error;
  return substr( $msg, 0, 720 );
}

sub _make_short_format_error {
  my $error = shift;

  my @lines = split /\R/smx, $error;
  my $msg = pop @lines;
  return substr( $msg, 0, 720 );
}

## use critic

1;

__END__

=head1 NAME

wtsi_clarity::util::error_reporter

=head1 SYNOPSIS

  wtsi_clarity::util::error_reporter

=head1 DESCRIPTION

  Provides an error generator to replace croak.

=head1 SUBROUTINES/METHODS

=head2 croak_with_stack

=head2 croak

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Carp

=item Exporter

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
