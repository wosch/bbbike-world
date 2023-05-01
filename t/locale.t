#!/usr/local/bin/perl
# Copyright (c) Feb 2015-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use CGI;
use Test::More;

use Extract::Locale;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 5;
my $debug = 0;

# wrapper
sub M { return Extract::Locale::M(@_); }

# adjust path for regression tests
$Extract::Locale::option->{"message_path"} = "./world/etc/extract";

##########################################################################
# standard english
my $q      = new CGI;
my $locale = Extract::Locale->new( 'q' => $q );

isnt( $locale, undef, "locale class is success" );
is( M("help"),   "help",   "en:help" );
is( M("foobar"), "foobar", "en:foobar" );

##########################################################################
# German
my $qq = new CGI;
$qq->param( "lang", "de" );
$locale = Extract::Locale->new( 'q' => $qq );

is( M("help"),   "hilfe",  "de:hilfe" );
is( M("foobar"), "foobar", "de:foobar" );

__END__
