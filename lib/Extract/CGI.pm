#!/usr/local/bin/perl
# Copyright (c) 2011-2018 Wolfram Schneider, https://bbbike.org
#
# helper functions for extract.cgi

package Extract::CGI;

use HTTP::Date;
use CGI qw(escapeHTML);
use Data::Dumper;
use JSON;
use Email::Valid;

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

our $debug          = 1;
our $extract_dialog = '/extract-dialog';
our $option;

##########################
# helper functions
#

# Extract::Poly::new->('debug'=> 2, 'option' => $option)
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
# helper functions
#

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

# see /html/extract.js
sub map {
    my $self = shift;

    return <<EOF;
</div> <!-- sidebar_left -->

<div id="content" class="site_index">
    <!-- define a DIV into which the map will appear. Make it take up the whole window -->
     <div id="map"></div>
</div><!-- content -->

EOF

}

sub manual_area {
    my $self     = shift;
    my $language = $self->{'language'};

    my $img_prefix = '/html/OpenLayers/2.12/theme/default/img';

    return <<EOF;
 <div id="manual_area">
  <div id="sidebar_content">
    <span class="export_hint">
      <br/>
      <span id="drag_box">
        <span id="drag_box_select" style="display:none">
            <button class="link">@{[ M("Select a different area") ]}</button>
            <a class='tools-helptrigger' href='$extract_dialog/$language/select-area.html'><img src='/html/help-16px.png' alt="" /></a>
            <p></p>
        </span>
        <span id="drag_box_default" data-step="4" data-intro="@{[ M('EXTRACT_INTRO_CLICK') ]}" data-position='auto' data-tooltipClass="extract-intro">
            @{[ M("Now move the map to your desired location") ]}. <br/>
            @{[ M("Then click") ]} <button class="link">@{[ M("here") ]}</button> @{[ M("to create the bounding box") ]}.
            <a class='tools-helptrigger' href='$extract_dialog/$language/select-area.html'><img src='/html/help-16px.png' alt="" /></a>
            <br/>
        </span>
      </span>
    </span>
    <span id="square_km"></span>

    <div id="polygon_controls" style="display:none">
	<input id="createVertices" type="radio" name="type" onclick="polygon_update()" />
	<label class="link" for="createVertices">@{[ M("add points to polygon") ]}
	<img src="$img_prefix/add_point_on.png" alt=""/>  <a class='tools-helptrigger' href='$extract_dialog/$language/polygon.html'><img src='/html/help-16px.png' alt="" /></a><br/>
	</label>

	<input id="rotate" type="radio" name="type" onclick="polygon_update()" />
	<label class="link" for="rotate">@{[ M("resize or drag polygon") ]}
	<img src="$img_prefix/move_feature_on.png" alt="move feature"/>
	</label>

        <!-- <span>@{[ M("EXTRACT_USAGE2") ]}</span> -->
    </div>

    <div id="format_image"></div>

  </div> <!-- sidebar_content -->
 </div><!-- manual_area -->
EOF
}

# link to same area on map compare
sub mc_parameters {
    my $self = shift;
    my $q    = shift;

    my $sw_lng = Param( $q, "sw_lng" );
    my $sw_lat = Param( $q, "sw_lat" );
    my $ne_lng = Param( $q, "ne_lng" );
    my $ne_lat = Param( $q, "ne_lat" );

    # nothing we could do
    if ( $sw_lng eq "" || $sw_lat eq "" || $ne_lng eq "" || $ne_lat ) {
        return "";
    }

    my $lng = $sw_lng + ( $ne_lng - $sw_lng ) / 2;
    my $lat = $sw_lat + ( $ne_lat - $sw_lat ) / 2;

    if ( $lng && $lat ) {
        return
            "?lon="
          . escapeHTML($lng) . "&lat="
          . escapeHTML($lat)
          . "&profile=extract";
    }
    else {
        return "";
    }
}

