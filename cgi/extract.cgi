#!/usr/local/bin/perl -T
# Copyright (c) 2011-2013 Wolfram Schneider, http://bbbike.org
#
# extract.cgi - extracts areas in a batch job
#
# spool area
#   /incoming   - request to extract an area, email sent out to user
#   /confirmed  - user confirmed request by clicking on a link in the email
#   /running    - the request is running
#   /osm        - the request is done, files are saved for further usage
#   /download   - where the user can download the files, email sent out
#  /jobN.pid    - running jobs
#
# todo:
# - xxx
#

use CGI qw/-utf8 unescape escapeHTML/;
use CGI::Carp;
use IO::File;
use JSON;
use Data::Dumper;
use Encode qw/encode_utf8/;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use GIS::Distance::Lite;
use HTTP::Date;
use Math::Polygon::Calc;
use Math::Polygon::Transform;

use strict;
use warnings;

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/var/cache/extract';

# sent out emails as
my $email_from = 'BBBike Admin <bbbike@bbbike.org>';

our $option = {
    'homepage'        => 'http://download.bbbike.org/osm/extract',
    'script_homepage' => 'http://extract.bbbike.org',

    'max_extracts'              => 50,
    'default_format'            => 'osm.pbf',
    'city_name_optional'        => 0,
    'city_name_optional_coords' => 1,
    'max_skm'                   => 24_000_000,    # max. area in square km
    'max_size'                  => 768_000,       # max area in KB size

    # request to confirm request with a click on an URL
    # -1: do not check email, 0: check email address, 1: sent out email
    'confirm' => 0,

    # max count of gps points for a polygon
    'max_coords' => 256 * 256,

    'enable_polygon'      => 1,
    'email_valid_mxcheck' => 1,
};

my $formats = {
    'osm.pbf' => 'Protocolbuffer Binary (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",

    'shp.zip'            => "Shapefile (Esri)",
    'garmin-osm.zip'     => "Garmin OSM",
    'garmin-cycle.zip'   => "Garmin Cycle",
    'garmin-leisure.zip' => "Garmin Leisure",
    'navit.zip'          => "Navit",
    'obf.zip'            => "Osmand (OBF)",
    'o5m.gz'             => "o5m gzip'd",
    'o5m.bz2'            => "o5m bzip'd",
};

#
# Parse user config file.
# This allows to override standard config values
#
my $config_file = "../.bbbike-extract.rc";
if ( -e $config_file ) {
    require $config_file;
}

my $spool = {
    'incoming'  => "$spool_dir/incoming",
    'confirmed' => "$spool_dir/confirmed",
    'running'   => "$spool_dir/running",
};

my $max_skm = $option->{'max_skm'};

# use "GET" or "POST" for forms
my $request_method = "GET";

######################################################################
# helper functions
#

sub header {
    my $q    = shift;
    my %args = @_;
    my $type = $args{-type} || "";

    my @onload;
    my @cookie;
    my @css = "../html/extract.css";

    if ( $type eq 'homepage' ) {
        @onload = ( -onLoad, 'init();' );
    }
    else {
        push @css, "../html/extract-center.css";
    }

    # store last used selected in cookies for further usage
    if ( $type eq 'check_input' ) {
        my @cookies;
        my @cookie_opt = (
            -path    => $q->url( -absolute => 1, -query => 0 ),
            -expires => '+30d'
        );

        push @cookies,
          $q->cookie(
            -name  => 'format',
            -value => $q->param("format"),
            @cookie_opt
          );
        push @cookies,
          $q->cookie(
            -name  => 'email',
            -value => $q->param("email"),
            @cookie_opt
          );

        push @cookie, -cookie => \@cookies;
    }

    return $q->header( -charset => 'utf-8', @cookie ) .

      $q->start_html(
        -title => 'Planet.osm extracts | BBBike.org',
        -head  => [
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
'Extracts OpenStreetMap areas in OSM, PBF, Garmin, Osmand or Esri shapefile format'
                }
            )
        ],
        -style => { 'src' => \@css, },

        # -script => [ map { { 'src' => $_ } } @javascript ],
        @onload,
      );
}

