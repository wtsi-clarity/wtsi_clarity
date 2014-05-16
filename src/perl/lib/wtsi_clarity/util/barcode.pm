## Created - December 2013
## Carol Scott hack for Clarity LIMs - from original BADGER module
## original VERSION - 1.01
##

package wtsi_clarity::util::barcode;

use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(Verifynumber makeID Calculatebarcode Checkdigit);

our $VERSION = '0.0';

##no critic

sub makeID {

    my $pkg = shift;
    my $s;

    if(! ref $pkg)
    {$s = $pkg;}else{ ($s) = @_;}
    
    return $s =~ /^[0-9]{1,3}\-[0-9][0-9]*$/ ? $s . makeCheck($s) : "";

}

sub IdOrNull {
    my ($s, $type) = @_;
    return validID($s, $type) ? substr($s, 2, -1) : "NULL";
}

sub validID {

    my ($s, $type) = @_;
    return "" if $s !~ /^[0-9]{1,3}\-[1-9][0-9]*[A-Z]$/;

    if (defined $type) {
    #Modified to return NULL on type mis match
	return "NULL" if $type ne substr($s, 0, 2);
    }
    
    my $ck = substr($s, length($s) - 1, 1);

    return $ck eq makeCheck(substr($s, 0, -1));
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

sub Verifynumber {

    my $pkg = shift;
    my $code;
    my $type;
    my $prefix = "Not Determined";
    my $number;
    my $check  = "Not Determined";
    my $sanger = '';
    my $s;
    my $strip;
    my $p;
    

    if(! ref $pkg)
    {
	$code = $pkg;
	$type = shift;
	$code = "$code";
    }
    else
    {
	($code,$type) = @_;
	$code = "$code";
    }
    
    $number = $code;
    if($code !~ /\D/g)
    {

	if((length($code) > 11)&&(length($code) < 14))
	{
	    
	    # For code 128 formats that have only 12 digits
	    while(length($code) < 13){$code = "0$code";}
	    $number 	= substr($code,0,12);
	    
	    $check	 	= chr(substr($number,10));
	    $prefix		= Letter_prefix(substr($number,0,3));
	    $number		= substr($number,3,7)/1;
	    
	    $code = "$prefix" ."-". "$number$check";

	    my $r = validID($code,$type);
	    if ($r eq "NULL")	{$p = "Invalid"	;}
	    elsif(!$r)		{$p = "Bad"	;}
	    else		{$p = "Good"	;}
	    
	    return {	Process => $p, 
			Type 	=> $prefix, 
			Number 	=> $number, 
			Check 	=> $check,
			Whole 	=> $code
	    };
	}
    }
    
    $check = validID($code,$type);
    if ($check eq "NULL")  {  $p = "Invalid"    ;}
    elsif(!$check)	   {  $p = "Bad"	;}
    else	           {  $p = "Good"	;}
    
    if($p ne "Bad")
    {
	$prefix = substr($code,0,2);
	$number = substr($code,2,(length($code)-3));
	$check 	= substr($code,length($code)-1);
    }
    
    return {	Process => $p, 
		Type 	=> $prefix, 
		Number 	=> $number, 
		Check 	=> $check,
		Whole 	=> $code
    };				
}

sub Number_prefix {
    
    my ($prefix) = @_;    
    return (($prefix * 7)  * 1000000000);;

}

sub Letter_prefix {

    my ($prefix) = @_;
    return(sprintf("%.0f", ($prefix/7)));
}

## Method to return the barcode identifier based on the entity type
## and unique id passed into the method. The barcode identifier is
## returned without the 13th digit check sum, to include this digit
## set $ean13 to true - beware that setting $ean13 to true and not
## passing a number will return a valid barcode identifier, not 12
## zero's.

sub Calculatebarcode {

    my ($type,$number,$ean13) = @_;

    if((!$number)||($number < 1)){return ('000000000000','0');}

    my $cl = makeID($type ."-". $number);
    if(!$cl){return (-1);}

    my $bc = Number_prefix($type) + ($number * 100);
    $bc += ord(substr($cl,length($cl)-1));
    if(length($bc) == 11){$bc ="0$bc";}   
    $number = $cl;

    if($ean13) {
	my $check = Checkdigit($bc);
	$bc      .= $check;
    }
    return ($bc, $number);
}

## Method to find the check digit that should be returned by
## Calculatebarcode but isn't. Argument $stem is $bc as returned from
## the Calculatebarcode method (first 12 digits of the
## barcode). Returns the single digit check sum that should be added
## to the end of $bc (as returned from Calculatebarcode) so that $bc
## will match the 13 digits returned by physically scanning the same
## barcode with a hand scanner.

sub Checkdigit {
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

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item vars

=item Exporter

=back

=head1 AUTHOR

Carol Scott E<lt>ces@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL by Carol Scott

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
