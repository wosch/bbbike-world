#!/usr/local/bin/perl
# Copyright (c) 2011-2012 Wolfram Schneider, http://bbbike.org
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
use IO::File;
use JSON;
use Data::Dumper;
use Encode qw/encode_utf8/;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use GIS::Distance::Lite;

use strict;
use warnings;

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/usr/local/www/tmp/extract';

# sent out emails as
my $email_from = 'BBBike Admin <bbbike@bbbike.org>';

my $option = {
    'max_extracts'       => 50,
    'default_format'     => 'osm.pbf',
    'city_name_optional' => 1,
    'max_skm'            => 240_000,     # max. area in square km
    'confirm' => 0,    # request to confirm request with a click on an URL
};

my $formats = {
    'osm.pbf' => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",
};

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

    my @javascript = ();    #"../html/bbbike-js.js";
    my @onload;
    my @cookie;
    if ( $type eq 'homepage' ) {
        push @javascript, "../html/OpenLayers-2.11/OpenLayers.js",
          "../html/OpenLayers-2.11/OpenStreetMap.js",
          "../html/jquery-1.7.1.min.js", "../html/extract.js";
        @onload = ( -onLoad, 'init();' );
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
        -title => 'BBBike @ World extracts',
        -head  => $q->meta(
            {
                -http_equiv => 'Content-Type',
                -content    => 'text/html; charset=utf-8'
            }
        ),

        -style => { 'src' => [ "../html/bbbike.css", "../html/luft.css" ] },
        -script => [ map { { 'src' => $_ } } @javascript ],
        @onload,
      );
}

# see ../html/extract.js
sub map {

    return <<EOF;
<div id="content" class="site_index">

 <div style="width: 100%; display: block;" id="sidebar">
  
  <div id="sidebar_content">

    <span class="export_hint">
      <a href="#" id="drag_box">Manually select a different area</a>  
    </span> - <span id="square_km"></span>

  <div id="export_osm">
    <p class="export_heading"/>
    <div id="export_osm_too_large" style="display:none">
      <p class="export_heading error">Area Too Large. Please zoom in!</p>
      <div class="export_details">
      </div>
    </div>
  </div> <!-- export_bounds -->
  
  </div>
</div><!-- sidebar -->
   
<!-- define a DIV into which the map will appear. Make it take up the whole window -->
<!-- <div style="width:100%; height:100%" id="map"></div> -->
<div style="width:100%; height:450px" id="map"></div>

</div><!-- content -->

EOF

}

sub footer {
    my $q = shift;

    my $analytics = &google_analytics;
    my $url = $q->url( -relative => 1 );

    my $extracts = ( $q->param('submit') || $q->param("key") )
      && $url ? qq,| <a href="$url">extract</a>, : "";
    return <<EOF;
<span id="debug"></span>

<div id="footer">
  <div id="footer_top">
    <a href="../">home</a> $extracts | <a href="../community.html#donate">donate</a>
  </div>
  <hr/>
  <div id="copyright" style="font-size:x-small">
    (&copy;) 2011-2012 <a href="http://www.bbbike.org">BBBike.org</a> 
    by <a href="http://wolfram.schneider.org">Wolfram Schneider</a> //
    Map data by the <a href="http://www.openstreetmap.org/" title="OpenStreetMap License">OpenStreetMap</a> Project
  <div id="footer_community"></div>
  </div>
</div>

</div></div></div> <!-- layout -->

$analytics

</body>
</html>
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
<p>
This site allow you to extracts areas from the <a href="http://wiki.openstreetmap.org/wiki/Planet.osm">planet.osm</a>.
The maximum area size is @{[ large_int($max_skm) ]} square km.
<br/>

It takes between 10-30 minutes to extract an area. You will be notified by e-mail if your extract is ready for download.
</p>
<hr/>
EOF
}

