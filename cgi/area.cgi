#!/usr/local/bin/perl
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# area.cgi - which areas are covered by bbbike.org

use CGI qw/-utf-8/;
use IO::File;
use IO::Dir;
use File::stat;
use JSON;
use Data::Dumper;
use Getopt::Long;

use lib './world/bin';
use lib '../world/bin';
use lib '../bin';
use BBBikeWorldDB;

use strict;
use warnings;

my $debug               = 1;
my $city_default        = "Berlin";
my $download_bbbike_org = "http://download.bbbike.org";
my $www_bbbike_org      = "http://www.bbbike.org";

binmode \*STDOUT, ":raw";
my $q = new CGI;

sub footer {
    my %args   = @_;
    my $q      = new CGI;
    my $cities = $args{'cities'};

    my $city = $args{'city'};

    $city = $city_default if $city !~ /^[A-Z][a-z]+$/;
    $city = $city_default if !grep { $city eq $_ } @$cities;

    $city = CGI::escapeHTML($city);

    return <<EOF;
<div id="footer">
<div id="footer_top">
<a href="/">home</a> |
<a href="$www_bbbike_org/community.html">donate</a> |
<a href="$www_bbbike_org/$city/" title="start bicycle route from $city area">$city</a> |
<a href="javascript:resizeOtherCities(more_cities);">more cities</a>

</div>
</div>
<hr/>

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
(&copy;) 2008-2012 <a href="http://bbbike.org">BBBike.org</a> // Map data by <a href="http://www.openstreetmap.org/" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
<div id="footer_community">
</div>
</div>
EOF
}

# file size in x.y MB
sub file_size {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $st->size / 1024 / 1024 ) / $scale;
        return "$result M" if $result > 0;
    }

    return "0.1K";
}

sub mtime {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";
    return $st->mtime;
}

sub download_area {
    my $city = shift || $city_default;
    my $osm_dir = "../osm";

    #die system("pwd > /tmp/a.pwd");
    my $dir = "$osm_dir/$city/";

    my $data = <<EOF;
<h3>OSM extracts for $city</h3>
<table>

EOF

    my $dh = IO::Dir->new($dir);
    if ( !defined $dh ) {
        warn "open dir '$dir': $!\n";
    }
    else {

        my @list;
        while ( defined( my $filename = $dh->read ) ) {
            next if $filename eq '.' || $filename eq '..';
            next if $filename eq 'HEADER.txt';
            next if $filename eq 'index.html';

            push @list, $filename;
        }
        $dh->close;

        foreach my $file ( sort @list ) {
            my $date = localtime( &mtime("$dir/$file") );
            $data .=
qq{<tr><td><a href="$download_bbbike_org/osm/bbbike/$city/$file" title="$date">$file</a></td>}
              . qq{<td align="right">}
              . file_size("$dir/$file")
              . qq{</td></tr>\n};
        }
    }

    $data .= <<EOF;
</table>
<hr/>
EOF

    $data .= qq{<div id="debug"></div>\n} if $debug >= 2;
    return $data;
}

sub header {
    my $q       = shift;
    my $offline = shift;
    my $city    = shift;

    my $sensor = 'true';
    my $base   = "";
    if ($offline) {
        $base = "$www_bbbike_org/cgi/";
    }

    my @javascript = (
        "../html/jquery-1.4.2.min.js",
"../html/devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete-min.js",
"http://maps.google.com/maps/api/js?sensor=$sensor&amp;libraries=weather,panoramio",
        "../html/bbbike.js",
        "../html/maps3.js",
    );

    return $q->start_html(
        -title => "BBBike @ World covered areas - osm extracts for $city",
        -head  => [
            $q->meta(
                {
                    -http_equiv => 'Content-Type',
                    -content    => 'text/html; charset=utf-8'
                }
            ),
        ],

        -style => {
            'src' => [
                $base
                  . "../html/devbridge-jquery-autocomplete-1.1.2/styles.css",
                $base . "../html/bbbike.css"
            ]
        },
        -script =>
          [ map { { 'src' => ( /^http:/ ? $_ : $base . $_ ) } } @javascript ],
    );
}

