#!/usr/local/bin/perl
# Copyright (c) June 2012 Wolfram Schneider, http://bbbike.org
#
# planet-size.cgi - compute size of an extract from planet.osm

use GIS::Distance::Lite;
use CGi;

use strict;
use warning;

my $debug = 0;

sub extract_size {
	my $area = $shift;

	return 20;
}

######################################################################
# GET /w/api.php?namespace=1&q=berlin HTTP/1.1
#
# param alias: q: query, search
#              ns: namespace
#

my $q = new CGI;

my $area = $q->param('area') || "14,14,14,14";
my $namespace = $q->param('namespace') || $q->param('ns') || '0';

if ( my $d = $q->param('debug') || $q->param('d') ) {
    $debug = $d if defined $d && $d >= 0 && $d <= 3;
}

binmode( \*STDERR, ":utf8" ) if $debug >= 1;

my $expire = $debug >= 2 ? '+1s' : '+1h';
print $q->header(
    -type    => 'text/javascript',
    -charset => 'utf-8',
    -expires => $expire,
);

binmode( \*STDOUT, ":utf8" );

my @list = &latlngnames_suggestions_unique(
    'city'        => $city,
    'latlng'      => $latlng,
    'granularity' => $granularity,
);

print &size($area);

