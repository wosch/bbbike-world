#!/usr/bin/perl -w
# -*- perl -*-

# Author: Slaven Rezic
#
# Copyright (C) 2005,2006,2007,2008 Slaven Rezic. All rights reserved.
# Copyright (C) 2008i-2010 Wolfram Schneider. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@users.sourceforge.net
# WWW:  http://bbbike.sourceforge.net
#

package BBBikeGooglemap;

use strict;
use FindBin;
use lib (
    grep { -d } (
        "$FindBin::RealBin/..",
        "$FindBin::RealBin/../lib",

        # für Radzeit:
        "$FindBin::RealBin/../BBBike",
        "$FindBin::RealBin/../BBBike/lib",
    )
);
use CGI qw(:standard);
use CGI::Carp;
use File::Basename qw(dirname);
use URI;
use BBBikeCGI::Util qw();
use BBBikeVar;
use Karte;
use Karte::Polar;
use Encode;
use Data::Dumper;

sub new { bless {}, shift }

our $force_utf8   = 1;
our $cgi_utf8_bug = 1;

sub run {
    my $self = shift;
    my %args = @_;

    warn __PACKAGE__, "::run->() ", join " ", caller(), "\n"
      if $args{'debug'} >= 2;

    my $q                = $args{'q'};
    my $gmap_api_version = $args{'gmap_api_version'};
    my $lang             = $args{'lang'};
    my $fullscreen       = $args{'fullscreen'};
    my $cache            = $args{'cache'};
    my $region           = $args{'region'} || "other";
    my $nomap            = $args{'nomap'} || 0;

    my $city = $q->param('city') || "";
    if ($city) {
        $ENV{DATA_DIR} = $ENV{BBBIKE_DATADIR} = "data-osm/$city";
    }
    $self->{gmap_api_version} = $gmap_api_version;

    local $CGI::POST_MAX = 2_000_000;

    my @polylines_polar;
    my @polylines_route;
    my @polylines_polar_feeble;
    my @wpt;

    my $coordsystem = param("coordsystem") || "wgs84";
    my $converter;
    if ( $coordsystem =~ m{^(wgs84|polar)$} ) {
        $converter = \&polar_converter;
        $coordsystem = 'polar';    # normalize XXX should be wgs84 some day?
    }
    else {                         # bbbike or standard
        $converter = \&bbbike_converter;
    }

    my $filename = param("gpxfile");

    for my $def (
        [ 'coords', \@polylines_route ],

        #[ 'city_center', \@polylines_polar ],
        [ 'area', \@polylines_polar ],

        #[ 'oldcoords',   \@polylines_polar_feeble ],
      )
    {
        my ( $cgiparam, $polylines_ref ) = @$def;

        for my $coords ( $q->param($cgiparam) ) {
            my (@coords) = split /[!;]/, $coords;
            my (@coords_polar) = map {
                my ( $x, $y ) = split /,/, $_;
                join ",", $converter->( $x, $y );
            } @coords;
            push @$polylines_ref, \@coords_polar;
        }
    }

    # center defaults to Berlin
    if ( scalar(@polylines_polar) == 0 ) {
        push @polylines_polar, ["13.376431,52.516172"];
    }

    for my $wpt ( $q->param("wpt") ) {
        my ( $name, $coord );
        if ( $wpt =~ /[!;]/ ) {
            ( $name, $coord ) = split /[!;]/, $wpt;
        }
        else {
            $name  = "";
            $coord = $wpt;
        }
        my ( $x, $y ) = split /,/, $coord;
        ( $x, $y ) = $converter->( $x, $y );
        push @wpt, [ $x, $y, $name ];
    }

    my $zoom = $q->param("zoom");
    $zoom = 3 if !defined $zoom;

    my $autosel = $q->param("autosel") || "";
    $self->{autosel} = $autosel && $autosel ne 'false' ? "true" : "false";

    my $maptype = $q->param("maptype") || "";
    $self->{maptype} = (
          $maptype =~ /hybrid/i    ? 'G_HYBRID_MAP'
        : $maptype =~ /normal/i    ? 'G_NORMAL_MAP'
        : $maptype =~ /^satelite/i ? 'G_SATELLITE_MAP'
        : $maptype =~ /^physical/i ? 'G_PHYSICAL_MAP'
        : $maptype =~ /^cycle$/    ? 'cycle_map'
        : $maptype =~ /^mapnik$/   ? 'mapnik_map'
        : $maptype =~ /^tah$/      ? 'tah_map'
        : 'cycle_map'
    );

    my $mapmode = $q->param("mapmode") || "";
    ( $self->{initial_mapmode} ) =
      $mapmode =~ m{^(search|addroute|browse|addwpt)$};
    $self->{initial_mapmode} ||= "";

    my $center = $q->param("center") || "";

    $self->{converter}   = $converter;
    $self->{coordsystem} = $coordsystem;

    #print header ( "-type" => "text/html; charset=utf-8" );

    binmode( \*STDOUT, ":utf8" ) if $force_utf8;
    binmode( \*STDERR, ":utf8" ) if $force_utf8;

    print $self->get_html( \@polylines_polar, \@polylines_route, \@wpt, $zoom,
        $center, $q, $lang, $fullscreen, $cache, $region, $nomap );
}

