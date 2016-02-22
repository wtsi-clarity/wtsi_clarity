#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Clarity' ) || print "Bail out!\n";
}

diag( "Testing WWW::Clarity $WWW::Clarity::VERSION, Perl $], $^X" );
