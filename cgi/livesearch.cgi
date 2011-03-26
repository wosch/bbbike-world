#!/usr/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# livesearch.cgi - bbbike.org live routing search

use CGI qw/-utf-8/;

use IO::File;
use JSON;
use Data::Dumper;

use strict;
use warnings;

my $logfile                   = '/var/log/lighttpd/bbbike.error.log';
my $max                       = 50;
my $only_production_statistic = 1;
my $debug                     = 1;

binmode \*STDOUT, ":raw";
my $q = new CGI;

sub is_mobile {
    my $q = shift;

    if (   $q->param('skin') && $q->param('skin') =~ m,^(m|mobile)$,
        || $q->virtual_host() =~ /^m\.|^mobile\.|^dev2/ )
    {
        return 1;
    }
    else {
        return 0;
    }
}

sub date_alias {
    my $date = shift;

    if ( $date eq 'today' ) {
        return substr( localtime(time), 4, 6 );
    }
    elsif ( $date eq 'yesterday' ) {
        return substr( localtime( time - 24 * 60 * 60 ), 4, 6 );
    }
    elsif ( $date =~ /^yesterday(\d)$/ ) {
        return substr( localtime( time - ( 24 * $1 ) * 60 * 60 ), 4, 6 );
    }
    else {
        return $date;
    }
}

sub logfiles {
    my $file    = shift;
    my @numbers = @_;

    my @files;
    for my $num (@numbers) {
        unshift @files, "$file.$num.gz";
    }
    return @files;
}