sub footer_top {
    my $self = shift;

    my $q        = shift;
    my %args     = @_;
    my $css      = $args{'css'} || "";
    my $error    = $args{'error'} || 0;
    my $language = $self->{'language'};

    my $locate =
      $args{'map'}
      ? '<br/><a href="javascript:locateMe()">where am I?</a>'
      : "";
    $locate = "";    # disable

    if ($css) {
        $css = "\n<style>$css</style>\n";
    }

    my $community_link =
      $language eq 'de' ? "/community.de.html" : "/community.html";
    my $donate = "";

    if ( $option->{'pro'} ) {
        $donate =
qq{<p class="normalscreen" id="extract-pro" title="you are using the extract pro service">}
          . qq{<a href="/support.html">extract pro</a></p>\n};
    }
    elsif ( !$error ) {
        $donate = qq{<p class="normalscreen" id="big_donate_image">}
          . qq{<a href="$community_link#donate"><img class="logo" height="47" width="126" src="/images/btn_donateCC_LG.gif" alt="donate"/></a></p>};
    }

    my $home = $q->url( -query => 0, -relative => 1 ) || "/";
    my $mc_parameters = $self->mc_parameters($q);

    my $homepage =
        $option->{'pro'}
      ? $option->{"script_homepage_pro"}
      : $option->{"script_homepage"};
    my $server_status_url =
        $option->{'pro'}
      ? $option->{"server_status_url_pro"}
      : $option->{"server_status_url"};
    my $download_homepage =
        $option->{'pro'}
      ? $option->{'download_homepage_pro'}
      : $option->{'download_homepage'};

    return <<EOF;
  $donate
  $css
  <div id="footer_top">
    <a href="$homepage">home</a> |
    <a target="_help" href="/extract.html">@{[ M("help") ]}</a> |
    <span class="extract-introjs"><a href="javascript:void(0);" onclick="javascript:introjs_start(); ">intro</a></span> |
    <a href="$server_status_url" target="_blank">status</a> |
    <!-- <a href="//mc.bbbike.org/mc/$mc_parameters" id="mc_link" target="_blank">map compare</a> | -->
    <a href="$download_homepage">download</a> |
    <a href="/support.html">@{[ M("commercial support") ]}</a>
    $locate
  </div>
EOF
}