# see ../html/extract.js
sub map {

    return <<EOF;
</div> <!-- sidebar_left -->

<div id="content" class="site_index">
    <!-- define a DIV into which the map will appear. Make it take up the whole window -->
     <div id="map"></div>
</div><!-- content -->

EOF

}

sub manual_area {
    my $img_prefix = '/html/OpenLayers/2.12/theme/default/img';

    return <<EOF;
 <div id="manual_area">
  <div id="sidebar_content">
    <span class="export_hint">
      <a id="drag_box">Manually select a different area</a>
      <a class='tools-helptrigger' href='/extract-dialog-select-area.html'><img src='/html/help-16px.png' alt="" /></a><br/>
    </span> 
    <span id="square_km"></span>

    <div id="polygon_controls" style="display:none">
	<input id="createVertices" type="radio" name="type" onclick="polygon_update()" />
	<label for="createVertices">add points to polygon
	<img src="$img_prefix/add_point_on.png" alt=""/>  <a class='tools-helptrigger' href='/extract-dialog-polygon.html'><img src='/html/help-16px.png' alt="" /></a><br/>
	</label>

	<input id="rotate" type="radio" name="type" onclick="polygon_update()" />
	<label for="rotate">resize or drag polygon
	<img src="$img_prefix/move_feature_on.png" alt="move feature"/>
	</label>
    </div>

  </div> <!-- sidebar_content -->
 </div><!-- manual_area -->
EOF
}

sub footer_top {
    my $q    = shift;
    my %args = @_;
    my $css  = $args{'css'} || "";

    my $locate =
      $args{'map'}
      ? '<br/><a href="javascript:locateMe()">where am I?</a>'
      : "";
    $locate = "";    # disable

    if ($css) {
        $css = "\n<style>$css</style>\n";
    }

    my $donate = qq{<p class="normalscreen" id="big_donate_image">}
      . qq{<a href="/community.html"><img class="logo" height="47" width="126" src="/images/btn_donateCC_LG.gif" alt="donate"/></a></p>};

    return <<EOF;
  $donate
  $css
  <div id="footer_top">
    <a href="../">home</a> |
    <a href="../extract.html">help</a> |
    <a href="http://download.bbbike.org/osm/">download</a> |
    <a href="/cgi/livesearch-extract.cgi">livesearch</a> |
    <a href="../community.html#donate">donate</a> $locate
  </div>
EOF
}

sub footer {
    my $q    = shift;
    my %args = @_;

    my $analytics = &google_analytics;
    my $url = $q->url( -relative => 1 );

    my $locate =
      $args{'map'} ? ' | <a href="javascript:locateMe()">where am I?</a>' : "";

    my @js =
      qw(OpenLayers/2.12/OpenLayers-min.js OpenLayers/2.12/OpenStreetMap.js jquery/jquery-1.7.1.min.js
      jquery/jqModal-2009.03.01-r14.js jquery/jquery-ui-1.9.1.custom.min.js extract.js);
    my $javascript = join "\n",
      map { qq{<script src="../html/$_" type="text/javascript"></script>} } @js;

    return <<EOF;

<div id="footer">
  @{[ &footer_top($q, 'map' => $args{'map'}, 'css' => $args{'css'} ) ]}
  <div id="copyright">
  <hr/>
    (&copy;) 2013 <a href="http://www.bbbike.org">BBBike.org</a>
    by <a href="http://wolfram.schneider.org">Wolfram Schneider</a><br/>
    Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
  <div id="footer_community"></div>
  </div>
</div>

</div></div></div> <!-- layout -->

$javascript
$analytics
<script type="text/javascript">
  jQuery('#pageload-indicator').hide();
</script>

</body>
</html>
EOF
}

sub social_links {
    <<EOF;
    <span id="social">
    <a href="http://www.facebook.com/BBBikeWorld" target="_new"><img class="logo" width="16" height="16" src="/images/facebook-t.png" alt="" title="BBBike on Facebook" /></a>
    <a href="http://twitter.com/BBBikeWorld" target="_new"><img class="logo" width="16" height="16" src="/images/twitter-t.png" alt="" title="Follow us on twitter.com/BBBikeWorld" /></a>
    <a class="gplus" onmouseover="javascript:google_plusone();" ><img alt="" src="/images/google-plusone-t.png"/></a><g:plusone href="http://extract.bbbike.org" size="small" count="false"></g:plusone>
    <a href="http://www.bbbike.org/feed/bbbike-world.xml"><img class="logo" width="14" height="14" title="What's new on BBBike.org" src="/images/rss-icon.png" alt="" /></a>
    &nbsp;
    </span>
EOF
}