# extract URLs from web server error log
sub extract_route {
    my $file  = shift;
    my $max   = shift;
    my $devel = shift;
    my $date  = shift;

    my $host = $devel ? '(dev|devel|www)' : 'www';

    my @data;
    my %hash;
    my @files;
    push @files, &logfiles( $file, reverse 8 .. 20 ) if $max > 500;
    push @files, &logfiles( $file, 7, 6, 5 ) if $max > 100;
    push @files, &logfiles( $file, 4, 3 ) if $max > 50;
    push @files, &logfiles( $file, 2, 1 );
    push @files, $file;

    if ($date) {
        $date = &date_alias($date);

        eval { "foo" =~ /$date/ };
        if ($@) {
            warn "date failed: '$date'\n";
            $date = "";
        }
    }

    foreach my $file (@files) {
        next if !-f $file;

        my $fh;
        warn "Open $file...\n" if $debug >= 2;
        if ( $file =~ /\.gz$/ ) {
            open( $fh, "gzip -dc $file |" ) or die "open $file: $!\n";
        }
        else {
            open( $fh, $file ) or die "open $file: $!\n";
        }
        binmode $fh, ":raw";

        while (<$fh>) {
            next if !( / slippymap\.cgi: / || m, bbbike.cgi: http://, );

            next
              if $only_production_statistic
                  && !m, (slippymap|bbbike)\.cgi: http://$host.bbbike.org/,i;

            next if !/coords/;
            next if $date && !/$date/;

            my @list = split;
            my $url  = pop(@list);

            next if scalar(@data) > 20_000;    # keep memory usage low
            push( @data, $url );

        }
        close $fh;
    }

    return @data;
}

sub footer {
    my $q = new CGI;

    my $data = "";
    $q->delete('date');

    foreach my $number ( 10, 25, 50, 100, 250, 500, 1000 ) {
        if ( $number == $max ) {
            $data .= " | $number";
        }
        else {
            $q->param( "max", $number );
            $data .=
                qq, | <a title="max. $number routes" href=",
              . $q->url( -relative => 1, -query => 1 )
              . qq{">$number</a>\n};
        }
    }

    # date links: before yesterday | yesterday | today
    $q->param( "max",  "400" );
    $q->param( "date", "yesterday2" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">before yesterday</a>\n};

    $q->param( "max",  "400" );
    $q->param( "date", "yesterday" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">yesterday</a>\n};

    $q->param( "date", "today" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">today</a>\n};

    return <<EOF;
<div id="footer">
<div id="footer_top">
<a href="../">home</a> |
<a href="../cgi/area.cgi">covered area</a>
$data
</div>
</div>
<hr>

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
(&copy;) 2008-2011 <a href="http://wolfram.schneider.org">Wolfram Schneider</a> &amp; <a href="http://www.rezic.de/eserte">Slaven Rezi&#x107;</a> // <a href="http://www.bbbike.org">http://www.bbbike.org</a> <br >
  Map data by the <a href="http://www.openstreetmap.org/">OpenStreetMap</a> Project // <a href="http://wiki.openstreetmap.org/wiki/OpenStreetMap_License">OpenStreetMap License</a> <br >
<div id="footer_community">
</div>
</div>
EOF
}

sub route_stat {
    my $obj  = shift;
    my $city = shift;

    my ( $average, $median, $max ) = route_stat2( $obj, $city );
    return " average: ${average}km, median: ${median}km, max: ${max}km";
}

sub route_stat2 {
    my $obj  = shift;
    my $name = shift;

    my @routes;

    # one city
    if ($name) {
        @routes = @{ $obj->{$name} };
    }

    # all cities
    else {
        foreach my $key ( keys %$obj ) {
            if ( scalar( @{ $obj->{$key} } ) > 0 ) {
                push @routes, @{ $obj->{$key} };
            }
        }
    }

    my $average = 0;
    my $median  = 0;
    my $max     = 0;

    my @data;
    foreach my $item (@routes) {
        my $route_length = $item->{"route_length"};
        $average += $route_length;
        push @data, $route_length;
        $max = $route_length if $route_length > $max;
    }
    $average = $average / scalar(@routes);

    @data = sort { $a <=> $b } @data;
    my $count = scalar(@data);
    if ( $count % 2 ) {
        $median = $data[ int( $count / 2 ) ];
    }
    else {
        $median =
          ( $data[ int( $count / 2 ) ] + $data[ int( $count / 2 ) - 1 ] ) / 2;
    }

    # round all values to 100 meters
    $median  = int( $median * 10 + 0.5 ) / 10;
    $average = int( $average * 10 + 0.5 ) / 10;
    $max     = int( $max * 10 + 0.5 ) / 10;

    return ( $average, $median, $max );
}

##############################################################################################
#
# main
#

print $q->header( -charset => 'utf-8', -expires => '+30m' );

my $sensor = is_mobile($q) ? 'true' : 'false';
print $q->start_html(
    -title => 'BBBike @ World livesearch',
    -head  => $q->meta(
        {
            -http_equiv => 'Content-Type',
            -content    => 'text/html; charset=utf-8'
        }
    ),

    -style => {
        'src' => [
            "../html/devbridge-jquery-autocomplete-1.1.2/styles.css",
            "../html/bbbike.css"
        ]
    },
    -script => [
        { -type => 'text/javascript', 'src' => "../html/jquery-1.4.2.min.js" },
        {
            -type => 'text/javascript',
            'src' =>
"../html/devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete-min.js"
        },
        {
            -type => 'text/javascript',
            'src' =>
"http://maps.google.com/maps/api/js?sensor=$sensor&amp;language=de"
        },
        { -type => 'text/javascript', 'src' => "../html/maps3.js" }
    ]
);

print qq{<div id="routing"></div>\n};
print qq{<div id="BBBikeGooglemap" style="height:94%">\n};
print qq{<div id="map"></div>\n};

print <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    city = "dummy";
    bbbike_maps_init("terrain", [[43, 8],[57, 15]], "en", 1 );
  
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

if ( $q->param('max') ) {
    my $m = $q->param('max');
    $max = $m if $m > 0 && $m <= 2_000;
}

my $date = $q->param('date') || "";
my $stat = $q->param('stat') || "";
my @d = &extract_route( $logfile, $max, 0, $date );

print qq{<script type="text/javascript">\n};

my $city_center;
my $json = new JSON;
my $cities;
my %hash;
my $counter;
my $counter2 = 0;
my @route_display;
foreach my $url (@d) {
    my $qq = CGI->new($url);
    $counter2++;
    print $url, "\n" if $debug >= 2;

    next if !$qq->param('driving_time');

    my $coords = $qq->param('coords');
    next if !$coords;
    next if exists $hash{$coords};
    $hash{$coords} = 1;

    last if $counter++ >= $max;

    my @params = qw/city route_length driving_time startname zielname area/;
    push @params,
      qw/pref_cat pref_quality pref_specialvehicle pref_speed pref_ferry pref_unlit/;

    my $opt = { map { $_ => ( $qq->param($_) || "" ) } @params };

    $city_center->{ $opt->{'city'} } = $opt->{'area'};

    my $data = "[";
    foreach my $c ( split /!/, $coords ) {
        $data .= qq{'$c', };
    }
    $data =~ s/, $/]/;

    my $opt_json = $json->encode($opt);
    print qq{plotRoute(map, $opt_json, $data);\n};

    push( @{ $cities->{ $opt->{'city'} } }, $opt ) if $opt->{'city'};
    push @route_display, $url;
}

print "/* ", Dumper($cities),      " */\n" if $debug >= 2;
print "/* ", Dumper($city_center), " */\n" if $debug >= 2;

my @cities = sort keys %$cities;

# sort cities by hit counter, not by name
if ( $stat eq 'hits' ) {
    @cities =
      reverse sort { $#{ $cities->{$a} } <=> $#{ $cities->{$b} } }
      keys %$cities;
}

my $d = join(
    "<br/>",
    map {
            qq/<a title="area $_:/
          . &route_stat( $cities, $_ )
          . qq/" href="#" onclick="jumpToCity(\\'/
          . $city_center->{$_}
          . qq/\\')">$_ (/
          . scalar( @{ $cities->{$_} } ) . ")</a>"
      } @cities
);

#$d.= qq{<p><a href="javascript:flipMarkers(infoMarkers)">flip markers</a></p>};
if (@route_display) {
    my $unique_routes = scalar(@route_display);
    $d .= qq{<div id="livestatistic">};
    $d .= "<hr />";
    $d .=
qq{Number of unique routes: <span title="total routes: $counter2">$unique_routes<br />};

    my $qq = CGI->new($q);
    $qq->param( "stat", $stat eq 'hits' ? "name" : "hits" );
    $d .=
        qq{Sort cities by <a href="}
      . $qq->url( -relative => 1, -query => 1 ) . qq{">}
      . ( $stat ne 'hits' ? " hits " : " name " )
      . qq{</a><br />};
    $d .= "<p>Cycle Route Statistic<br/>" . &route_stat($cities) . "</p>";
    $d .= "</div>";
}

print qq{\n\$("div#routing").html('$d');\n\n};

my $city = $q->param('city') || "";
if ( $city && exists $city_center->{$city} ) {
    print qq[\njumpToCity('$city_center->{ $city }');\n];
}

print qq{\n</script>\n};

print
qq{<noscript><p>You must enable JavaScript and CSS to run this application!</p>\n</noscript>\n};
print "</div>\n";
print &footer;

print $q->end_html;

