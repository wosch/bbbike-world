#!/usr/local/bin/perl -T
# Copyright (c) 2009-2015 Wolfram Schneider, http://bbbike.org
#
# area.cgi - which areas are covered by bbbike.org

use CGI qw/-utf-8/;
use CGI::Carp;
use IO::File;
use IO::Dir;
use File::stat;
use JSON;
use Data::Dumper;
use Getopt::Long;

use lib qw(./world/bin ../world/bin ../bin);
use lib qw(../world/lib ../lib);
use BBBikeWorldDB;
use BBBikeLocale;
use BBBikeAnalytics;

use strict;
use warnings;

our $option = {
    'homepage_download' => 'http://download.bbbike.org/osm/',
    'homepage_bbbike'   => 'http://www.bbbike.org',

    'message_path' => "../world/etc/extract",
    'city_default' => 'Berlin',
    'debug'        => 1,

    'enable_google_analytics' => 1,
};

my $debug               = $option->{'debug'};
my $city_default        = $option->{'city_default'};
my $download_bbbike_org = $option->{'homepage_download'};
my $www_bbbike_org      = $option->{'homepage_bbbike'};

my $checksum_file = 'CHECKSUM.txt';

#binmode \*STDOUT, ":raw";
binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

# EOF config
###########################################################################

sub M { return BBBikeLocale::M(@_); };    # wrapper

my $q = new CGI;
if ( defined $q->param('debug') ) {
    $debug = int( $q->param('debug') );
}

sub load_javascript_libs {
    my @js = qw(
      OpenLayers/2.12/OpenLayers-min.js
      OpenLayers/2.12/OpenStreetMap.js
      extract-download.js
      area.js
    );

    my $javascript = join "\n",
      map { qq{<script src="/html/$_" type="text/javascript"></script>} } @js;

    return $javascript;
}

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
    <a href="javascript:resizeOtherCities(more_cities);">@{[ M("more cities") ]}</a>
  </div>
</div> <!-- footer -->
<hr/>

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
  (&copy;) 2008-2015 <a href="http://bbbike.org">BBBike.org</a> //
  Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors <br/>
  <a href="http://mc.bbbike.org/mc/">map compare</a> - <a href="http://extract.bbbike.org/">osm extract service</a>

  <div id="footer_community"></div>
</div> <!-- copyright -->
EOF
}

# file size in x.y MB
sub file_size {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $st->size / 1024 / 1024 ) / $scale;
        return $result . "M" if $result > 0;
    }

    return "0.1K";
}

sub mtime {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";
    return $st->mtime;
}

sub download_area {
    my $city    = shift || $city_default;
    my $offline = shift;
    my $q       = shift;

    my $osm_dir = "../osm";

    #die system("pwd > /tmp/a.pwd");
    my $dir = "$osm_dir/$city/";

    my $locale = BBBikeLocale->new( 'q' => $q );
    print $locale->language_links( 'with_separator' => 1 );

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
        my $has_checksum_file = 0;
        while ( defined( my $filename = $dh->read ) ) {
            next if $filename eq '.' || $filename eq '..';
            next if $filename eq 'HEADER.txt';
            next if $filename eq 'index.html';
            if ( $filename eq $checksum_file ) {
                $has_checksum_file = 1;
                next;
            }

            push @list, $filename;
        }
        $dh->close;

        my %hash = map { $_ => 1 } @list;
        my %ext_name = ( "md5" => "MD5", "sha256" => "SHA" );

        my $prefix = $offline ? "." : "$download_bbbike_org/osm/bbbike/$city";
        foreach my $file ( sort @list ) {
            my $date = localtime( &mtime("$dir/$file") );
            next if $file =~ /\.(md5|sha256|txt)$/;

            $data .=
              qq{<tr><td><a href="$prefix/$file" title="$date">$file</a>};

            my $data_checksum;
            if ( !$has_checksum_file ) {
                for my $ext ( "md5", "sha256" ) {
                    my $file_ext = "$file.$ext";
                    if ( exists $hash{$file_ext} ) {
                        $data_checksum .= ", " if $data_checksum;
                        $data_checksum .=
                          qq{<a href="$prefix/$file_ext" title="checksum $ext">}
                          . $ext_name{$ext}
                          . qq{</a>};
                    }
                }
                $data .= " (" . $data_checksum . ") " if $data_checksum;

            }

            if ( $file !~ /\.poly$/ ) {
                $data .=
                    qq{</td>}
                  . qq{<td align="right">}
                  . file_size("$dir/$file")
                  . qq{</td></tr>\n};
            }
        }
        if ($has_checksum_file) {
            my $date = localtime( &mtime("$dir/$checksum_file") );
            $data .= qq{<tr><td>}
              . qq{<a href="$prefix/$checksum_file" title="$date">$checksum_file</a></td></tr>\n};
        }
    }

    $data .= <<EOF;
</table>

<br/>
<a href="http://extract.bbbike.org/extract.html" target="_new">help</a> |
<a href="http://extract.bbbike.org/extract-screenshots.html" target="_new">screenshots</a> |
<a href="$www_bbbike_org/$city/" title="@{[ ("start bicycle routing for") ]} $city @{[ ("area") ]}">@{[ M("cycle routing") ]} $city</a>
<hr/>

