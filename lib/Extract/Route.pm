#!/usr/local/bin/perl
# Copyright (c) 2018-2018 Wolfram Schneider, https://bbbike.org
#
# helper functions for route.cgi

package Extract::Route;

use LWP;
use LWP::UserAgent;

use CGI qw(escapeHTML);
use URI;
use URI::QueryParam;
use Data::Dumper;
use JSON;

use HTTP::Date;

#use Email::Valid;

use lib qw(world/lib);
use Extract::Locale;
use BBBike::Analytics;
use Extract::Config;
use Extract::Poly;
use Extract::Utils;

# qw(normalize_polygon save_request complete_save_request
#    check_queue Param square_km large_int
#    square_km);

use strict;
use warnings;

$ENV{PATH} = "/bin:/usr/bin";

###########################################################################
# config
#

our $debug = 1;
our $option;

our $extract_dialog = '/extract-dialog';

##########################
# helper functions
#

# Extract::Route::new->('debug'=> 2, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {%args};

    bless $self, $class;

    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    # set global debug variable
    $debug  = $self->{'debug'}  if $self->{'debug'};
    $option = $self->{'option'} if $self->{'option'};

    $self->{'formats'}  = $Extract::Config::formats;
    $self->{'database'} = "world/etc/tile/pbf.csv";

    $self->{'locale'} = Extract::Locale->new(
        'q'                   => $self->{'q'},
        'supported_languages' => $option->{'supported_languages'},
        'language'            => $option->{'language'}
    );

    $self->{'language'} = $self->{'locale'}->get_language;
}

######################################################################
# Route functions
#

# validate the JSON file which we downloaded from GPSies.com
sub is_valid {
    my $self = shift;
    my $q    = $self->{'q'};

    my $route = Param( $q, "route" );

    if ( $route eq "" ) {
        warn "No route parameter given, give up\n";
        return 0;
    }

    if ( !$self->valid_route($route) ) {
        warn "Route parameter invalid, give up\n";
        return 0;
    }

    my $perl = $self->fetch_route($route);
    $self->{"route"} = $perl;

    my $bbox = $self->{"bbox"} = $perl->{"features"}[0]{"geometry"}{"bbox"};

    if ( ref $bbox ne 'ARRAY' ) {
        warn "bbox array does not exists, give up\n";
        return 0;
    }

    if ( scalar @$bbox != 4 ) {
        warn "bbox array does not contain 4 elements, give up\n";
        return 0;
    }

    return 1;
}

sub want_json_output {
    my $self = shift;
    my $q    = $self->{'q'};

    my $output = Param( $q, "output" );
    return $output eq 'json' ? 1 : 0;
}

sub json_output {
    my $self = shift;
    my $q    = $self->{'q'};

    print $q->header("application/json");

    # print raw JSON data (unparsed)
    print $self->{"json_data"};
}

