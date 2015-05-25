#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use BBBike::Locale;
use Extract::CGI;

use strict;
use warnings;

my $debug = 1;

our $option;

my $counter = 0;
$BBBike::Locale::option->{"message_path"} = "./world/etc/extract";

sub cgi {
    my $obj = new Extract::CGI;

    isnt( $obj, undef, "cgi" );

    return 1;
}

########################################################################################
# stub
#
$counter += &cgi;

plan tests => $counter;

__END__
