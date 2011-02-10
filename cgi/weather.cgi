#!/usr/bin/perl

use CGI qw/-utf-8/;
use CGI::Carp;
use IO::File;
use JSON;
use XML::Simple;
use Encode;
use LWP::UserAgent;

use strict;
use warnings;

my $q         = new CGI;
my $debug     = 2;
my $cache_dir = "/var/cache/bbbike";

my $enable_google_weather_forecast = 1;

sub cache_file {
    my $q = shift;

    my $server = $q->server_name;
    my $city   = $q->param('city_script') || $q->param('city');

    if ( $city !~ /^[A-Za-z_-]+$/ ) {
        warn "Illegal city name: '$city'!\n";
        return;
    }
    return "$cache_dir/$server/$city/wettermeldung-$<";
}

sub get_data_from_cache {
    my $file = shift;

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
    -type   => 'application/json;charset=UTF-8',
    -expire => '+30m'
);

if ( $debug >= 9 ) {
    $q->param( "lng",  16.9105306 );
    $q->param( "lat",  52.4093290 );
    $q->param( "city", "Zagreb" );
    $q->param( "lang", "hr" );
}

my $lat  = $q->param('lat')  || "";
my $lng  = $q->param('lng')  || "";
my $lang = $q->param('lang') || "";
my $city = $q->param('city') || "";

Fatal(
    "Missing parameters: lat: '$lat', lng: '$lng', lang: '$lang', city: '$city'"
) if !( $lat && $lng && $lang && $city );

my $url = 'http://ws.geonames.org/findNearByWeatherJSON?lat=';

my $wettermeldung_file      = &cache_file($q);
my $wettermeldung_file_json = "$wettermeldung_file.$lang.json";
my $weather_forecast        = "$wettermeldung_file.forecast.$lang.json";

my %weather;
if ( my $content = get_data_from_cache($wettermeldung_file_json) ) {
    my $forecast = get_data_from_cache($weather_forecast) || "{}";

    $weather{'weather'} = $content;
    $weather{'forecast'} = $forecast if $enable_google_weather_forecast;
    print &merge_json( \%weather );
    exit 0;
}

elsif ( $lat && $lng ) {
    $url .= $lat . '&lng=' . $lng;
    $url .= "&lang=$lang" if $lang && $lang ne "";

    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");

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

    # forecast
    if ($enable_google_weather_forecast) {

        my $city = $q->param('city');

       # by city name
       #$url = 'http://www.google.com/ig/api?weather=' . $city . '&hl=' . $lang;

        # by lat/lng
        $url =
            'http://www.google.com/ig/api?weather='
          . "$city,,,"
          . int( 1_000_000 * $lat ) . ","
          . int( 1_000_000 * $lng )
          . "&hl=$lang";

        warn "Download URL: $url\n" if $debug >= 2;

        $req = HTTP::Request->new( GET => $url );
        $res = $ua->request($req);

        # Check the outcome of the response
        if ( $res->is_success ) {
            my @c = grep { s/^charset=// && $_ } $res->content_type();
            my $charset = $c[0];
            warn "weather forecast charset: $charset\n" if $debug >= 2;
            $content =
              Encode::decode( $charset, $res->content, $Encode::FB_DEFAULT );

            my $perl = XMLin($content);
            my $json = encode_json($perl);
            $weather{'forecast'} = Encode::decode( 'utf-8', $json );
            write_to_cache( $weather_forecast, $weather{'forecast'} );
        }
        else {
            warn "No weather data for: $url\n" if $debug >= 1;
        }
    }

    print &merge_json( \%weather );

}