sub bbbike_converter {
    my ( $x, $y ) = @_;
    local $^W;    # avoid non-numeric warnings...
    $Karte::Polar::obj->standard2map( $x, $y );
}

sub polar_converter { @_[ 0, 1 ] }

sub to_array {
    my @coords = @_;

    my $marker_list = '';
    foreach my $c (@coords) {
        next if $c !~ /,/;

        my ( $y, $x ) = split( /,/, $c );
        $marker_list .= qq/[$x,$y],/;
    }
    $marker_list =~ s/,\s*$//;
    return $marker_list;
}

sub get_html {
    my (
        $self,       $paths_polar, $paths_route, $wpts,
        $zoom,       $center,      $q,           $lang,
        $fullscreen, $cache,       $region,      $nomap
    ) = @_;

    #open(O, "> /tmp/a.log"); print O "nomap: $nomap\n";
    my $log_routes = 0;

    my $converter   = $self->{converter};
    my $coordsystem = $self->{coordsystem};

    use Data::Dumper;
    my $coords = $$paths_polar[0];
    my $route  = $$paths_route[0];

    my $marker_list = "[" . &to_array( @{$coords} ) . "]";
    my $route_list  = &to_array(@$route);

    my ( $centerx, $centery );
    if ($center) {
        ( $centerx, $centery ) = map { sprintf "%.5f", $_ } split /,/, $center;
    }
    elsif ( $paths_polar && @$paths_polar ) {
        ( $centerx, $centery ) = map { sprintf "%.5f", $_ } split /,/,
          $paths_polar->[0][0];
    }
    elsif ( $wpts && @$wpts ) {
        ( $centerx, $centery ) = map { sprintf "%.5f", $_ } $wpts->[0][0],
          $wpts->[0][1];
    }
    else {
        require Geography::Berlin_DE;
        ( $centerx, $centery ) =
          $converter->( split /,/, Geography::Berlin_DE->center() );
    }

    my %google_api_keys = (
        'bbbike.dyndns.org' =>
"ABQIAAAAidl4U46XIm-bi0ECbPGe5hSLqR5A2UGypn5BXWnifa_ooUsHQRSCfjJjmO9rJsmHNGaXSFEFrCsW4A",

        '78.47.225.30' =>
"ABQIAAAACNG-XP3VVgdpYda6EwQUyhTTdIcL8tflEzX084lXqj663ODsaRSCKugGasYn0ZdJkWoEtD-oJeRhNw",
        'bbbike.de' =>
'ABQIAAAACNG-XP3VVgdpYda6EwQUyhRfQt6AwvKXAVZ7ZsvglWYeC-xX5BROlXoba_KenDFQUtSEB_RJPUVetw',
        'bbbike.org' =>
'ABQIAAAAX99Vmq6XHlL56h0rQy6IShRC_6-KTdKUFGO0FTIV9HYn6k4jEBS45YeLakLQU48-9GshjYiSza7RMg',
        'www.bbbike.org' =>
'ABQIAAAAX99Vmq6XHlL56h0rQy6IShRC_6-KTdKUFGO0FTIV9HYn6k4jEBS45YeLakLQU48-9GshjYiSza7RMg',
        'dev.bbbike.org' =>
'ABQIAAAAX99Vmq6XHlL56h0rQy6IShQGl2ahQNKygvI--_E2nchLqmbBhxRLXr4pQqVNorfON2MgRTxoThX1iw',
        'devel.bbbike.org' =>
'ABQIAAAAX99Vmq6XHlL56h0rQy6IShSz9Y_XkjB4bplja172uJiTycvaMBQbZCQc60GoFTYOa5aTUrzyHP-dVQ',
        'localhost' =>
'ABQIAAAAX99Vmq6XHlL56h0rQy6IShT2yXp_ZAY8_ufC3CFXhHIE1NvwkxTN4WPiGfl2FX2PYZt6wyT5v7xqcg',
    );

    my $full = URI->new( BBBikeCGI::Util::my_url( CGI->new($q), -full => 1 ) );
    my $fallback_host = "bbbike.de";
    my $host = eval { $full->host } || $fallback_host;

    # warn "Google maps API: host: $host, full: $full\n";

    my $google_api_key = $google_api_keys{$host}
      || $google_api_keys{$fallback_host};
    my $cgi_reldir = dirname( $full->path );
    my $is_beta = $full =~ m{bbikegooglemap2.cgi};

    my $bbbikeroot      = "/BBBike";
    my $get_public_link = sub {
        BBBikeCGI::Util::my_url( CGI->new($q), -full => 1 );
    };
    if ( $host eq 'bbbike.dyndns.org' ) {
        $bbbikeroot = "/bbbike";
    }
    elsif ( $host =~ m{srand\.de} ) {
        $bbbikeroot = dirname( dirname( $full->path ) );
    }
    elsif ( $host eq 'localhost' ) {
        $bbbikeroot      = "/bbbike";
        $get_public_link = sub {
            my $link = BBBikeCGI::Util::my_url( CGI->new($q), -full => 1 );
            $link =~ s{localhost$bbbikeroot/cgi}{bbbike.de/cgi-bin};
            $link;
        };
    }

    my $script;
    my $slippymap_size = "";

    if ( $q->user_agent("XXXiPhone") || $nomap ) {

        #$slippymap_size = qq{ style="width:240px; height:240px; "};
        $slippymap_size = qq{ style="display:none"};
    }

    my $city = $q->param('city') || "";
    my $gmap_api_version = $self->{gmap_api_version};

    $lang = "en" if !$lang;

    my $startname    = Encode::decode( utf8 => $q->param('startname') );
    my $zielname     = Encode::decode( utf8 => $q->param('zielname') );
    my $vianame      = Encode::decode( utf8 => $q->param('vianame') || "" );
    my $driving_time = Encode::decode( utf8 => $q->param('driving_time') );
    my $route_length = Encode::decode( utf8 => $q->param('route_length') );
    my $zoom_param = $q->param('zoom_param');

    my $map   = Encode::decode( utf8 => $q->param('map') )   || "default";
    my $layer = Encode::decode( utf8 => $q->param('layer') ) || "";

    my $html = "";

    if ($fullscreen) {
        $html = <<EOF;
<style type="text/css">
div#BBBikeGooglemap { 
	width: 90%; 
	height: 80%; 
	margin-left: 5%; 
	margin-right: 5%; 
	padding: 0em; 
        top: 0em; 
	left: 0em;
}
</style>
EOF
    }

    my $viac = $q->param('viac') || "";
    my $route_points =
      scalar(@$route) >= 2 ? to_array( $$route[0], $$route[-1] ) : "";
    if ($viac) {    # && grep { $viac eq $_ } @$route ) {
        $route_points .= ", " . &to_array($viac);
    }

    $html .= <<EOF;