<span class="city">
Start bicycle routing for <a style="font-size:x-large" href="$www_bbbike_org/$city/">$city</a>
</span>
EOF

    my $donate = qq{<p class="normalscreen" id="big_donate_image"><br/>}
      . qq{<a href="$www_bbbike_org/community.html"><img class="logo" height="47" width="126" src="/images/btn_donateCC_LG.gif"/></a>};
    $data .= $donate;

    $data .= qq{<div id="debug"></div>\n} if $debug >= 2;
    return $data;
}

sub header {
    my $q       = shift;
    my $offline = shift;
    my $city    = shift;

    my $sensor = 'true';
    my $base   = "";

    my @javascript = qw(/html/jquery/jquery-1.8.3.min.js);

    my $description =
"OSM extracts for $city in OSM, PBF, Garmin cycle map, Osmand, mapsforge, Navit and Esri shapefile format";
    return $q->start_html(
        -title => $description
        ,    #"BBBike @ World covered areas - osm extracts for $city",
        -head => [
            $q->meta(
                {
                    -http_equiv  => 'Content-Type',
                    -content     => 'text/html; charset=utf-8',
                    -description => $description . ". Service by BBBike.org",
                }
            ),
        ],

        -style => { 'src' => [ $base . "/html/bbbike.css" ] },
        -script =>
          [ map { { 'src' => ( /^http:/ ? $_ : $base . $_ ) } } @javascript ],
    );
}

sub js_jump {
    my $map_type = shift;

    return << 'EOF';
    
<script type="text/javascript">
    //<![CDATA[

    var city = "Berlin";
    var more_cities = false;
    var bbbike_db = [];

    $(document).ready(function() {
	download_init_map();
	init_map_resize();
    });

    //]]>
</script>

EOF
}

#
# local CSS overrides for this script
#
sub css_map {
    return <<EOF;
<style type="text/css">
div#BBBikeGooglemap, div#map_wrapper { left:  24.5em; }
div#sidebar, div#sidebar_left        { width: 24.5em; height: auto; }

span#language {
  position: inherit;
  padding-left: 20em;
  padding-top: 0.5em;
}
</style>

EOF
}

# place holder
sub js_map {
    my $map_type = shift;

    return <<EOF;
<script type="text/javascript">
</script>

EOF
}

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}          debug level, default: $debug
--offline               run offline
--city=name             given city name
--download=url          download site
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

$download_bbbike_org = "" if $offline;

my $database = "world/etc/cities.csv";
$database = "../$database" if -e "../$database";

my $db = BBBikeWorldDB->new( 'database' => $database, 'debug' => 0 );

print $q->header( -charset => 'utf-8', -expires => '+30m' ) if !$offline;

my $city_area = $q->param('city') || "";
my $city = $q->param('city') || $offline_city || $city_default;

print &header( $q, $offline, $city );
print &css_map;

print qq{<div id="sidebar">\n};
print qq{\t<div id="routes">}
  . &download_area( $city, $offline, $q )
  . qq{</div>\n};
print qq{</div> <!-- sidebar -->\n};

print qq{<div id="BBBikeGooglemap">\n};
print qq{<div id="map"></div>\n};

my $map_type = "hike_bike";
print &js_jump($map_type);
print &js_map;

print <<EOF;
<script type="text/javascript">
\$(document).ready(function() {
    city = "$city";

EOF

my $json = new JSON;
my $counter;
my @route_display;

my %hash = %{ $db->city };
my $city_center;
my @city_list;

print "    bbbike_db = [\n";
foreach my $city ( sort keys %hash ) {
    next if $city eq 'dummy' || $city eq 'bbbike';

    my $coord = $hash{$city}->{'coord'};

    # warn "c: $city\n"; warn Dumper($hash{$city}), "\n";

    my $opt;
    my ( $x1, $y1, $x2, $y2 ) = split /\s+/, $coord;

    $opt->{"area"}        = "$x1,$y1!$x2,$y2";
    $opt->{"city"}        = "$city";
    $city_center->{$city} = $opt->{"area"};

    my $opt_json = $json->encode($opt);
    printf( qq|\t["%s",[%s,%s,%s,%s]],\n|, $opt->{"city"}, $x1, $y1, $x2, $y2 );

    push @city_list, $city;
}
print <<EOF;
    ]; // var bbbike_db = [ ... ];
    
    plot_bbbike_areas(bbbike_db, $offline);
EOF

if ( $city && exists $hash{$city} ) {
    print qq[    jump_to_city(bbbike_db, "$city");\n\n];
}

print <<EOF;
});    // \$(document).ready();

</script>

<noscript>
<p>You must enable JavaScript and CSS to run this application!</p>
</noscript>

</div> <!-- map -->

<!-- ******************************************* -->
EOF

print qq{<div id="bottom">\n};
print qq{<div id="more_cities" style="display:none;">\n};
print qq{<div id="more_cities_inner">\n};
print qq{</div><!-- more cities inner -->\n};
print qq{</div><!-- more cities -->\n};

print &footer( "cities" => \@city_list, 'city' => $city );
print "</div> <!-- bottom -->\n";

# load javascript code late
print &load_javascript_libs;
print $option->{"enable_google_analytics"}
  ? BBBikeAnalytics->new( 'q' => $q )->google_analytics
  : "";

print $q->end_html;

1;