sub google_analytics {
    return <<EOF;
<script type="text/javascript">
//<![CDATA[
  var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
  document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
  //]]>
  </script><script type="text/javascript">
//<![CDATA[
  try {
  var pageTracker = _gat._getTracker("UA-286675-19");
  pageTracker._trackPageview();
  } catch(err) {}
  //]]>
  </script>
EOF
}

sub message {
    return <<EOF;
<span id="noscript"><noscript>Please enable JavaScript in your browser. Thanks!</noscript></span>
@{[ &social_links ]}
<span id="toolbar">
BBBike extract -
</span> 
<span id="tools-titlebar">
 <span id="tools-help"><a class='tools-helptrigger' href='/extract-mini.html'><span>about</span></a></span>
 <span id="pageload-indicator">&nbsp;<img src="/html/indicator.gif" alt="" title="Loading JavaScript libraries" /></span>
 <span class="jqmWindow jqmWindowLarge" id="tools-helpwin"></span>
</span>

<span id="debug"></span>
EOF
}

sub layout {
    my $q    = shift;
    my %args = @_;

    my $data = <<EOF;
  <div id="all">

    <div id="border">
      <div id="main">
        <!-- <div id="top"></top> -->
EOF

    my $id = $args{'check_input'} ? 'result' : "sidebar_left";
    $data .= qq{    <div id="$id">\n};

    return $data;
}

# call back URL
sub script_url {
    my $option = shift;
    my $obj    = shift;

    my $coords = "";
    my $city = $obj->{'city'} || "";

    if ( scalar( @{ $obj->{'coords'} } ) > 100 ) {
        $coords = "0,0,0";
        warn "Coordinates to long for URL, skipped\n" if $debug >= 2;
    }
    else {
        $coords = join '|', ( map { "$_->[0],$_->[1]" } @{ $obj->{'coords'} } );
    }

    my $script_url = $option->{script_homepage} . "/?";
    $script_url .=
"sw_lng=$obj->{sw_lng}&sw_lat=$obj->{sw_lat}&ne_lng=$obj->{ne_lng}&ne_lat=$obj->{ne_lat}";
    $script_url .= "&format=$obj->{'format'}";
    $script_url .= "&coords=" . CGI::escape($coords) if $coords ne "";
    $script_url .= "&city=" . CGI::escape($city) if $city ne "";

    return $script_url;
}

# fewer points, max. 1024 points in a polygon
sub normalize_polygon {
    my $poly = shift;
    my $max = shift || 1024;

    my $same = '0.001';
    warn "Polygon input: " . Dumper($poly) if $debug >= 3;

    # max. 10 meters accuracy
    my @poly = polygon_simplify( 'same' => $same, @$poly );

    # but not more than N points
    if ( scalar(@poly) > $max ) {
        warn "Resize 0.01 $#poly\n" if $debug >= 1;
        @poly = polygon_simplify( 'same' => 0.01, @$poly );
        if ( scalar(@poly) > $max ) {
            warn "Resize $max points $#poly\n" if $debug >= 1;
            @poly = polygon_simplify( max_points => $max, @poly );
        }
    }

    return @poly;
}

# get coordinates from a string or a file handle
sub extract_coords {
    my $coords = shift;

    if ( ref $coords ne "" ) {
        my $fh_file = $coords;

        binmode $fh_file, ":raw";
        local $/ = "";
        my $data = <$fh_file>;
        undef $fh_file;
        $coords = $data;
    }

    return $coords;
}