<!-- BBBikeGooglemap starts here -->
<div id="chart_div" onmouseout="clearMouseMarker()" style="display:none"></div>
<div id="BBBikeGooglemap" $slippymap_size>
EOF

    $html .=
qq{<script type="text/javascript"> google.load("maps", $gmap_api_version); </script>\n}
      if $gmap_api_version == 2;

    $region = "other" if $region !~ /^(de|eu|other)$/;
    my $is_route = scalar(@$route);

    if ( !$nomap ) {
        my $m = $map eq 'default' && $route_length ne '' ? "cycle" : $map;

        $html .= <<EOF;

    <div id="map"></div>

    <div id="nomap_script">
    <script type="text/javascript">
    //<![CDATA[

    var marker_list = [ $route_list ];

    var marker_list_points = [ $route_points ];

    city = "$city";
    bbbike_maps_init("$m", $marker_list, "$lang", false, "$region", "$zoom_param", "$layer", $is_route );
    if (document.getElementById("suggest_start")) {
	init_markers({"lang":"$lang"});
    }

EOF
    }
    else {
        $html .= <<EOF;
    <script type="text/javascript">
    //<![CDATA[
    state.marker_list = $marker_list;
     
EOF
    }

    if ( $route_length ne '' ) {

        $html .= <<EOF;
     var elevation_obj = {
	"driving_time":"$driving_time",
	"area":$marker_list,
	"lang":"$lang",
	"route_length":"$route_length",
	"city":"$city",
	"startname":"@{[ CGI::escapeHTML($startname) ]}",
	"zielname": "@{[ CGI::escapeHTML($zielname) ]}",
	"vianame":  "@{[ CGI::escapeHTML($vianame) ]}",
	"maptype":"cycle"
    };
    elevation_initialize(map, elevation_obj);
EOF
    }

    $html .= <<EOF;
   
    //]]>
    </script>
    <noscript>
        <p>You must enable JavaScript and CSS to run this application!</p>
    </noscript>
</div> <!-- nomaps -->
</div> <!-- BBBikeGooglemap -->
<!-- BBBikeGooglemap ends here -->
EOF

    # log route queries
    if ( $log_routes && !$cache ) {

        eval {

            # utf8 fixes
            if ($cgi_utf8_bug) {
                foreach my $key (qw/startname zielname vianame/) {
                    my $val = $q->param($key);
                    $val = Encode::decode( "utf8", $val );

                    # XXX: have to run decode twice!!!
                    #$val = Encode::decode( "utf8", $val );

                    $q->param( $key, $val );
                }
            }

            my $url = $q->url( -query => 1, -full => 1 );
            warn "URL:$url\n";
        };
    }
    return $html;
}

#my $o = BBBikeGooglemap->new;
#$o->run(new CGI);

1;

