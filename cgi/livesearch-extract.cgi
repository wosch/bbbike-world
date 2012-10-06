#!/usr/local/bin/perl
# Copyright (c) 2012 Wolfram Schneider, http://bbbike.org
#
# livesearch-extract.cgi - extractbbbike.org live extracts

use CGI qw/-utf-8 unescape escapeHTML/;
use URI;
use URI::QueryParam;

use IO::File;
use IO::Dir;
use JSON;
use Data::Dumper;
use Encode;
use File::stat;

use strict;
use warnings;

my $log_dir = '/var/cache/extract/trash';

my $max                       = 25;
my $only_production_statistic = 1;
my $debug                     = 1;
my $default_date              = "";
my $timezone                  = 'UTC';    # json log runs in UTC

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $q = new CGI;

# google mobile maps
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

# swap day and month: mon day -> day mon
sub date_alias {
    my $date = shift;
    my $d    = _date_alias($date);
    my @a    = split( " ", $d );
    return "$a[1] $a[0]";
}

sub _date_alias {
    my $date = shift;

    sub _localtime {
        my $time = shift;
        return $timezone eq 'UTC' ? gmtime($time) : localtime($time);
    }

    if ( $date eq 'today' ) {
        return substr( _localtime(time), 4, 6 );
    }
    elsif ( $date eq 'yesterday' ) {
        return substr( _localtime( time - 24 * 60 * 60 ), 4, 6 );
    }
    elsif ( $date =~ /^yesterday(\d)$/ ) {
        return substr( _localtime( time - ( 24 * $1 ) * 60 * 60 ), 4, 6 );
    }
    else {
        return $date;
    }
}

sub is_production {
    my $q = shift;

    return 1 if -e "/tmp/is_production";
    return $q->virtual_host() =~ /^www\.bbbike\.org$/i ? 1 : 0;
}

# extract areas from trash can
sub extract_areas {
    my $log_dir = shift;
    my $max     = shift;
    my $devel   = shift;
    my $date    = shift;
    my $unique  = shift;

    warn "extract route: log dir: $log_dir, max: $max, date: $date\n" if $debug;

    my %hash;
    my $dh = IO::Dir->new($log_dir) or die "open $log_dir: $!\n";

    while ( defined( my $file = $dh->read ) ) {
        next if $file !~ /\.json$/;

        my $f = "$log_dir/$file";
        my $st = stat($f) or die "stat $f: $!\n";
        $hash{$f} = $st->mtime;
    }
    $dh->close;

    my @list = reverse sort { $hash{$a} <=> $hash{$b} } keys %hash;
    if ($date) {
        $date = &date_alias($date);

        warn "Use date: '$date'\n" if $debug;

        eval { "foo" =~ /$date/ };
        if ($@) {
            warn "date failed: '$date'\n";
            $date = "";
        }
    }

    my @area;
    my $json = new JSON;
    for ( my $i = 0 ; $i < scalar(@list) && $i < $max ; $i++ ) {
        my $file = $list[$i];
        my $fh = new IO::File $file, "r" or die "open $file: $!\n";
        binmode $fh, ":utf8";

        my $data = "";
        while (<$fh>) {
            $data .= $_;
        }

        my $obj = $json->decode($data);
        next if !exists $obj->{'date'};

        #warn "xxx: ", Dumper($obj);
        next if $date && $obj->{'date'} !~ /$date/;

        push @area, $obj;
    }

    return @area;
}

