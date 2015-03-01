#!/usr/local/bin/perl
# Copyright (c) Feb 2015-2015 Wolfram Schneider, http://bbbike.org

use CGI;
use Test::More;

use lib './world/lib';
use BBBikeLocale;

use strict;
use warnings;

plan tests => 5;
my $debug = 0;

# wrapper
sub M { return BBBikeLocale::M(@_); }

# adjust path for regression tests
$BBBikeLocale::option->{"message_path"} = "./world/etc/extract";

##########################################################################
# standard english
my $q = new CGI;
my $locale = BBBikeLocale->new( 'q' => $q );

isnt( $locale, undef, "locale class is success" );
is( M("help"),   "help",   "en:help" );
is( M("foobar"), "foobar", "en:foobar" );

##########################################################################
# German
my $qq = new CGI;
$qq->param( "lang", "de" );
$locale = BBBikeLocale->new( 'q' => $qq );

is( M("help"),   "hilfe",  "de:hilfe" );
is( M("foobar"), "foobar", "de:foobar" );

__END__