sub footer {
    my $self = shift;

    my $q    = shift;
    my %args = @_;

    my $analytics =
      $option->{"enable_google_analytics"}
      ? BBBike::Analytics->new( 'q' => $q )->google_analytics
      : "";
    my $url = $q->url( -relative => 1 );
    my $error = $args{'error'} || 0;

    my $locate =
      $args{'map'} ? ' | <a href="javascript:locateMe()">where am I?</a>' : "";

    my @css = ();
    if ( $option->{'enable_introjs'} ) {
        push @css, qw(introjs/2.9.3/introjs.css);
    }

    my @js = qw(
      OpenLayers/2.12/OpenLayers-min.js
      OpenLayers/2.12/OpenStreetMap.js
      jquery/jquery-1.8.3.min.js
      jquery/jqModal-1.1.0.js
      jquery/jquery-ui-1.9.1.custom.min.js
      jquery/jquery.cookie-1.3.1.js
      jquery/jquery.iecors.js
    );

    if ( $option->{'enable_introjs'} ) {
        push @js, qw(introjs/2.9.3/intro.min.js);
    }

    # finally, our JS
    push @js, "extract.js";

    # load CSS before JS due possible dependencies
    my $css = join "\n",
      map { qq[<link  href="/html/$_" rel="stylesheet" type="text/css" />] }
      @css;

    my $javascript = join "\n",
      map { qq[<script src="/html/$_" type="text/javascript"></script>] } @js;

    $javascript .=
qq{\n<script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?v=3.9&amp;sensor=false&amp;language=en&amp;libraries=weather,panoramio"></script>}
      if $option->{"with_google_maps"};

    return <<EOF;

<div id="footer">
  @{[ $self->footer_top($q, 'error' => $error, 'map' => $args{'map'}, 'css' => $args{'css'} ) ]}
  <hr/>
  <div id="copyright" class="normalscreen">
    (&copy;) 2018 <a href="https://www.bbbike.org">BBBike.org</a>
    by <a href="https://wolfram.schneider.org">Wolfram Schneider</a><br/>
    Map data (&copy;) <a href="https://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
  <div id="footer_community"></div>
  </div> <!-- copyright -->
</div>

</div></div></div> <!-- layout -->

$css

$javascript
$analytics
<script type="text/javascript">
  jQuery('#pageload-indicator').hide();
</script>

  <!-- pre-load some images for slow mobile networks -->
  <div id="slow-network" style="display:none">
    <img src="/html/close.png" alt="close button" />
  </div>

<!-- bbbike_extract_status: $error, pro version: @{[ $option->{'pro'} ]} -->
</body>
</html>
EOF
}

sub social_links {
    my $self = shift;

    <<EOF;
    <span id="social">
    <a href="https://twitter.com/BBBikeWorld" target="_new"><img class="logo" width="16" height="16" src="/images/twitter-t.png" alt="" title="Follow us on twitter.com/BBBikeWorld" /></a>
    <a href="https://www.bbbike.org/feed/bbbike-world.xml"><img class="logo" width="14" height="14" title="What's new on BBBike.org" src="/images/rss-icon.png" alt="" /></a>
    </span>
EOF
}

sub message {
    my $self = shift;

    my $q        = shift;
    my $language = shift;
    my $locale   = shift || $self->{'locale'};

    return <<EOF;
<span id="noscript"><noscript>Please enable JavaScript in your browser. Thanks!</noscript></span>
<span id="toolbar"></span>

<span id="tools-titlebar">
 @{[ $locale->language_links ]}
 @{[ $self->social_links ]} -
 <span class="extract-introjs"><a href="javascript:void(0);" onclick="javascript:introjs_start(); ">intro</a> -</span>
 <span id="tools-help"><a class='tools-helptrigger' href='$extract_dialog/$language/about.html' title='info'><span>@{[ M("about") ]} extracts</span></a> - </span>
 <span id="pageload-indicator">&nbsp;<img src="/html/indicator.gif" width="14" height="14" alt="" title="Loading JavaScript libraries" /> Loading JavaScript</span>
 <span class="jqmWindow jqmWindowLarge" id="tools-helpwin"></span>
</span>

<span id="debug"></span>
EOF
}

sub layout {
    my $self = shift;

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
    my $self = shift;

    my $option = shift;
    my $obj    = shift;

    my $coords = "";
    my $city   = $obj->{'city'} || "";
    my $lang   = $obj->{'lang'} || "";

    if ( scalar( @{ $obj->{'coords'} } ) > 100 ) {
        $coords = "0,0,0";
        warn "Coordinates to long for URL, skipped\n" if $debug >= 2;
    }
    else {
        $coords = join '|', ( map { "$_->[0],$_->[1]" } @{ $obj->{'coords'} } );
    }

    my $script_homepage =
        $option->{'pro'}
      ? $option->{'script_homepage_pro'}
      : $option->{'script_homepage'};

    my $script_url = "$script_homepage/?";
    $script_url .=
"sw_lng=$obj->{sw_lng}&sw_lat=$obj->{sw_lat}&ne_lng=$obj->{ne_lng}&ne_lat=$obj->{ne_lat}";
    $script_url .= "&format=$obj->{'format'}";
    $script_url .= "&coords=" . CGI::escape($coords) if $coords ne "";
    $script_url .= "&city=" . CGI::escape($city) if $city ne "";
    $script_url .= "&lang=" . CGI::escape($lang) if $lang ne "";

    return $script_url;
}

sub get_spool_dir {
    my $self = shift;

    my $spool_dir = $self->{'option'}->{'spool_dir'}
      || $Extract::Config::spool_dir;

    return $spool_dir;
}

#
# validate user input
# reject wrong values
#
sub check_input {
    my $self = shift;

    my %args = @_;
    my $q = $args{'q'} || $self->{'q'};

    my $error;
    my $data;

    ( $error, $data ) = $self->_check_input(@_);

    print $self->header( $q, -type => 'check_input', -error => $error );
    print $self->layout( $q, 'check_input' => 1 );

    print $data;

    print $self->footer(
        $q,
        'error' => $error,
        'css'   => '#footer { width: 90%; padding-bottom: 20px; }'
    );
}

#
# Check input values.
# On error, return a HTTP 520 status
# and a HTML message.
#
sub _check_input {
    my $self = shift;

    my %args    = @_;
    my $q       = $args{'q'} || $self->{'q'};
    my $locale  = $args{'locale'} || $self->{'locale'};
    my $max_skm = $self->{'option'}->{'max_skm'};

    #our $qq = $q;

    my $lang = $locale->get_language;
    our @error = ();
    our $error = 0;

    sub error {
        my $message   = shift;
        my $no_escape = shift;

        $error++;

        my $data =
          "<p>" . ( $no_escape ? $message : escapeHTML($message) ) . "</p>\n";

        #print $data;
        push @error, $data;
    }

    my $format = Param( $q, "format" );
    my $city   = Param( $q, "city" );
    my $email  = Param( $q, "email" );
    my $sw_lat = Param( $q, "sw_lat" );
    my $sw_lng = Param( $q, "sw_lng" );
    my $ne_lat = Param( $q, "ne_lat" );
    my $ne_lng = Param( $q, "ne_lng" );
    my $coords = Param( $q, "coords" );
    my $layers = Param( $q, "layers" );
    my $pg     = Param( $q, "pg" );
    my $as     = Param( $q, "as" );
    my $expire = Param( $q, "expire" );

    if ( $expire ne '' && $expire =~ /^\d+$/ ) {
        my $time = time();
        if ( $expire + 2 * 86400 < $time ) {
            warn "Page expired: $expire, please reload\n";
        }
    }

    if ( !$expire ) {
        warn "No expire parameter given, bot requests?\n";
    }

    if ( !exists $self->{'formats'}->{$format} ) {
        error("Unknown error format '$format'");
    }

    if ( $email eq '' ) {
        error(
            "Please enter a email address. "
              . "We need an email address to notify you if your extract is ready for download. "
              . "If you don't have an email address, you can get a temporary from "
              . "<a href='https://mailinator.com/'>mailinator.com</a>",
            1
        );
    }

    # accecpt "nobody" as email address
    elsif ( $option->{'email_allow_nobody'} && lc($email) eq 'nobody' ) {
        $email .= '@bbbike.org';
        warn "Reset E-Mail addresse to $email\n" if $debug >= 1;
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

    #$coords = extract_coords($coords);

    my $poly = new Extract::Poly;
    if ($coords) {

        #if ( !$option->{enable_polygon} ) {
        #    error("A polygon is not supported, use a rectangle instead");
        #    goto NEXT;
        #}

        @coords = $poly->parse_coords($coords);
        error(  "to many coordinates for polygon: "
              . scalar(@coords) . ' > '
              . $option->{max_coords} )
          if $#coords > $option->{max_coords};
        @coords = $poly->normalize_polygon( \@coords );

        if ( scalar(@coords) <= 2 ) {
            error("Need more than 2 points.");
            error("Maybe the input file is corrupt?") if scalar(@coords) == 0;

            #goto NEXT;
        }

        foreach my $point (@coords) {
            error("lng '$point->[0]' is out of range -180 ... 180")
              if !$poly->is_lng( $point->[0] );
            error("lat '$point->[1]' is out of range -90 ... 90")
              if !$poly->is_lat( $point->[1] );
        }

        ( $sw_lng, $sw_lat, $ne_lng, $ne_lat ) = $poly->polygon_bbox(@coords);
        warn "Calculate poygone bbox: ",
          "sw_lng: $sw_lng, sw_lat: $sw_lat, ne_lng: $ne_lng, ne_lat: $ne_lat\n"
          if $debug >= 1;
    }

    # rectangle, 2 points
    error("sw lat '$sw_lat' is out of range -90 ... 90")
      if !$poly->is_lat($sw_lat);
    error("sw lng '$sw_lng' is out of range -180 ... 180")
      if !$poly->is_lng($sw_lng);
    error("ne lat '$ne_lat' is out of range -90 ... 90")
      if !$poly->is_lat($ne_lat);
    error("ne lng '$ne_lng' is out of range -180 ... 180")
      if !$poly->is_lng($ne_lng);

    $pg = 1 if !$pg || $pg > 1 || $pg <= 0;

    error("area size '$as' must be greather than zero")
      if $as eq "" || $as <= 0;

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

    #NEXT:

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

    ###############################################################################
    # display coordinates, but not more than 32
    my $coordinates =
      @coords
      ? encode_json(
        $#coords < 32
        ? \@coords
        : [ @coords[ 0 .. 15 ], "to long to read..." ]
      )
      : "$sw_lng,$sw_lat x $ne_lng,$ne_lat";

    my $script_url = $self->script_url(
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
            'lang'   => $lang,
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
        'lang'            => $lang,
        'as'              => $as,
        'pg'              => $pg,
    };

    if ( $option->{enable_priority} ) {
        $obj->{'ip_address'} = $q->remote_host();
        $obj->{'user_agent'} = $q->user_agent();
    }

    ###############################################################################
    # bots?
    my $confirmed_dir =
      $self->get_spool_dir() . "/" . $Extract::Config::spool->{"confirmed"};

    my ( $email_counter, $ip_counter ) =
      check_queue( 'obj' => $obj, 'spool_dir_confirmed' => $confirmed_dir );

    # a limit per user or IP address
    # see $cgi/extract.cgi::option
    my $email_limit =
      defined $option->{'scheduler'}->{'user_limit_email'}->{$email}
      ? $option->{'scheduler'}->{'user_limit_email'}->{$email}
      : $option->{'scheduler'}->{'user_limit'};
    my $ip_limit = $option->{'scheduler'}->{'ip_limit'};

    if ( $email_counter > $email_limit ) {
        error( M("EXTRACT_LIMIT"), 1 );
        warn "limit email counter: $email_counter > email_limit $email\n"
          if $debug >= 1;
    }
    elsif ( $ip_counter > $ip_limit ) {
        error( M("EXTRACT_LIMIT"), 1 );
        warn "limit ip counter: $ip_counter > $ip_limit\n" if $debug >= 1;
    }

    my @data;

    # invalid input, do not save the request and give up
    if ($error) {
        error( M("EXTRACT_VALID"), 1 );

        if ($debug) {
            warn join "\n", "==> User input errors, stop: "
              . $q->url( -full => 1, -query => 1 ), @error;
        }

        return ( $error, join "\n", @error, @data );
    }

    my $text = M("EXTRACT_CONFIRMED");
    if ( $text =~ /(.+)/s ) {
        $text = $1;
    }

    my $server_status_url =
        $option->{'pro'}
      ? $option->{'server_status_url_pro'}
      : $option->{'server_status_url'};

    push @data,
      sprintf( $text,
        escapeHTML($city), large_int($skm), $coordinates,
        $self->{'formats'}->{$format},
        $server_status_url );

    my ( $key, $json_file ) =
      &save_request( $obj, $self->get_spool_dir,
        $Extract::Config::spool->{"confirmed"} );
    if ( &complete_save_request($json_file) ) {
        push @data, M("EXTRACT_DONATION") if !$option->{'pro'};

        push @data, qq{<br/>} x 4, "</p>\n";
    }

    # disk full, permission problem?
    else {
        push @error, qq{<p class="error">I'm so sorry,},
          qq{ I couldn't save your request.\n},
          qq{Please contact the BBBike.org maintainer!</p>};
        $error++;
    }

    return ( $error, join "\n", @error, @data );
}

# ($lat1, $lon1 => $lat2, $lon2);

# startpage
sub homepage {
    my $self = shift;

    my %args           = @_;
    my $q              = $args{'q'} || $self->{'q'};
    my $locale         = $args{'locale'} || $self->{'locale'};
    my $language       = $self->{'language'};
    my $formats        = $self->{'formats'};
    my $request_method = $self->{'option'}->{'request_method'};

    print $self->header( $q, -type => 'homepage' );
    print $self->layout($q);

    # localize formats
    my $formats_locale = {};
    foreach my $key ( keys %$formats ) {
        $formats_locale->{$key} = M( $formats->{$key} );
    }

    print qq{<div id="intro">\n};

    print qq{<div id="message">\n}, $self->message( $q, $language, $locale ),
      $self->locate_message,
      "</div>\n";
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

    print $q->hidden( "lang", $language ), "\n\n";

    # build group for formats
    my @values = ();
    foreach my $group ( @{ $option->{'formats'} } ) {
        my @f;

        # only formats which are configured in $formats hash
        foreach my $f ( @{ $group->{'formats'} } ) {
            push @f, $f if exists $formats->{$f};
        }

        push @values,
          $q->optgroup(
            -name   => M( $group->{'title'} ),
            -values => \@f,
            -labels => $formats_locale,
          );
    }
    warn Dumper( \@values ) if $debug >= 3;

    print qq{<div id="table">\n};
    print $q->table(
        { -width => '100%' },
        $q->Tr(
            {},
            [
                $q->td(
                    [
                        "\n"
                          . qq{<span class='lnglatbox' title='South West, valid values: lng -180 .. 180, lat -90 .. 90'>}
                          . M('Left lower corner (South-West)') . "<br/>"
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
                          )
                          . "</span>\n",
qq{<span title="hide longitude,latitude box" class="lnglatbox" onclick="javascript:toggle_lnglatbox ();">}
                          . qq{<input class="uncheck" type="radio" />@{[ M("hide") ]} lnglat</span>\n}
                    ]
                ),

                $q->td(
                    [
                            "\n"
                          . qq{<span class='lnglatbox' title='North East, valid values: lng -180 .. 180, lat -90 .. 90'>}
                          . M('Right top corner (North-East)') . "<br/>"
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
                          )
                          . "</span>\n"
                    ]
                ),

                $q->td(
                    [
                            "\n"
                          . qq{<span class='' title='PBF: fast and compact data, OSM XML gzip: standard OSM format, }
                          . "twice as large, Garmin format in different styles, Esri shapefile format, "
                          . "Osmand for Androids'>@{[ M('Format') ]} "
                          . "<a class='tools-helptrigger' href='$extract_dialog/$language/format.html'><img src='/html/help-16px.png' alt=''/></a>"
                          . "<br/></span>\n\n"
                          . $q->popup_menu(
                            -name   => 'format',
                            -id     => 'format',
                            -values => \@values,
                            -labels => $formats_locale,

                            # intro.js
                            -data_step         => 1,
                            -data_intro        => M("EXTRACT_INTRO_FORMAT"),
                            -data_position     => 'auto',
                            -data_tooltipClass => "extract-introjs",

                            -default => $default_format
                          )
                          . "\n\n",
                    ]
                  )
                  . $q->td(
                    { "class" => "center" },
                    [
qq{<span title="show longitude,latitude box" class="lnglatbox_toggle" onclick="javascript:toggle_lnglatbox ();">}
                          . qq{<input class="uncheck" type="radio" />@{[ M("show") ]} lnglat</span><br/>\n}
                          . qq{<span class="center" id="square_km_small" title="area covers N square kilometers"></span>\n}
                    ]
                  ),

                $q->td(
                    [
                            "\n"
                          . qq{<span title='Required, you will be notified by email if your extract is ready for download.'>}
                          . M("Your email address")
                          . qq{ <a class='tools-helptrigger-small' href='$extract_dialog/$language/email.html'>}
                          . qq{<img src='/html/help-16px.png' alt=''/></a><br/></span>\n}
                          . $q->textfield(
                            -name => 'email',
                            -id   => 'email',

                            #-size  => 22,

                            # intro.js
                            -data_step         => 2,
                            -data_intro        => M("EXTRACT_INTRO_EMAIL"),
                            -data_position     => 'auto',
                            -data_tooltipClass => "extract-introjs",
                            -value             => $default_email
                          )
                          . "\n"
                          . $q->hidden(
                            -name  => 'as',
                            -value => "-1",
                            -id    => 'as'
                          )
                          . "\n"
                          . $q->hidden(
                            -name  => 'pg',
                            -value => "0",
                            -id    => 'pg'
                          )
                          . "\n"
                          . $q->hidden(
                            -name  => 'coords',
                            -value => "",
                            -id    => 'coords'
                          )
                          . "\n"
                          . $q->hidden(
                            -name  => 'oi',
                            -value => "0",
                            -id    => 'oi'
                          )
                          . "\n"
                          . $q->hidden(
                            -name  => 'layers',
                            -value => "",
                            -id    => 'layers'
                          )
                          . "\n",
                    ]
                  )
                  . $q->td(
                    { "class" => "center" },
                    [
qq{<span class="center" title="file data size approx." id="size_small"></span>\n}
                    ]
                  ),
                $q->td(
                    [
qq{<span class='' title='Give the city or area to extract a name. }
                          . "The name is optional, but better fill it out to find it later again.'>"
                          . "@{[ M('Name of area to extract') ]} "
                          . "<a class='tools-helptrigger-small' href='$extract_dialog/$language/name.html'><img src='/html/help-16px.png' alt='' /></a>"
                          . "<a class='tools-helptrigger-small' href='$extract_dialog/$language/search.html'> @{[ M('or search') ]}</a>"
                          . "<br/></span>\n"
                          . $q->textfield(
                            -name => 'city',
                            -id   => 'city',

                            # intro.js
                            -data_step         => 3,
                            -data_intro        => M("EXTRACT_INTRO_NAME"),
                            -data_position     => 'auto',
                            -data_tooltipClass => "extract-introjs",

                            #-size => 18
                          )
                          . "\n",
                    ]
                  )
                  . $q->td(
                    { "class" => "center" },
                    [
qq{<span id="time_small" class="center" title="approx. extract time in minutes"></span>\n}
                    ]
                  ),

                $q->td(
                    [
                        $q->submit(
                            -title => 'start extract',
                            -name  => 'submit',
                            -value => M('extract'),
                            -id    => 'submit'
                          )
                          . "\n"
                    ]
                )
            ]
        )
    );

    print "\n";
    print $q->hidden( "expire", time() ), "\n";

    print "</div>\n";
    print $q->end_form;
    print "\n\n";

    print $self->export_osm;

    #print qq{<hr/>\n};
    print $self->manual_area;
    print "</div>\n";

    print $self->map;

    print $self->footer( $q, 'map' => 1 );
}

sub locate_message {
    my $self = shift;

    return <<EOF;
<span id="locate">
<span style="display:none" id="tools-pageload"></span>
<a title="where am I?" href="javascript:locateMe()"><img id="location-icon" src="/images/location-icon.png" width="25" height="23" alt="loading" border="0"/></a>
</span>
EOF
}

sub export_osm {
    my $self = shift;

    return <<EOF;
  <div id="export_osm">
    <div id="export_osm_too_large" style="display:none">
      <span class="export_heading error">Area too large. <span id="size"></span>
      Please zoom in!
      You may also download <a target="_help" href="/extract.html#other_extract_services">pre-extracted areas</a>
      from other services or try out the
      <a href="/support.html">extract pro service</a>
      </span>
      <div class="export_details"></div>
    </div>
  </div> <!-- export_osm -->
EOF
}

sub M { return Extract::Locale::M(@_); };    # wrapper

1;

__DATA__;
