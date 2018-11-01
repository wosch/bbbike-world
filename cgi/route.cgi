#!/usr/local/bin/perl
# -T
# Copyright (c) 2011-2018 Wolfram Schneider, https://bbbike.org
#
# route.cgi - redirect to extract.cgi based on GPX file
#

# CGI.pm treat all parameters as UTF-8 strings
use CGI qw(-utf8);

use lib qw[../world/lib ../lib];
use Extract::Config;
use Extract::Route;
use Extract::CGI;

use strict;
use warnings;

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";
$ENV{PATH} = "/bin:/usr/bin";

our $option = {

    # XXX?
    'homepage'             => 'https://download.bbbike.org/osm/extract/',
    'homepage_extract_pro' => 'https://extract-pro.bbbike.org',
    'download_homepage'    => 'https://download.bbbike.org/osm/',

    'server_status_url'     => 'https://download.bbbike.org/osm/extract/',
    'server_status_url_pro' => 'https://download.bbbike.org/osm/extract-pro/',

    'script_homepage'     => 'https://extract.bbbike.org',
    'script_homepage_pro' => 'https://extract-pro.bbbike.org',

    'default_format' => 'garmin-cycle.zip',

    # max count of gps points for a polygon
    'max_coords' => 256 * 256,

    'enable_polygon' => 1,

    'debug'          => "1",
    'request_method' => "GET",

    'supported_languages' => $Extract::Locale::option->{"supported_languages"},
    'language'            => $Extract::Locale::option->{"language"},

    'pro' => 0,
};

##########################################################################
# main
#
my $q     = new CGI;
my $debug = $option->{'debug'};
if ( defined $q->param('debug') ) {
    $debug = int( $q->param('debug') );
}

my $extract_config = Extract::Config->new( 'q' => $q, 'option' => $option );
$extract_config->load_config;
$extract_config->check_extract_pro;

my $route_cgi = Extract::Route->new(
    'q'      => $q,
    'option' => $option,
    'debug'  => $debug
);

# valid request, we got all data successfully
if ( $route_cgi->is_valid ) {

    # workaround for Access-Control-Allow-Origin
    if ( $route_cgi->want_json_output ) {
        $route_cgi->json_output;
    }

    # redirect to /cgi/extract.cgi
    else {
        $route_cgi->redirect;
    }
}

# else throw error page in HTML
else {
    $route_cgi->error_message;
}

__END__;
https://dev3.bbbike.org/cgi/route.cgi?route=htvrzxsdzbhhinis
https://www.gpsies.com/files/geojson/f/j/u/fjurfvdctnlcmqtu.js
