#!/usr/local/bin/perl -T
# Copyright (c) 2011-2016 Wolfram Schneider, https://bbbike.org
#
# extract.cgi - extracts areas in a batch job
#

# CGI.pm treat all parameters as UTF-8 strings
use CGI qw(-utf8);
use Data::Dumper;

use lib qw[../world/lib ../lib];
use Extract::Config;
use Extract::CGI;

use strict;
use warnings;

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";
$ENV{PATH} = "/bin:/usr/bin";

our $option = {

    # legacy
    'homepage'             => 'https://download.bbbike.org/osm/extract/',
    'homepage_extract_pro' => 'https://extract-pro.bbbike.org',

    'download_homepage'     => 'https://download.bbbike.org/osm/',
    'download_homepage_pro' => 'https://download.bbbike.org/osm/',

    'server_status_url'     => 'https://download.bbbike.org/osm/extract/',
    'server_status_url_pro' => 'https://download.bbbike.org/osm/extract/',

    # spool directory. Should be at least 100GB large
    'spool_dir' => '/var/cache/extract',

    # A seperate spool directory for pro users.
    # Currently not activated, all users share the same spool directory
    'spool_dir_pro' => '/var/cache/extract',

    'download'     => '/osm/extract/',
    'download_pro' => '/osm/extract/',

    'script_homepage'     => 'https://extract.bbbike.org',
    'script_homepage_pro' => 'https://extract-pro.bbbike.org',

    'script_homepage_api' => 'https://extract4.bbbike.org',

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

    'debug'          => "1",
    'request_method' => "GET",

    'supported_languages' => $Extract::Locale::option->{"supported_languages"},
    'language'            => $Extract::Locale::option->{"language"},

    'pro' => 0,

    'with_google_maps'        => 0,
    'enable_google_analytics' => 1,

    # scheduler with priorities (by IP or user agent)
    'enable_priority' => 1,

    # with intro.js guide
    'enable_introjs' => 1,

    # scheduler limits
    'scheduler' => {

        # per user
        'user_limit' => 25,

        # per ip address
        'ip_limit_adress' => {},

        # general ip address limit if ip_limit_adress{ip address} is not set
        'ip_limit' => 50
    },

    # configure order of formats in menu
    'formats_order' =>
      [qw/osm shape geojson sql garmin android svg bbbike srtm/],

    # start extracts in background for referer customers
    'route_cgi' => { 'auto_submit' => 0 },
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

my $config_error;

eval {
    $extract_config->load_config;
    $extract_config->check_extract_pro;
};

if ($@) {
    $config_error = "$@";
}

my $extract_cgi = Extract::CGI->new(
    'q'      => $q,
    'option' => $option,
    'debug'  => $debug
);

warn Dumper($option) if $debug >= 2;

if ( defined $config_error ) {
    warn "Internal config error: $config_error\n";

    $extract_cgi->check_input(
        'error' => '520',
        'data'  => "Internal config error. Please contact the site maintainer!"
    );
}

# second page
elsif ( $q->param("submit") ) {
    $extract_cgi->check_input;
}

# first page, homee page
else {
    $extract_cgi->homepage;
}

__END__;
