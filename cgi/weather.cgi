#!/usr/local/bin/perl -T
# Copyright (c) 2009-2018 Wolfram Schneider, https://bbbike.org
#
# weather.cgi - get weather data for a cit
#
# TODO: http://api.openweathermap.org/data/2.5/weather?lat=35&lon=139

use CGI qw/-utf-8/;
use CGI::Carp;
use IO::File;
use JSON;
use XML::Simple;
use Encode;
use LWP::UserAgent;

use strict;
use warnings;

$ENV{PATH} = "/bin:/usr/bin";

my $q         = new CGI;
my $debug     = 2;
my $cache_dir = "/opt/bbbike/cache";

sub cache_file {
    my $q = shift;

    my $server      = $q->server_name;
    my $city_script = $q->param('city_script');

    if ( $server !~ /^([a-z0-9A-Z\.]+)$/ ) {
        warn "Illegal server name: '$server'!\n";
        return;
    }
    $server = $1;

    if ( $city_script !~ /^([A-Za-z]+)$/ ) {
        warn "Illegal city_script name: '$city_script'!\n";
        return;
    }
    $city_script = $1;

    return "$cache_dir/$server/$city_script/wettermeldung-$<";
}

sub get_data_from_cache {
    my $file = shift;

    # ignore cache
    if ( $q->param('generate_cache') ) {
        return;
    }

    my (@stat) = stat($file);
    if ( !defined $stat[9] or $stat[9] + 30 * 60 < time() ) {
        return;
    }
    else {
        my $fh = new IO::File $file, "r"
          or do { warn "open $file: $!\n"; return; };
        binmode $fh, ':utf8';
        warn "Read weather data from cache file: $file\n" if $debug >= 2;

        my $content;
        while (<$fh>) {
            $content .= $_;
        }

        return $content;
    }
}

sub write_to_cache {
    my $file    = shift;
    my $content = shift;

    my $fh = new IO::File $file, "w"
      or do { warn "open > $file: $!\n"; return; };
    binmode $fh, ':utf8';
    warn "Write weather data to cache file: $file\n" if $debug >= 2;

    print $fh $content;
}

sub merge_json {
    my $hash = shift;

    my $data;
    foreach my $key ( keys %$hash ) {
        $data .= ",\n" if $data;
        $data .= qq{  "$key": } . $hash->{$key};
    }

    return "{\n" . $data . "\n}\n";
}

sub Fatal {
    my $message = shift;

    warn $message, "\n";
    print "{}\n";

    exit 1;
}

# $q = CGI->new('lat=53&lng=15&lang=de');
##############################################################################################
#
# main
#

binmode \*STDOUT, ':utf8';
print $q->header(
    -type    => 'application/json',
    -charset => 'utf-8',
    -expires => '+30m'
);

if ( $debug >= 9 ) {
    $q->param( "lng",  16.9105306 );
    $q->param( "lat",  52.4093290 );
    $q->param( "city", "Zagreb" );
    $q->param( "lang", "hr" );
}

my $lat         = $q->param('lat')         || "";
my $lng         = $q->param('lng')         || "";
my $lang        = $q->param('lang')        || "";
my $city        = $q->param('city')        || "";
my $city_script = $q->param('city_script') || "";

# untaint
$lang = ( $lang =~ /^([a-z_]+)$/  ? $1 : "" );
$city = ( $city =~ /^([^\.\s]+)$/ ? $1 : "" );

Fatal(
    "Missing parameters: lat: '$lat', lng: '$lng', lang: '$lang', city: '$city'"
) if !( $lat && $lng && $lang && $city && $city_script );

my $url = 'http://api.geonames.org/findNearByWeatherJSON?username=foobar&lat=';

my $wettermeldung_file      = &cache_file($q);
my $wettermeldung_file_json = "$wettermeldung_file.$lang.json";
my $weather_forecast        = "$wettermeldung_file.forecast.$lang.json";

my %weather;
my $timeout = 5;

if ( my $content = get_data_from_cache($wettermeldung_file_json) ) {
    my $forecast = get_data_from_cache($weather_forecast) || "{}";

    $weather{'weather'} = $content;
    print &merge_json( \%weather );
    exit 0;
}

elsif ( $lat && $lng ) {
    $url .= $lat . '&lng=' . $lng;
    $url .= "&lang=$lang" if $lang && $lang ne "";

    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    $ua->timeout($timeout);

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    # current weather
    warn "Download URL: $url\n" if $debug >= 2;

    if ( $res->is_success ) {
        $weather{'weather'} =
          Encode::decode( 'utf-8', $res->content, $Encode::FB_DEFAULT );
        write_to_cache( $wettermeldung_file_json, $weather{'weather'} );
    }
    else {
        warn "No weather data for: $url\n" if $debug >= 1;
    }

    print &merge_json( \%weather );

}

1;
