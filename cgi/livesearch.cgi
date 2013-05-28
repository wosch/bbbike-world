#!/usr/local/bin/perl
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
#
# livesearch.cgi - bbbike.org live routing search

use CGI qw/-utf-8 unescape/;
use URI;
use URI::QueryParam;

use IO::File;
use JSON;
use Data::Dumper;
use Encode;

use strict;
use warnings;

my $logfile = '/var/log/lighttpd/bbbike.error.log';

#my $logfile                      = '../../tmp/lighttpd/bbbike.error.log';
my $max                          = 50;
my $only_production_statistic    = 1;
my $debug                        = 1;
my $logrotate_first_uncompressed = 1;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

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
        push @files, "$file.$num.gz";
    }
    return @files;
}

#
# estimate the usage for a 24 hour period. Based on the google analytics
# usage statistics for April 2011
#
sub estimated_daily_usage {
    my $counter = shift;

    $counter = 1 if $counter <= 0;

# hour -> percentage
#
# total number of searches:
# zcat bbbike.error.log.?.gz | awk '{ if ($7 ~ /^URL:/) { print $4 } }'| perl -npe 's,:.*,,' | wc -l
#
# in percent per hour
# zcat bbbike.error.log.?.gz | awk '{ if ($7 ~ /^URL:/) { print $4 } }'| perl -npe 's,:.*,,' | sort | uniq -c | sort -n -k 2 | awk '{ printf("%d => %2.2f,\n", $2, $1 * 100 / 57294)}'
#
    my $hourly_usage = {
        0  => 1.35,
        1  => 1.23,
        2  => 1.29,
        3  => 1.39,
        4  => 1.47,
        5  => 2.11,
        6  => 3.04,
        7  => 5.77,
        8  => 6.17,
        9  => 6.71,
        10 => 7.40,
        11 => 6.29,
        12 => 6.01,
        13 => 6.96,
        14 => 5.37,
        15 => 6.26,
        16 => 4.29,
        17 => 4.90,
        18 => 3.83,
        19 => 4.29,
        20 => 4.29,
        21 => 6.36,
        22 => 2.00,
        23 => 1.23,
    };

    my ( $hour, $min ) = ( localtime(time) )[ 2, 1 ];
    my $now = 0;

    foreach my $key ( keys %$hourly_usage ) {
        if ( $key < $hour ) {
            $now += $hourly_usage->{$key};
        }
        elsif ( $key == $hour ) {
            $now += $hourly_usage->{$key} * $min / 60;
        }
    }

    return int( $counter * 100 / $now );
}

sub is_production {
    my $q = shift;

    return 1 if -e "/tmp/is_production";
    return $q->virtual_host() =~ /^www\.bbbike\.org$/i ? 1 : 0;
}