sub layout {
    my $q = shift;

    return <<EOF;
  <div id="all">

    <div id="border">
      <div id="main">

      <center>@{[ $q->h3("BBBike @ World extracts") ]}</center>
EOF
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
    print &layout($q);

    our $error = 0;

    sub error {
        my $message   = shift;
        my $no_escape = shift;

        $error++;

        print "<p>", $no_escape ? $message : escapeHTML($message), "</p>\n";
    }

    sub is_coord {
        my $number = shift;

        return 0 if $number eq "";
        return 0 if $number !~ /^[\-\+]?[0-9]+(\.[0-9]+)?$/;

        return $number <= 180 && $number >= -180 ? 1 : 0;
    }

    sub Param {
        my $param = shift;
        my $data = $qq->param($param) || "";

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

    if ( !exists $formats->{$format} ) {
        error("Unknown error format '$format'");
    }
    if ( $city eq '' ) {
        if ( $option->{'city_name_optional'} ) {
            $city = "none";
        }
        else {
            error("Please give the area a name.");
        }
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
    elsif ( !Email::Valid->address($email) ) {
        error("E-mail address '$email' is not valid.");
    }
    error("sw lat '$sw_lat' is out of range -180 ... 180")
      if !is_coord($sw_lat);
    error("sw lng '$sw_lng' is out of range -180 ... 180")
      if !is_coord($sw_lng);
    error("ne lat '$ne_lat' is out of range -180 ... 180")
      if !is_coord($ne_lat);
    error("ne lng '$ne_lng' is out of range -180 ... 180")
      if !is_coord($ne_lng);

    error("ne lng '$ne_lng' must be larger than sw lng '$sw_lng'")
      if $ne_lng <= $sw_lng;
    error("ne lat '$ne_lat' must be larger than sw lat '$sw_lat'")
      if $ne_lat <= $sw_lat;

    my $skm = square_km( $sw_lat, $sw_lng, $ne_lat, $ne_lng );
    error(
"Area is to large: @{[ large_int($skm) ]} square km, must be smaller than @{[ large_int($max_skm) ]} square km."
    ) if $skm > $max_skm;

    if ($error) {
        print qq{<p class="error">The input data is not valid. };
        print "Please click on the back button of your browser ";
        print "and correct the values!</p>\n";

        print &footer($q);
        return;
    }
    else {
        print <<EOF;
<p>Thanks - the input data looks good. You will be notificed by e-mail soon. 
Please follow the instruction in the email to proceed your request.</p>

<p align='left'>Area: "@{[ escapeHTML($city) ]}" covers @{[ large_int($skm) ]} square km <br/>
Coordinates: @{[ escapeHTML("$sw_lng,$sw_lat x $ne_lng,$ne_lat") ]} <br/>
Format: $format
</p>

<p>Sincerely, your BBBike\@World admin</p>
EOF

    }

    my $obj = {
        'email'  => $email,
        'format' => $format,
        'city'   => $city,
        'sw_lat' => $sw_lat,
        'sw_lng' => $sw_lng,
        'ne_lat' => $ne_lat,
        'ne_lng' => $ne_lng,
        'skm'    => $skm,
        'time'   => time(),
    };

    my $json      = new JSON;
    my $json_text = $json->pretty->encode($obj);

    my ( $key, $json_file ) = &save_request($obj);
    my $mail_error = "";
    if (
        !$key
        || (
            $mail_error = send_email_confirm(
                'q'       => $q,
                'obj'     => $obj,
                'key'     => $key,
                'confirm' => $option->{'confirm'}
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
            print qq{<hr/>\n};
            print
qq{<p>We appreciate any feedback, suggestions and a <a href="../community.html#donate">donation</a>!</p>\n};
        }
    }

    print &footer($q);
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

Sincerely, your BBBike admin

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

    $smtp->mail($from) or die "can't send email from $from\n";
    $smtp->to(@to)     or die "can't use SMTP recipient '$to'\n";
    $smtp->verify(@to) or die "can't verify SMTP recipient '$to'\n";
    if ($confirm) {
        $smtp->data($data) or die "can't email data to '$to'\n";
    }
    $smtp->quit() or die "can't send email to '$to'\n";
}

sub square_km {
    my ( $x1, $y1, $x2, $y2 ) = @_;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    return int( $height * $width );
}

# 240000 -> 240,000
sub large_int {
    my $int = shift;

    return $int if $int < 1_000;

    my $number = substr( $int, 0, -3 ) . "," . substr( $int, -3, 3 );
    return $number;
}

# save request in incoming spool
sub save_request {
    my $obj = shift;

    my $json      = new JSON;
    my $json_text = $json->pretty->encode($obj);

    my $key = md5_hex( encode_utf8($json_text) . rand() );
    my $spool_dir =
      $option->{'confirm'} ? $spool->{"incoming"} : $spool->{"confirmed"};
    my $incoming = "$spool_dir/$key.json.tmp";

    my $fh = new IO::File $incoming, "w";
    binmode $fh, ":utf8";
    if ( !defined $fh ) {
        warn "Cannot open $incoming: $!\n";
        return;
    }

    warn "Store request: $json_text\n" if $debug;
    print $fh $json_text, "\n";
    $fh->close;

    return ( $key, $incoming );
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

    print &message;

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

    print $q->table(
        $q->Tr(
            {},
            [
                $q->td(
                    [
"<span title='Give the city or area to extract a name. The name is optional, but better fill it out to find it later again.'>Name of area to extract</span>",
                        $q->textfield( -name => 'city', -size => 40 )
                    ]
                ),
                $q->td(
                    [
"<span title='Required, you will be notified by e-mail if your extract is ready for download.'>Your email address (*)</span>",
                        $q->textfield(
                            -name  => 'email',
                            -size  => 40,
                            -value => $default_email
                        )
                    ]
                ),
                $q->td(
                    [
"<span title='South West, valid values: -180 .. 180'>Left lower corner (SW)</span>",
                        "$lng: "
                          . $q->textfield(
                            -name => 'sw_lng',
                            -id   => 'sw_lng',
                            -size => 14
                          )
                          . " $lat: "
                          . $q->textfield(
                            -name => 'sw_lat',
                            -id   => 'sw_lat',
                            -size => 14
                          )
                    ]
                ),
                $q->td(
                    [
"<span title='North East, valid values: -180 .. 180'>Right top corner (NE)</span>",
                        "$lng: "
                          . $q->textfield(
                            -name => 'ne_lng',
                            -id   => 'ne_lng',
                            -size => 14
                          )
                          . " $lat: "
                          . $q->textfield(
                            -name => 'ne_lat',
                            -id   => 'ne_lat',
                            -size => 14
                          )
                    ]
                ),

                $q->td(
                    [
"<span title='PBF: fast and compact data, OSM XML gzip: standard OSM format, twice as large'>Output Format</span>",
                        $q->popup_menu(
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

            ]
        )
    );

    #print $q->p;
    print $q->submit(
        -title => 'start extract',
        -name  => 'submit',
        -value => 'extract',

        #-id    => 'extract'
    );
    print $q->end_form;
    print qq{<hr/>\n};
    print &map;

    print &footer($q);

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
