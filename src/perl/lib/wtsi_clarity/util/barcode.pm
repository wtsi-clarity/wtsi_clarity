package wtsi_clarity::util::barcode;

use strict;
use warnings;
use Carp;
use Exporter qw(import);

our @EXPORT_OK = qw(calculateBarcode);

our $VERSION = '0.0';

##no critic

sub makeID {
    my $s = shift;
    return $s =~ /^[A-Z]{2}\-[0-9][0-9]*$/ ? $s . makeCheck($s) : "";
}

sub makeCheck {
    my ($s) = @_;
    my @chars = split //, $s;

    my $len = (scalar @chars) - 1;
    my $sum = 0;

    foreach my $c (@chars) {
	next if $c eq '-';
	$sum += ord($c) * $len--;
    }
 
    return chr($sum % 23 + ord('A'));
}

sub numberPrefix {
    # Return the number of two letter prefix
    my ($prefix) = @_;
    my $i = (substr $prefix,0,1);
    my $j = (substr $prefix,1,1);

    $i = ord($i)-64;
    $j = ord($j)-64;
    if($i < 1){$i = 0;}
    if($j < 1){$j = 0;}

    $prefix = (($i * 27) + $j) * 1000000000;

    return $prefix;
}

## Method to return the barcode identifier based on the entity type
## and unique id passed into the method. The barcode identifier is
## returned without the 13th digit check sum, to include this digit
## set $ean13 to true - beware that setting $ean13 to true and not
## passing a number will return a valid barcode identifier, not 12
## zero's.

sub calculateBarcode {
    my ($type,$number) = @_;

    if (!$type) {
      croak 'Barcode prefix is needed for barcode generation';
    }
    if (!$number) {
      croak 'ID is needed for barcode generation';
    }

    my $cl = makeID($type ."-". $number);
    if(!$cl) {
      croak 'Failed to generate id';
    }

    my $bc = numberPrefix($type) + ($number * 100);
    $bc += ord(substr($cl,length($cl)-1));
    if(length($bc) == 11){$bc ="0$bc";}
  
    my $check = checkDigit($bc);
    $bc      .= $check;

    return ($bc, $cl);
}

## Method to find the check digit that should be returned by
## Calculatebarcode but isn't. Argument $stem is $bc as returned from
## the Calculatebarcode method (first 12 digits of the
## barcode). Returns the single digit check sum that should be added
## to the end of $bc (as returned from Calculatebarcode) so that $bc
## will match the 13 digits returned by physically scanning the same
## barcode with a hand scanner.

sub checkDigit {
    my $stem = shift;
    my $sum  = 0;
    while ($stem) {
        $sum += (chop $stem) * 3;
        $sum +=  chop $stem;
    }
    my $mod = 10 - ($sum % 10);
    return ($mod == 10) ? 0 : $mod;
}

1;

__END__

=head1 NAME

wtsi_clarity::util::barcode

=head1 SYNOPSIS

 WTSI barcode generation for labware label printing

=head1 SUBROUTINES/METHODS

=head2 calculateBarcode

=head2 checkDigit

=head2 numberPrefix

=head2 makeCheck

=head2 makeID

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item Exporter

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