#
# upload poly file to extract an area:
#
# curl -sSf -F "submit=extract" -F "email=nobody@gmail.com" -F "city=Karlsruhe" -F "format=osm.pbf" \
#   -F "coords=@karlsruhe.poly" http://extract.bbbike.org | lynx -nolist -dump -stdin
#
sub parse_coords {
    my $coords = shift;

    if ( $coords =~ /\|/ ) {
        return parse_coords_string($coords);
    }
    elsif ( $coords =~ /\[/ ) {
        return parse_coords_json($coords);
    }
    elsif ( $coords =~ /END/ ) {
        return parse_coords_poly($coords);
    }
    else {
        warn "No known coords system found: '$coords'\n";
        return ();
    }
}

sub parse_coords_json {
    my $coords = shift;

    my $perl;
    eval { $perl = decode_json($coords) };
    if ($@) {
        warn "decode_json: $@ for $coords\n";
        return ();
    }

    return @$perl;
}

sub parse_coords_poly {
    my $coords = shift;

    my @list = split "\n", $coords;
    my @data;
    foreach (@list) {
        next if !/^\s+/;
        chomp;

        my ( $lng, $lat ) = split;
        push @data, [ $lng, $lat ];
    }

    return @data;
}

sub parse_coords_string {
    my $coords = shift;
    my @data;

    my @coords = split /\|/, $coords;

    foreach my $point (@coords) {
        my ( $lng, $lat ) = split ",", $point;
        push @data, [ $lng, $lat ];
    }

    return @data;
}

#
# validate user input
# reject wrong values
#
sub check_input {
    my %args = @_;

    my $q = $args{'q'};
    our $qq = $q;

    print &header( $q, -type => 'check_input' );
    print &layout( $q, 'check_input' => 1 );

    our $error = 0;

    sub error {
        my $message   = shift;
        my $no_escape = shift;

        $error++;

        print "<p>", $no_escape ? $message : escapeHTML($message), "</p>\n";
    }

    sub is_lng { return is_coord( shift, 180 ); }
    sub is_lat { return is_coord( shift, 90 ); }

    sub is_coord {
        my $number = shift;
        my $max    = shift;

        return 0 if $number eq "";
        return 0 if $number !~ /^[\-\+]?[0-9]+(\.[0-9]+)?$/;

        return $number <= $max && $number >= -$max ? 1 : 0;
    }

    sub Param {
        my $param = shift;
        my $data  = $qq->param($param);
        $data = "" if !defined $data;

        $data =~ s/^\s+//;
        $data =~ s/\s+$//;
        $data =~ s/[\t\n]+/ /g;
        return $data;
    }

    my $format = Param("format");
    my $city   = Param("city");
    my $email  = Param("email");
    my $sw_lat = Param("sw_lat");
    my $sw_lng = Param("sw_lng");
    my $ne_lat = Param("ne_lat");
    my $ne_lng = Param("ne_lng");
    my $coords = Param("coords");
    my $layers = Param("layers");
    my $pg     = Param("pg");

    if ( !exists $formats->{$format} ) {
        error("Unknown error format '$format'");
    }
    if ( $email eq '' ) {
        error(
            "Please enter a e-mail address. "
              . "We need an e-mail address to notify you if your extract is ready for download. "
              . "If you don't have an e-mail address, you can get a temporary from "
              . "<a href='http://mailinator.com/'>mailinator.com</a>",
            1
        );
    }
    elsif (
        !Email::Valid->address(
            -address => $email,
            -mxcheck => $option->{'email_valid_mxcheck'}
        )
      )
    {
        error("E-mail address '$email' is not valid.");
    }

    my $skm = 0;

    # polygon, N points
    my @coords = ();
    $coords = extract_coords($coords);

    if ($coords) {
        if ( !$option->{enable_polygon} ) {
            error("A polygon is not supported, use a rectangle instead");
            goto NEXT;
        }

        @coords = parse_coords($coords);
        error(  "to many coordinates for polygon: "
              . scalar(@coords) . ' > '
              . $option->{max_coords} )
          if $#coords > $option->{max_coords};
        @coords = &normalize_polygon( \@coords );

        if ( scalar(@coords) <= 2 ) {
            error("Need more than 2 points.");
            error("Maybe the input file is corrupt?") if scalar(@coords) == 0;
            goto NEXT;
        }

        foreach my $point (@coords) {
            error("lng '$point->[0]' is out of range -180 ... 180")
              if !is_lng( $point->[0] );
            error("lat '$point->[1]' is out of range -90 ... 90")
              if !is_lat( $point->[1] );
        }

        ( $sw_lng, $sw_lat, $ne_lng, $ne_lat ) = polygon_bbox(@coords);
        warn "Calculate poygone bbox: ",
          "sw_lng: $sw_lng, sw_lat: $sw_lat, ne_lng: $ne_lng, ne_lat: $ne_lat\n"
          if $debug >= 1;
    }

    # rectangle, 2 points
    error("sw lat '$sw_lat' is out of range -90 ... 90")
      if !is_lat($sw_lat);
    error("sw lng '$sw_lng' is out of range -180 ... 180")
      if !is_lng($sw_lng);
    error("ne lat '$ne_lat' is out of range -90 ... 90")
      if !is_lat($ne_lat);
    error("ne lng '$ne_lng' is out of range -180 ... 180")
      if !is_lng($ne_lng);

    $pg = 1 if !$pg || $pg > 1 || $pg <= 0;

    if ( !$error ) {
        error("ne lng '$ne_lng' must be larger than sw lng '$sw_lng'")
          if $ne_lng <= $sw_lng
              && !( $sw_lng > 0 && $ne_lng < 0 );    # date border

        error("ne lat '$ne_lat' must be larger than sw lat '$sw_lat'")
          if $ne_lat <= $sw_lat;

        $skm = square_km( $sw_lat, $sw_lng, $ne_lat, $ne_lng, $pg );
        error(
"Area is to large: @{[ large_int($skm) ]} square km, must be smaller than @{[ large_int($max_skm) ]} square km."
        ) if $skm > $max_skm;
    }

  NEXT:

    if ( $city eq '' ) {
        if ( $option->{'city_name_optional'} ) {
            $city =
              $option->{'city_name_optional_coords'}
              ? "none ($sw_lng,$sw_lat x $ne_lng,$ne_lat)"
              : "none";
        }
        else {
            error("Please give the area a name.");
        }
    }

    if ( $layers ne "" && $layers !~ /^[BTF0]+$/ ) {
        error("layers '$layers' is out of range");
    }

    if ($error) {
        print qq{<p class="error">The input data is not valid. };
        print "Please click on the back button of your browser ";
        print "and correct the values!</p>\n";

        print "<br/>" x 4;
        print &footer( $q,
            'css' => '#footer { width: 90%; padding-bottom: 20px; }' );
        return;
    }
    else {

        # display coordinates, but not more than 32
        my $coordinates =
          @coords
          ? encode_json(
            $#coords < 32
            ? \@coords
            : [ @coords[ 0 .. 15 ], "to long to read..." ]
          )
          : "$sw_lng,$sw_lat x $ne_lng,$ne_lat";

        print <<EOF;
<p>Thanks - the input data looks good.</p><p>
It takes between 10-30 minutes to extract an area from planet.osm,
depending on the size of the area and the system load.
You will be notified by e-mail if your extract is ready for download.
Please follow the instruction in the email to proceed your request.</p>

<p align='left'>Area: "@{[ escapeHTML($city) ]}" covers @{[ large_int($skm) ]} square km <br/>
Coordinates: @{[ escapeHTML($coordinates) ]} <br/>
Format: $format
</p>

<p>Press the back button to get the same area in a different format, or to request a new area.</p>
EOF

    }

    my $script_url = &script_url(
        $option,
        {
            'sw_lat' => $sw_lat,
            'sw_lng' => $sw_lng,
            'ne_lat' => $ne_lat,
            'ne_lng' => $ne_lng,
            'format' => $format,
            'layers' => $layers,
            'coords' => \@coords,
            'city'   => $city,
        }
    );

    my $obj = {
        'email'           => $email,
        'format'          => $format,
        'city'            => $city,
        'sw_lat'          => $sw_lat,
        'sw_lng'          => $sw_lng,
        'ne_lat'          => $ne_lat,
        'ne_lng'          => $ne_lng,
        'coords'          => \@coords,
        'layers'          => $layers,
        'skm'             => $skm,
        'date'            => time2str(time),
        'time'            => time(),
        'script_url'      => $script_url,
        'coords_original' => $debug >= 2 ? $coords : "",
    };

    my $json      = new JSON;
    my $json_text = $json->utf8->pretty->encode($obj);

    my ( $key, $json_file ) = &save_request($obj);
    my $mail_error = "";
    if (
        !$key
        || (
            $option->{'confirm'} >= 0
            && (
                $mail_error = send_email_confirm(
                    'q'       => $q,
                    'obj'     => $obj,
                    'key'     => $key,
                    'confirm' => $option->{'confirm'}
                )
            )
        )
      )
    {
        print
          qq{<p class="error">I'm so sorry, I couldn't save your request.\n},
          qq{Please contact the BBBike.org maintainer!</p>};
        print "<p>Error message: ", escapeHTML($mail_error), "<br/>\n";
        print "Please check if the E-Mail address is correct."
          if $mail_error =~ /verify SMTP recipient/;
        print "</p>\n";

        # cleanup temp json file
        unlink($json_file) or die "unlink $json_file: $!\n";
    }

    else {

        if ( !&complete_save_request($json_file) ) {
            print qq{<p class="error">I'm so sorry,},
              qq{ I couldn't save your request.\n},
              qq{Please contact the BBBike.org maintainer!</p>};
        }

        else {
            print
              qq{<p>We appreciate any feedback, suggestions },
              qq{and a <a href="../community.html#donate">donation</a>! },
qq{You can support us via PayPal, Flattr or bank wire transfer.\n},
              qq{<br/>} x 4,
              "</p>\n";
        }
    }

    print &footer( $q,
        'css' => '#footer { width: 90%; padding-bottom: 20px; }' );
}

# save request in incoming spool
sub send_email_confirm {
    my %args = @_;

    my $obj     = $args{'obj'};
    my $key     = $args{'key'};
    my $q       = $args{'q'};
    my $confirm = $args{'confirm'};

    my $url = $q->url( -full => 1, -absolute => 1 ) . "?key=$key";

    my $message = <<EOF;
Hi,

somone - possible you - requested to extract an OpenStreetMaps area
from planet.osm

 City: $obj->{"city"}
 Area: $obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}
 Format: $obj->{"format"}


To proceeed, please click on the following link:

  $url

othewise just ignore this e-mail.

Sincerely, your BBBike extract admin

--
http://BBBike.org - Your Cycle Route Planner
EOF

    eval {
        &send_email( $obj->{"email"},
            "Please confirm planet.osm extract request",
            $message, $confirm );
    };
    if ($@) {
        warn "send_email_confirm: $@\n";
        return $@;
    }

    return 0;
}

# SMTP wrapper
sub send_email {
    my ( $to, $subject, $text, $confirm ) = @_;
    my $mail_server  = "localhost";
    my @to           = split /,/, $to;
    my $content_type = "Content-Type: text/plain; charset=UTF-8\n"
      . "Content-Transfer-Encoding: binary";

    my $from = $email_from;
    my $data =
      "From: $from\nTo: $to\nSubject: $subject\n" . "$content_type\n$text";
    my $smtp = new Net::SMTP( $mail_server, Hello => "localhost", Debug => 0 )
      or die "can't make SMTP object\n";

    # validate e-mail addresses - even if we don't sent out an email yet
    $smtp->mail($from) or die "can't send email from $from\n";
    $smtp->to(@to)     or die "can't use SMTP recipient '$to'\n";
    $smtp->verify(@to) or die "can't verify SMTP recipient '$to'\n";

    # sent out an email and ask to confirm
    # configured by: $option->{'conform'}
    if ( $confirm > 0 ) {
        $smtp->data($data) or die "can't email data to '$to'\n";
    }
    else {

        # do not sent mail body data
    }

    $smtp->quit() or die "can't send email to '$to'\n";
}

# ($lat1, $lon1 => $lat2, $lon2);
sub square_km {
    my ( $x1, $y1, $x2, $y2, $factor ) = @_;
    $factor = 1 if !defined $factor;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    return int( $height * $width * $factor );
}

# 240000 -> 240,000
sub large_int {
    my $text = reverse shift;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

# save request in incoming spool
sub save_request {
    my $obj = shift;

    my $json      = new JSON;
    my $json_text = $json->utf8->pretty->encode($obj);

    my $key = md5_hex( encode_utf8($json_text) . rand() );
    my $spool_dir =
      $option->{'confirm'} > 0 ? $spool->{"incoming"} : $spool->{"confirmed"};
    my $job = "$spool_dir/$key.json.tmp";

    warn "Store request $job: $json_text\n" if $debug;

    my $fh = new IO::File $job, "w";
    if ( !defined $fh ) {
        warn "Cannot open $job: $!\n";
        return;
    }
    binmode $fh, ":utf8";

    print $fh $json_text, "\n";
    $fh->close;

    return ( $key, $job );
}

# foo.json.tmp -> foo.json
sub complete_save_request {
    my $file = shift;
    if ( !$file || !-e $file ) {
        warn "file '$file' does not exists\n";
        return;
    }

    my $temp_file = $file;
    $temp_file =~ s/\.tmp$//;

    if ( $file eq $temp_file ) {
        warn "$file has no .tmp extension\n";
        return;
    }

    if ( rename( $file, $temp_file ) ) {
        return $temp_file;
    }
    else {
        warn "rename $file -> $temp_file: $!\n";
        return;
    }
}

# the user confirm a request
# move the config file from incoming to confirmed directory
sub confirm_key {
    my %args = @_;
    my $q    = $args{'q'};

    my $key = $q->param("key") || "";

    my $incoming  = $spool->{"incoming"} . "/$key.json";
    my $confirmed = $spool->{"confirmed"} . "/$key.json";

    print &header($q);
    print &layout($q);

    # move file to next spool directory
    # Don't complain if the file was already moved (users clicked twice?)
    my $success = ( -f $incoming && rename( $incoming, $confirmed ) )
      || -f $confirmed;

    if ( !$success ) {
        print
qq{<p class="error">I'm so sorry, I couldn't find a key for your request.\n},
          qq{Please contact the BBBike.org maintainer!</p>};
    }
    else {
        print
          qq{<p class="">Thanks - your request has been confirmed.\n},
          qq{It takes usually 10-30 minutes to extract the data.\n},
qq{You will be notified by e-mail if your extract is ready for download. Stay tuned!</p>};

        print qq{<hr/>\n<p>We appreciate any feedback, suggestions },
          qq{and a <a href="../community.html#donate">donation</a>!</p>};
    }

    print &footer($q);
}

# startpage
sub homepage {
    my %args = @_;

    my $q = $args{'q'};

    print &header( $q, -type => 'homepage' );
    print &layout($q);

    print qq{<div id="intro">\n};

    print qq{<div id="message">\n}, &message, &locate_message, "</div>\n";
    print "<hr/>\n\n";

    print $q->start_form(
        -method   => $request_method,
        -id       => 'extract',
        -onsubmit => 'return checkform();'
    );

    my $lat = qq{<span title='Latitude'>lat</span>};
    my $lng = qq{<span title='Longitude'>lng</span>};

    my $default_email = $q->cookie( -name => "email" ) || "";
    my $default_format = $q->cookie( -name => "format" )
      || $option->{'default_format'};

    print qq{<div id="table">\n};
    print $q->table(
        { -width => '100%' },
        $q->Tr(
            {},
            [
                $q->td(
                    [
"<span class='normalscreen lnglatbox' title='South West, valid values: -180 .. 180'>Left lower corner (South-West)<br/>"
                          . "&nbsp;&nbsp; $lng: "
                          . $q->textfield(
                            -name => 'sw_lng',
                            -id   => 'sw_lng',
                            -size => 8
                          )
                          . " $lat: "
                          . $q->textfield(
                            -name => 'sw_lat',
                            -id   => 'sw_lat',
                            -size => 8
                          ),
'</span><span id="square_km_small" title="area covers N square kilometers"></span>'
                    ]
                ),

                $q->td(
                    [
"<span class='normalscreen lnglatbox' title='North East, valid values: -180 .. 180'>Right top corner (North-East)<br/>"
                          . "&nbsp;&nbsp; $lng: "
                          . $q->textfield(
                            -name => 'ne_lng',
                            -id   => 'ne_lng',
                            -size => 8
                          )
                          . " $lat: "
                          . $q->textfield(
                            -name => 'ne_lat',
                            -id   => 'ne_lat',
                            -size => 8
                          ),
'</span><span title="file data size approx." id="size_small"></span>'
                    ]
                ),

                $q->td(
                    [
"<span class='normalscreen' title='PBF: fast and compact data, OSM XML gzip: standard OSM format, "
                          . "twice as large, Garmin format in different styles, Esri shapefile format, "
                          . "Osmand for Androids'>Format <a class='tools-helptrigger' href='/extract-dialog-format.html'><img src='/html/help-16px.png' alt=''/></a><br/></span>"
                          . $q->popup_menu(
                            -name   => 'format',
                            -values => [
                                sort { $formats->{$a} cmp $formats->{$b} }
                                  keys %$formats
                            ],
                            -labels  => $formats,
                            -default => $default_format
                          )
                    ]
                ),

                $q->td(
                    [
"<span title='Required, you will be notified by e-mail if your extract is ready for download.'>"
                          . "Your email address <a class='tools-helptrigger-small' href='/extract-dialog-email.html'><img src='/html/help-16px.png' alt=''/></a><br/></span>"
                          . $q->textfield(
                            -name  => 'email',
                            -size  => 28,
                            -value => $default_email
                          )
                          . $q->hidden(
                            -name  => 'as',
                            -value => "0",
                            -id    => 'as'
                          )
                          . $q->hidden(
                            -name  => 'pg',
                            -value => "0",
                            -id    => 'pg'
                          )
                          . $q->hidden(
                            -name  => 'coords',
                            -value => "",
                            -id    => 'coords'
                          )
                          . $q->hidden(
                            -name  => 'layers',
                            -value => "",
                            -id    => 'layers'
                          ),
'<span id="time_small" title="approx. extract time in minutes"></span>'
                    ]
                ),

                $q->td(
                    [
"<span class='normalscreen' title='Give the city or area to extract a name. "
                          . "The name is optional, but better fill it out to find it later again.'>Name of area to extract <a class='tools-helptrigger-small' href='/extract-dialog-name.html'><img src='/html/help-16px.png' alt='' /></a><br/></span>"
                          . $q->textfield(
                            -name => 'city',
                            -id   => 'city',
                            -size => 28
                          )
                    ]
                ),

                $q->td(
                    [
                        $q->submit(
                            -title => 'start extract',
                            -name  => 'submit',
                            -value => 'extract',

                            #-id    => 'submit'
                        )
                    ]
                ),
            ]
        )
    );

    print "\n</div>\n";

    #print "<br/>\n";
    #print $q->submit(
    #    -title => 'start extract',
    #    -name  => 'submit',
    #    -value => 'extract',
    #
    #    #-id    => 'extract'
    #);
    print $q->end_form;
    print &export_osm;
    print qq{<hr/>\n};
    print &manual_area;
    print "</div>\n";

    print &map;

    print &footer( $q, 'map' => 1 );
}

sub locate_message {
    return <<EOF;
<span id="locate">
<span style="display:none" id="tools-pageload">Please wait... <img src="/images/indicator.gif" alt="loading" /></span>
<a title="where am I?" href="javascript:locateMe()"><img src="/images/location-icon.png" width="25" height="23" alt="loading" border="0"/></a>
</span>
EOF
}

sub export_osm {
    return <<EOF;
  <div id="export_osm">
    <div id="export_osm_too_large" style="display:none">
      <span class="export_heading error">Area too large. <span id="size"></span>
      Please zoom in!
      You may also download <a target="_help" href="/extract.html#other_extract_services">pre-extracted areas</a> from other services</span>
      <div class="export_details"></div>
    </div>
  </div> <!-- export_osm -->
EOF
}

######################################################################
# main
my $q = new CGI;

my $action = $q->param("submit") || ( $q->param("key") ? "key" : "" );
if ( $action eq "extract" ) {
    &check_input( 'q' => $q );
}
elsif ( $action eq 'key' ) {
    &confirm_key( 'q' => $q );
}
else {
    &homepage( 'q' => $q );
}

1;