sub js_jump {
    my $map_type = shift;

    return <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    city = "dummy";
    bbbike_maps_init('$map_type', [[43, 8],[57, 15]], "en", 1 );
  
    function jumpToCity (coord) {
	var b = coord.split("!");

	var bounds = new google.maps.LatLngBounds;
        for (var i=0; i<b.length; i++) {
	      var c = b[i].split(",");
              bounds.extend(new google.maps.LatLng( c[1], c[0]));
        }
        map.setCenter(bounds.getCenter());
        map.fitBounds(bounds);
	var zoom = map.getZoom();

        // no zoom level higher than 15
         map.setZoom( zoom < 16 ? zoom + 0 : 16);
    } 

    //]]>
    </script>
EOF
}

sub css_map {
    return <<EOF;
<style type="text/css">
div#BBBikeGooglemap { left: 23em; }
</style>

EOF
}

sub js_map {
    my $map_type = shift;

    return <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    var resize;
    setTimeout(function () { setMapWidth(); }, 200);

    // reset map size, 3x a second
    jQuery(window).resize(function () {
        if (resize) clearTimeout(resize);
        resize = setTimeout(function () {
            setMapWidth();
        }, 300);
    });

    //]]>
    </script>
EOF
}

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}          debug level, default: $debug
--offline               run offline
EOF
}

##############################################################################################
#
# main
#
my $help;
my $offline = 0;
my $offline_city;

GetOptions(
    "debug=i" => \$debug,
    "help"    => \$help,
    "offline" => \$offline,
    "city=s"  => \$offline_city,
) or die usage;

die usage if $help;

my $database = "world/etc/cities.csv";
$database = "../$database" if -e "../$database";

my $db = BBBikeWorldDB->new( 'database' => $database, 'debug' => 0 );

print $q->header( -charset => 'utf-8', -expires => '+30m' ) if !$offline;

my $city_area = $q->param('city') || "";
my $city = $q->param('city') || $offline_city || $city_default;

print &header( $q, $offline, $city );
print &css_map;

print qq{<div id="sidebar">}, &download_area($city), qq{</div>\n};
print qq{<div id="BBBikeGooglemap" style="height:94%">\n};
print qq{<div id="map"></div>\n};

my $map_type = $city_area ? "mapnik" : "terrain";
print &js_jump($map_type);
print &js_map;

print <<EOF;
<script type="text/javascript">
city = "$city";

EOF

my $json = new JSON;
my $counter;
my @route_display;

my %hash = %{ $db->city };
my $city_center;
my @city_list;
foreach my $city ( sort keys %hash ) {

    my $coord = $hash{$city}->{'coord'};

    # warn "c: $city\n"; warn Dumper($hash{$city}), "\n";

    my $opt;
    my ( $x1, $y1, $x2, $y2 ) = split /\s+/, $coord;

    $opt->{"area"}        = "$x1,$y1!$x2,$y2";
    $opt->{"city"}        = "$city";
    $city_center->{$city} = $opt->{"area"};

    my $opt_json = $json->encode($opt);
    print qq{plotRoute(map, $opt_json, "[]");\n};

    push @city_list, $city;
}

if ( $city && exists $city_center->{$city} ) {
    print "\n", qq[jumpToCity('$city_center->{$city}');\n];
}

print <<EOF;
var more_cities = false;
function resizeOtherCities(toogle) {
    var tag = document.getElementById("BBBikeGooglemap");
    var tag_more_cities = document.getElementById("more_cities");

    if (!tag) return;
    if (!tag_more_cities) return;

    if (!toogle) {
        tag.style.height = "75%";
	tag_more_cities.style.display = "block";
	tag_more_cities.style.fontSize = "85%";

    } else {
	tag_more_cities.style.display = "none";
        tag.style.height = "90%";
    }

    more_cities = toogle ? false : true;
    google.maps.event.trigger(map, 'resize');
}

// resizeFullScreen(false);

</script>
<noscript>
<p>You must enable JavaScript and CSS to run this application!</p>
</noscript>
</div> <!-- map -->

EOF

print qq{<div id="bottom">\n};
print qq{<div id="more_cities" style="display:none;">\n<p/>\n};
foreach my $c (@city_list) {
    next if $c eq 'dummy' || $c eq 'bbbike';
    print qq{<a href="}
      . ( $offline ? "../$c/" : qq{?city=$c} )
      . qq{">$c</a>\n};
}
print qq{<p/></div><!-- more cities -->\n};

print &footer( "cities" => \@city_list, 'city' => $city );
print "</div> <!-- bottom -->\n";
print $q->end_html;