sub footer {
    my $q = new CGI;

    my $data = "";
    $q->delete('date');

    foreach my $number ( 10, 25, 50, 100, 250 ) {
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
    $q->param( "max",  "350" );
    $q->param( "date", "yesterday2" );
    $data .=
        qq{ | <a href="}
      . $q->url( -relative => 1, -query => 1 )
      . qq{">before yesterday</a>\n};

    $q->param( "max",  "350" );
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
<a href="../">home</a>
$data
</div>
</div>

<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
<hr>
(&copy;) 2008-2012 <a href="http://bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="http://www.openstreetmap.org/" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
<div id="footer_community">
</div>
</div>
EOF
}

sub css_map {
    return <<EOF;
<style type="text/css">
div#BBBikeGooglemap, div#nomap { left: 18em; }
div#sidebar { width: 17em; }
</style>

EOF
}

# statistic with google maps
sub statistic {
    my $q = shift;

    my $ns = $q->param("namespace") || $q->param("ns") || "";
    $ns = "text" if $ns =~ /^(text|ascii|plain)$/;

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

        -style  => { 'src' => ["../html/bbbike.css"] },
        -script => [
            { 'src' => "http://www.google.com/jsapi?hl=en" },
            {
                'src' =>
"http://maps.googleapis.com/maps/api/js?sensor=false&amp;language=en"
            },
            { 'src' => "../html/bbbike-js.js" }
        ],
    );

    print &css_map;
    print qq{<div id="sidebar"></div>\n};
    if ( $ns ne 'text' ) {
        print qq{<div id="BBBikeGooglemap" style="height:92%">\n};
        print qq{<div id="map"></div>\n};
    }
    else {
        print qq{<div id="nomap" style="height:92%">\n};
    }

    print <<EOF;
    <script type="text/javascript">
    //<![CDATA[

    city = "dummy";
    bbbike_maps_init("mapnik_bw", [[30, 30],[59, -10]], "en", true, "eu" );
  
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

    my $date = $q->param('date') || $default_date;
    my $stat = $q->param('stat') || "name";
    my @d = &extract_areas( $log_dir, $max * 1.5, &is_production($q), $date );

    #print Dumper(\@d); exit;

    print qq{<script type="text/javascript">\n};

    my $city_center;
    my $cities;
    my $counter2 = 0;
    my @route_display;

    my $json = new JSON;
    my %hash;
    my $counter       = 0;
    my $counter_total = 0;
    my @cities;
    my %format;

    foreach my $o (@d) {
        $counter_total++;
        $format{ $o->{"format"} }++;

        my $data =
qq|$o->{"sw_lng"},$o->{"sw_lat"}!$o->{"ne_lng"},$o->{"ne_lat"},$o->{"format"}|;
        next if $hash{$data}++;
        last if $counter++ >= $max;

        my $city = escapeHTML( $o->{"city"} );
        my $opt =
          { "city" => $city, "area" => $data, "format" => $o->{"format"} };
        $city_center->{$city} = $data;
        push @cities, $opt;

        my $opt_json = $json->encode($opt);

       # plotRoute(map, {"city":"Aachen","area":"5.88,50.60!6.58,50.99"}, "[]");
        print qq{plotRoute(map, $opt_json, "[]");\n};

    }
    warn "duplicates: ", scalar( keys %hash ), "\n";

    #my $d .= "count: @{[ $counter - 1 ]}</div>";

    my $d = join(
        "<br/>",
        map {
                qq/<a title="format $_->{'format'}/
              . qq/" href="#" onclick="jumpToCity(\\'/
              . $city_center->{ $_->{'city'} }
              . qq,\\')">$_->{'city'}</a>,
          } sort { $a->{'city'} cmp $b->{'city'} } @cities
    );
    $d .= "<hr/>unique total: " . scalar(@cities);
    if ( scalar(@cities) < $counter_total && $counter_total < $max ) {
        $d .= "<br/>total: $counter_total";
    }

    $d .= join "<br/>", "", "",
      map          { "$_ ($format{$_})" }
      reverse sort { $format{$a} <=> $format{$b} } keys %format;

    if ( $date ne "" ) {
        $d .= "<br/>the localtime is in UTC";
    }

    print qq{\n\$("div#sidebar").html('$d');\n\n};

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

##############################################################################################
#
# main
#

&statistic($q);

