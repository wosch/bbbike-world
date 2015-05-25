#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# see also world/t/subplanet-inner.t

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Planet;

use strict;
use warnings;

my $debug = 1;

our $option;

my $counter = 0;

sub planet {
    my $planet = new Extract::Planet;

    isnt( $planet, undef, "planet" );

    return 1;
}

########################################################################################
# stub
#
$counter += &planet;

plan tests => $counter;

__END__