# check if the route id is correct
sub valid_route {
    my $self  = shift;
    my $route = shift;

    if ( $route =~ m/^[a-z]{16}$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

# fetch the data from the internet
sub fetch_route {
    my $self  = shift;
    my $route = shift;

    my $file = "../world/t/data-gpsies/$route.js";
    my $url  = $self->create_fetch_url($route);

    my $data = "";

    # local file, for testing
    if ( -e $file ) {
        $data = `cat $file`;
        chomp($data);
    }

    # fetch from the internet
    elsif ( $data = $self->fetch_url($url) ) {
    }

    # error
    else {
        $data = "{}";
    }

    $self->{"json_data"} = $data;

    my $json = new JSON;
    my $perl = {};

    # we return the results as perl hash
    eval { $perl = $json->decode($data); };

    if ($@) {
        warn "Failed to parse json, give up: $file $@\n";

        #warn $data;

        return {};
    }

    return $perl;
}

sub fetch_url {
    my $self = shift;
    my $url  = shift;

    my $ua = LWP::UserAgent->new;
    $ua->agent("BBBike.org-Extract/1.0");

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    warn "fetch URL: $url\n" if $debug >= 1;

    if ( $res->is_success ) {
        return $res->decoded_content();
    }
    else {
        return;
    }
}

# fjurfvdctnlcmqtu -> https://www.gpsies.com/files/geojson/f/j/u/fjurfvdctnlcmqtu.js
sub create_fetch_url {
    my $self = shift;
    my $route = shift // "";

    return "" if !$self->valid_route($route);

    my $prefix = "https://www.gpsies.com/files/geojson";

    # fjurfvdctnlcmqtu -> f/j/u/fjurfvdctnlcmqtu
    if ( $route =~ m,(.)(.)(.)(.+), ) {
        return "$prefix/$1/$2/$3/$1$2$3$4.js";
    }

    # error?
    return "";
}

sub error_message {
    my $self = shift;
    my $error = shift // 500;

    my $q               = $self->{'q'};
    my $script_homepage = $self->{'option'}->{'script_homepage'};

    my $appid = $q->param("appid") // "gpsies1";
    my $ref   = $q->param("ref")   // "gpsies.com";

    my $uri = URI->new($script_homepage);
    $uri->query_form( "error" => $error, "appid" => $appid, "ref" => $ref );

    my $u = $uri->as_string;
    warn "Error, redirect to: $u\n";

    # for now we just redirect to the homepage
    # TODO: write a error message to the user
    print $q->redirect($u);
}

# padding the bbox 10km around
sub increase_bbox {
    my $self    = shift;
    my $bbox    = shift;
    my $padding = shift // $self->{"q"}->param("padding")
      // $self->{'option'}->{'increase_bbox'} // 10;
    my $max_padding = 50;

    $padding = abs( int($padding) );

    # do nothing for padding=0
    if ( $padding == 0 ) {
        return $bbox;
    }

    if ( $padding > $max_padding || $padding <= 0 ) {
        warn "padding=$padding is out of range, reset to $max_padding\n";
        $padding = $max_padding;
    }

    my $b = {
        "ne_lng" => $bbox->[0],
        "ne_lat" => $bbox->[1],
        "sw_lng" => $bbox->[2],
        "sw_lat" => $bbox->[3],
    };

    if ( !$self->validate_bbox_coordinates($b) ) {
        return $bbox;
    }

    # make the rectangle bigger
    my $s           = $padding / 100;
    my $bigger_bbox = [
        $b->{"ne_lng"} + $s,
        $b->{"ne_lat"} + $s,
        $b->{"sw_lng"} - $s,
        $b->{"sw_lat"} - $s
    ];

    warn "padding up bbox: $s\n" if $debug >= 2;

    return $bigger_bbox;
}

sub validate_bbox_coordinates {
    my $self = shift;
    my $b    = shift;

    # to fare north or south, ignore
    if ( $b->{"ne_lat"} > 80 || $b->{"ne_lat"} < -80 ) {
        warn qq[ne_lat out of range +/- 80: $b->{"ne_lat"}, ignore\n];
        return;
    }
    if ( $b->{"sw_lat"} > 80 || $b->{"sw_lat"} < -80 ) {
        warn qq[sw_lat out of range +/- 80: $b->{"sw_lat"}, ignore\n];
        return;
    }

    # out of range
    if ( $b->{"ne_lng"} > 180 || $b->{"ne_lng"} < -180 ) {
        warn qq[ne_lng out of range +/- 180: $b->{"ne_lng"}, ignore\n];
        return;
    }
    if ( $b->{"sw_lng"} > 180 || $b->{"sw_lng"} < -180 ) {
        warn qq[sw_lng out of range +/- 180: $b->{"sw_lng"}, ignore\n];
        return;
    }

    return 1;
}

#
# on success, we does a redirect to /cgi/extract.cgi
#
# https://extract.bbbike.org/cgi/route.cgi?route=fjurfvdctnlcmqtu ->
#
# https://extract.bbbike.org/?sw_lng=-118.679&sw_lat=32.797&ne_lng=-118.237&ne_lat=33.041&format=osm.pbf&city=san%20clemente%20island&lang=en
#
sub redirect {
    my $self = shift;

    my $q   = $self->{'q'};
    my $uri = URI->new( $self->{'option'}->{'script_homepage'} );

    my $bbox = $self->{"bbox"};

    # scale the bbox 10km around
    $bbox = $self->increase_bbox($bbox);

    my $city = $self->{"route"}{"features"}[0]{"properties"}{"name"}
      // "gpsies map";
    my $email  = $q->param("email")  // "nobody";
    my $format = $q->param("format") // "garmin-cycle-latin1.zip";
    my $appid  = $q->param("appid")  // "gpsies1";
    my $ref    = $q->param("ref")    // "gpsies.com";
    my $route  = $q->param("route")  // "";

    $uri->query_form(
        "ne_lng" => $bbox->[0],
        "ne_lat" => $bbox->[1],
        "sw_lng" => $bbox->[2],
        "sw_lat" => $bbox->[3],

        "format" => $format,
        "city"   => $city,
        "email"  => $email,
        "appid"  => $appid,
        "ref"    => $ref,
        "route"  => $route,
    );

    print $q->redirect( $uri->as_string );
}

# EOF
######################################################################

sub header {
    my $self = shift;

    my $q     = shift;
    my %args  = @_;
    my $type  = $args{-type} || "";
    my $error = $args{-error} || "";

    my @onload;
    my @cookie;
    my @css     = "/html/extract.css";
    my @expires = ();
    my @meta    = ();

    if ( $type eq 'homepage' ) {
        @onload = ( -onLoad, 'init();' );
    }
    else {
        push @css, "/html/extract-center.css";
    }

    # store last used selected in cookies for further usage
    if ( $type eq 'check_input' || $type eq 'homepage' ) {
        my @cookies;
        my @cookie_opt = (
            -path    => $q->url( -absolute => 1, -query => 0 ),
            -expires => '+30d'
        );

        my $format = $q->param("format");
        push @cookies,
          $q->cookie(
            -name  => 'format',
            -value => $format,
            @cookie_opt
          ) if defined $format;

        my $email = $q->param("email");
        push @cookies,
          $q->cookie(
            -name  => 'email',
            -value => $email,
            @cookie_opt
          ) if defined $email;

        my $l = $q->param("lang") || "";
        if ( $l && grep { $l eq $_ } @{ $option->{supported_languages} } ) {
            push @cookies,
              $q->cookie(
                -name  => 'lang',
                -value => $l,
                @cookie_opt
              );
        }

        push @cookie, -cookie => \@cookies;
    }

    @meta = (
        $q->meta(
            {
                -http_equiv => 'Content-Type',
                -content    => 'text/html; charset=utf-8'
            }
        ),
        $q->meta(
            {
                -name => 'description',
                -content =>
'Free OpenStreetMap exports from Planet.osm in OSM, PBF, Garmin, Osmand, mapsforge, Navit, SVG, GeoJSON, SQLite or Esri shapefile format (as rectangle or polygon)'
            }
        )
    );

    # do not cache requests
    if ( $type eq 'check_input' ) {
        @expires = ( -expires => "+0s" );

        push @meta,
          $q->meta(
            {
                -name    => 'robots',
                -content => 'nofollow,noarchive,noindex'
            }
          );

        push @meta,
          $q->meta(
            {
                -http_equiv => 'pragma',
                -content    => 'no-cache'
            }
          ),
          ;
    }

    my @status = ( -status => $error ? 520 : 200 );
    my $data = "";

    $data .= $q->header( @status, -charset => 'utf-8', @cookie, @expires );

    $data .= $q->start_html(
        -title => 'BBBike extracts OpenStreetMap',
        -head  => [@meta],
        -style => { 'src' => \@css, },

        # -script => [ map { { 'src' => $_ } } @javascript ],
        @onload,
    );

    return $data;
}

1;

__DATA__;