# extract URLs from web server error log
sub extract_route {
    my $file   = shift;
    my $max    = shift;
    my $devel  = shift;
    my $date   = shift;
    my $unique = shift;

    warn "extract route: file: $file, max: $max, date: $date\n" if $debug;

    my $host = $devel ? '(dev|devel|www)' : '(www|api)';

    # read more data then requested, expect some duplicated URLs
    my $duplication_factor = 1.5;

    my @data_all;
    my @files = $file;
    push @files,
      $logrotate_first_uncompressed ? "$file.1" : &logfiles( $file, 1 );
    push @files, &logfiles( $file, 2 .. 20 );
    push @files, &logfiles( $file, 21 .. 100 ) if $max > 2_000;

    if ($date) {
        $date = &date_alias($date);

        warn "Use date: '$date'\n" if $debug;

        eval { "foo" =~ /$date/ };
        if ($@) {
            warn "date failed: '$date'\n";
            $date = "";
        }
    }

    my %hash;

    # read newest log files first
    foreach my $file (@files) {
        my @data;

        next if !-f $file;

        my $fh;
        warn "Open $file ...\n" if $debug >= 1;
        if ( $file =~ /\.gz$/ ) {
            open( $fh, "gzip -dc $file |" ) or die "open $file: $!\n";
        }

        else {
            open( $fh, $file ) or die "open $file: $!\n";
        }

        binmode $fh, ":raw";
        while (<$fh>) {
            next if !/;pref_seen=[12]/;

            if (   !m, (bbbike|[A-Z][a-zA-Z]+)\.cgi: (URL:)?http://,
                && !/ slippymap\.cgi: / )
            {
                next;
            }

            next
              if $only_production_statistic
                  && !
m, (slippymap|bbbike|[A-Z][a-zA-Z]+)\.cgi: (URL:)?http://$host.bbbike.org/,i;
            next if !/coords/;
            next if $date && !/$date/;
            next if /[;&]cache=1/;

            # binmode dies, use Encode module instead
            # $_ = Encode::decode("utf8", $_, Encode::FB_QUIET);

            my @list = split;
            my $url  = pop(@list);

            $url =~ s/^URL://;

            # keep memory usage low
            pop @data if scalar(@data) > 15_000;

            # more aggresive duplication check, for better performance
            next if $unique && $hash{$url}++;

            # newest entries first
            unshift @data, $url;
        }
        close $fh;
        push @data_all, @data;

        # enough data
        last if scalar(@data_all) > $max * $duplication_factor;

        # no new data, stop
        if ( $date && scalar(@data_all) && scalar(@data) == 0 ) {
            warn "Got no new data for date '$date', stop here\n" if $debug;
            last;
        }
    }

    warn "URLs: ", scalar(@data_all), ", factor: $duplication_factor\n"
      if $debug;
    return @data_all;
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
    $q->param( "max",  "700" );
    $q->param( "date", "yesterday2" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">before yesterday</a>\n};

    $q->param( "max",  "700" );
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

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
<hr>
(&copy;) 2008-2013 <a href="http://bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
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
    $average = $average / scalar(@routes) if scalar(@routes);

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

# statistic with google maps
sub statistic_maps {
    my $q = shift;

    print $q->header( -charset => 'utf-8', -expires => '+30m' );

    my $sensor = is_mobile($q) ? 'true' : 'false';
    print $q->start_html(
        -title => 'BBBike @ World livesearch',
        -head  => [
            $q->meta(
                {
                    -http_equiv => 'Content-Type',
                    -content    => 'text/html; charset=utf-8'
                }
            ),
            $q->meta(
                { -name => "robots", -content => "nofollow,noindex,noarchive" }
            )
        ],

        -style  => { 'src' => ["../html/bbbike.css"] },
        -script => [
            { 'src' => "http://www.google.com/jsapi?hl=en" },
            {
                'src' =>
"http://maps.googleapis.com/maps/api/js?v=3.9&sensor=false&language=en&libraries=weather,panoramio"
            },
            { 'src' => "/html/bbbike-js.js" }
        ],
    );

    print qq{<div id="routes"></div>\n};
    print qq{<div id="BBBikeGooglemap" style="height:94%">\n};
    print qq{<div id="map"></div>\n};

    print <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    city = "dummy";
    bbbike_maps_init("terrain", [[43, 8],[57, 15]], "en", true, "eu" );
  
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
        $max = $m if $m > 0 && $m <= 5_000;
    }

    my $date = $q->param('date') || "";
    my $stat = $q->param('stat') || "name";
    my @d = &extract_route( $logfile, $max, &is_production($q), $date );

    #print join ("\n", @d); exit;

    print qq{<script type="text/javascript">\n};

    my $city_center;
    my $json = new JSON;
    my $cities;
    my $counter;
    my $counter2 = 0;
    my @route_display;

    sub Param {
        my $q   = shift;
        my $key = shift;
        my @val = $q->param($_) || "";

        # XXX: WTF? run decode N times!!!
        eval {
            @val = map { Encode::decode( "utf8", $_, Encode::FB_QUIET ) } @val;
        };

        return @val;
    }

    my %hash;
    foreach my $url (@d) {

        # CGI->new() is sooo slow
        my $qq = CGI->new($url);

        $counter2++;
        warn $url, "\n" if $debug >= 2;

        #next if !$qq->param('driving_time');

        my $coords = $qq->param('coords');
        next if !$coords;
        next if exists $hash{$coords};
        $hash{$coords} = 1;

        last if $counter++ >= $max;

        my @params =
          qw/city route_length driving_time startname zielname vianame area/;
        push @params,
          qw/pref_cat pref_quality pref_specialvehicle pref_speed pref_ferry pref_unlit viac/;

        my $opt = { map { $_ => ( Param( $qq, $_ ) ) } @params };

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
    warn "duplicates: ", scalar( keys %hash ), "\n";

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
    $d .= qq{<div id="livestatistic">};
    if (@route_display) {
        my $unique_routes = scalar(@route_display);
        $d .= "<hr />";
        $d .=
qq{Number of unique routes: <span title="total routes: $counter2, cities: }
          . scalar(@cities)
          . qq{">$unique_routes<br />};

        if ( !is_production($q) && $date eq 'today' ) {
            $d .=
                "<p>Estimated usage today: "
              . &estimated_daily_usage($unique_routes) . "/"
              . &estimated_daily_usage($counter2) . "</p>";
        }
        my $qq = CGI->new($q);
        $qq->param( "stat", $stat eq 'hits' ? "name" : "hits" );
        $d .=
            qq{Sort cities by <a href="}
          . $qq->url( -relative => 1, -query => 1 ) . qq{">}
          . ( $stat ne 'hits' ? " hits " : " name " )
          . qq{</a><br />};
        $d .= "<p>Cycle Route Statistic<br/>" . &route_stat($cities) . "</p>";
    }
    else {
        $d .= "No routes found";
    }
    $d .= "</div>";

    print qq{\n\$("div#routes").html('$d');\n\n};

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
}

# basic statistic, no maps
sub statistic_basic {
    my $q                = shift;
    my $most_used_cities = 10;

    my $max = 700;
    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 15_000;
    }

    my $date = $q->param('date') || "today";
    my @d = &extract_route( $logfile, $max, &is_production($q), $date );

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

        #next if !$qq->param('driving_time');

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

        push( @{ $cities->{ $opt->{'city'} } }, $opt ) if $opt->{'city'};
        push @route_display, $url;
    }

    print $q->header( -charset => 'utf-8', -expires => '+30m' );
    print $q->start_html( -title => 'BBBike @ World livesearch' );

    my @cities        = sort keys %{$cities};
    my $unique_routes = scalar(@route_display);

    print "<p>City count: ", scalar(@cities),
      ", unique routes: $unique_routes, ", "total routes: $counter2</p>\n";

    if ( $unique_routes > 20 && !is_production($q) && $date eq 'today' ) {
        print "<p>Estimated usage today: "
          . &estimated_daily_usage($unique_routes) . "/"
          . &estimated_daily_usage($counter2) . "</p>";
    }

    print "<p>Cycle Route Statistic<br/>" . &route_stat($cities) . "</p>\n";

    if ( $most_used_cities && scalar(@cities) > 20 ) {
        print "<hr />\n";
        my @cities2 =
          reverse sort { $#{ $cities->{$a} } <=> $#{ $cities->{$b} } }
          keys %$cities;

        if ( scalar(@cities2) >= $most_used_cities ) {
            @cities2 = @cities2[ 0 .. ( $most_used_cities - 1 ) ];
        }
        print join( "<br/>\n",
            map { $_ . " (" . scalar( @{ $cities->{$_} } ) . ")" } @cities2 );
    }

    print "<hr />\n";
    print join( "<br/>\n",
        map { $_ . " (" . scalar( @{ $cities->{$_} } ) . ")" } @cities );

    # footer
    print qq{<br/><br/>\n<a href="../">home</a>\n};

    $q->param( "date", "yesterday" );
    print qq{ | <a href="} . $q->url( -query => 1 ) . qq{">yesterday</a>\n};
    $q->param( "date", "today" );
    print qq{ | <a href="} . $q->url( -query => 1 ) . qq{">today</a>\n};
    print "<hr />\n";
    print
      qq{Copyright (c) 2011-2013 <a href="http://bbbike.org">BBBike.org</a>\n};
    print "<br/>\n" . localtime() . "\n";
}

sub dump_url_list {
    my $q = shift;

    my $max = 1000;
    my @d = &extract_route( $logfile, $max, 0, "" );

    my $cities;
    my %hash;
    my %hash2;
    my $counter = 0;
    my @route_display;

    my $limit = $q->param("max") || 50;
    $limit = 20 if $limit < 0 || $limit > 500;

    print $q->header( -charset => 'utf-8', -type => 'text/plain' );

    foreach my $url (@d) {
        $url =~ s/;/&/g;    # bug in URI
        my $u = URI->new($url);

        next if !$u->query_param('driving_time');

        my $coords = $u->query_param('coords');
        next if !$coords;
        next if exists $hash{$coords};
        $hash{$coords} = 1;

        $u->query_param_delete('coords');
        $u->query_param_delete('area');
        $u->query_param_delete('driving_time');

        $u->query_param( 'cache', 1 );

        my $city = $u->query_param("city");

        if ( !exists $hash2{$city} ) {
            $hash2{$city} = 1;

            # pref_cat=N1;pref_quality=Q2;
            $u->query_param( 'pref_cat',     "" );
            $u->query_param( 'pref_quality', "" );
            push @route_display, $u->as_string;

            $u->query_param( 'pref_cat',     "N1" );
            $u->query_param( 'pref_quality', "Q2" );
            push @route_display, $u->as_string;
        }

        last if scalar(@route_display) >= $limit * 2;
    }

    print join "\n", @route_display;
    print "\n";
}

##############################################################################################
#
# main
#

my $ns = $q->param("namespace") || $q->param("ns") || "";

# plain statistic
if ( $ns =~ /^stat/ || $ns =~ /^(ascii|text|plain)$/ ) {
    &statistic_basic($q);
}

# URL list
elsif ( $ns =~ /^cache/ ) {
    &dump_url_list($q);
}

# html statistic with google maps
else {
    &statistic_maps($q);
}

