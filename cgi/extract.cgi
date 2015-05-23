#!/usr/local/bin/perl -T
# Copyright (c) 2011-2015 Wolfram Schneider, http://bbbike.org
#
# extract.cgi - extracts areas in a batch job
#
# spool area
#   /confirmed  - user confirmed request by clicking on a link in the email
#   /running    - the request is running
#   /osm        - the request is done, files are saved for further usage
#   /download   - where the user can download the files, email sent out
#  /jobN.pid    - running jobs
#
# todo:
# - xxx
#

use CGI qw/-utf8 unescape escapeHTML/;
use CGI::Carp;
use Data::Dumper;

use lib qw[../world/lib ../lib];
use Extract::Config;
use Extract::Utils;
use Extract::CGI;
use BBBike::Locale;

use strict;
use warnings;

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

our $option = {
    'homepage'        => 'http://download.bbbike.org/osm/extract/',
    'script_homepage' => 'http://extract.bbbike.org',

    'max_extracts'              => 50,
    'default_format'            => 'osm.pbf',
    'city_name_optional'        => 0,
    'city_name_optional_coords' => 1,
    'max_skm'                   => 24_000_000,    # max. area in square km
    'max_size'                  => 768_000,       # max area in KB size

    # max count of gps points for a polygon
    'max_coords' => 256 * 256,

    'enable_polygon'      => 1,
    'email_valid_mxcheck' => 1,
    'email_allow_nobody'  => 1,

    'debug'          => "2",
    'request_method' => "GET",

    'supported_languages' => $BBBike::Locale::option->{"supported_languages"},
    'language'            => $BBBike::Locale::option->{"language"},

    'pro' => 0,

    'with_google_maps'        => 0,
    'enable_google_analytics' => 1,

    # scheduler with priorities (by IP or user agent)
    'enable_priority' => 1,

    # scheduler limits
    'scheduler' => {
        'user_limit' => 25,
        'ip_limit'   => 50
    },

    # configure order of formats in menu
    'formats' => [
        {
            'title'   => "OSM",
            'formats' => [
                'osm.pbf', 'osm.xz', 'osm.gz', 'osm.bz2',
                'o5m.xz',  'o5m.gz', 'opl.xz', 'csv.xz',
                'csv.gz'
            ]
        },
        {
            'title'   => "Garmin",
            'formats' => [
                'garmin-osm.zip',     'garmin-cycle.zip',
                'garmin-leisure.zip', 'garmin-bbbike.zip'
            ]
        },
        {
            'title'   => "Android",
            'formats' => [ 'obf.zip', 'mapsforge-osm.zip', 'navit.zip' ]
        },
        { 'title' => "Shapefile", 'formats' => ['shp.zip'] },
        {
            'title'   => "Elevation (SRTM)",
            'formats' => [
                'srtm-europe.osm.pbf',  'srtm-europe.garmin-srtm.zip',
                'srtm-europe.obf.zip',  'srtm.osm.pbf',
                'srtm.garmin-srtm.zip', 'srtm.obf.zip'
            ]
        }
    ],
};

###
# global variables
#
my $q     = new CGI;
my $debug = $option->{'debug'};
if ( defined $q->param('debug') ) {
    $debug = int( $q->param('debug') );
}

my $extract_config = Extract::Config->new( 'q' => $q, 'option' => $option );
$extract_config->load_config;
$extract_config->check_extract_pro;

my $extract_cgi =
  Extract::CGI->new( 'q' => $q, 'option' => $option, 'debug' => $debug );

#my $formats = $Extract::Config::formats;
#my $spool   = $Extract::Config::spool;
#
## spool directory. Should be at least 100GB large
#my $spool_dir = $option->{'spool_dir'} || '/var/cache/extract';
#
#my $language       = "";                  # will be set later
#my $extract_dialog = '/extract-dialog';
#
#my $max_skm = $option->{'max_skm'};
#
## use "GET" or "POST" for forms
#my $request_method = $option->{request_method};
#
## translations
#my $msg;
#
#
#
#
#sub M { return BBBike::Locale::M(@_); };    # wrapper

######################################################################
# main

my $locale = BBBike::Locale->new(
    'q'                   => $q,
    'supported_languages' => $option->{'supported_languages'},
    'language'            => $option->{'language'}
);

if ( $q->param("submit") ) {
    $extract_cgi->check_input( 'q' => $q, 'locale' => $locale );
}
else {
    $extract_cgi->homepage( 'q' => $q, 'locale' => $locale );
}

1;
