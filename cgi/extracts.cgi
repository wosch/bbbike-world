#!/usr/local/bin/perl
# Copyright (c) 2011 Wolfram Schneider, http://bbbike.org
#
# extracts.cgi - extracts areas in a batch job

use CGI qw/-utf-8 unescape escapeHTML/;
use IO::File;
use JSON;
use Data::Dumper;
use Encode;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use GIS::Distance::Lite;

use strict;
use warnings;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/var/tmp/bbbike/extracts';

# max. area in square km
my $max_skm = 50_000;

# sent out emails as
my $email_from = 'BBBike Admin <bbbike@bbbike.org>';

my $option = {
    'max_extracts'   => 50,
    'min_wait_time'  => 5 * 60,    # in seconds
    'default_format' => 'pbf',
};

my $formats = {
    'pbf'     => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
};

my $spool = {
    'incoming'  => "$spool_dir/incoming",
    'confirmed' => "$spool_dir/confirmed",
    'running'   => "$spool_dir/running",
};

# group writable file
umask(002);

######################################################################
# helper functions
#

sub header {
    my $q = shift;

    return $q->header( -charset => 'utf-8' ) .

      $q->start_html(
        -title => 'BBBike @ World extracts',
        -head  => $q->meta(
            {
                -http_equiv => 'Content-Type',
                -content    => 'text/html; charset=utf-8'
            }
        ),

        -style => { 'src' => [ "../html/bbbike.css", "../html/luft.css" ] },
        -script => [ { 'src' => "/html/bbbike-js.js" } ],
      );
}

sub footer {
    my $q = shift;

    my $analytics = &google_analytics;
    my $url = $q->url( -relative => 1 );

    my $extracts = $q->param('submit')
      || $q->param("key") ? qq,| <a href="$url">extracts</a>, : "";
    return <<EOF;


<div id="footer">
<div id="footer_top">
<a href="../">home</a> $extracts 
</div>
<div id="copyright" style="text-align: center; font-size: x-small; margin-top: 1em;" >
<hr/>
(&copy;) 2011 <a href="http://bbbike.org">BBBike.org</a> 
by <a href="http://wolfram.schneider.org">Wolfram Schneider</a> //
Map data by the <a href="http://www.openstreetmap.org/" title="OpenStreetMap License">OpenStreetMap</a> Project
<div id="footer_community">
</div>
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
The maximum area size is $max_skm square km.
<br/>

It takes between 30-120 minutes to extract an area. You will be notified by e-mail if your extract is ready for download.
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

sub check_input {
    my %args = @_;

    my $q = $args{'q'};
    our $qq = $q;

    print &header($q);
    print &layout($q);

    our $error = 0;

    sub error {
        my $message = shift;
        $error++;

        print "<p>", escapeHTML($message), "</p>\n";
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
        error("Please give the area a name.");
    }
    if ( $email eq '' ) {
        error("Please enter a e-mail address.");
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
    error("Area is to large: $skm, must be smaller than $max_skm")
      if $skm > $max_skm;

    if ($error) {
        print qq{<p class="error">The input data is not valid. };
        print "Please click on the back button of your browser ";
        print "and correct the values!</p>\n";

        print &footer($q);
        return;
    }
    else {
        print "<p>Thanks - the input data looks good. ",
          "You will be notificed by e-mail soon.",
          "Please follow the instruction in the email ",
          "to proceed your request.</p>\n",
          "<p>Sincerely, your BBBike\@World admin</p>\n";
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

    my $key = &save_request($obj);
    if (
        !(
            $key
            && send_email_confirm( 'q' => $q, 'obj' => $obj, 'key' => $key )
        )
      )
    {
        print
          qq{<p class="error">I'm so sorry, I could not save your request.\n},
          qq{Please contact the BBBike.org maintainer!</p>};
    }
    else {
        print qq{<p class="success">E-Mail was sent out successfully.</p>\n};
    }

    print &footer($q);
}

# save request in incoming spool
sub send_email_confirm {
    my %args = @_;

    my $obj = $args{'obj'};
    my $key = $args{'key'};
    my $q   = $args{'q'};

    my $url = $q->url( -full => 1, -absolute => 1 ) . "?key=$key";

    my $message = <<EOF;
Hi,

somone - possible you - requested to extract an area from planet.osm

 City: $obj->{"city"}
 Area: $obj->{"sw_lat"},$obj->{"sw_lng"} x $obj->{"ne_lat"},$obj->{"ne_lng"}
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
            "Please confirm planet.osm extract request", $message );
    };
    if ($@) {
        warn "$@";
        return 0;
    }

    return 1;
}

sub send_email {
    my ( $to, $subject, $text ) = @_;
    my $mail_server = "localhost";
    my @to = split /,/, $to;

    my $from = $email_from;
    my $data = "From: $from\nTo: $to\nSubject: $subject\n\n$text";
    my $smtp = new Net::SMTP( $mail_server, Hello => "localhost" )
      or die "can't make SMTP object";

    $smtp->mail($from) or die "can't send email from $from";
    $smtp->to(@to)     or die "can't use SMTP recipient '$to'";
    $smtp->data($data) or die "can't email data to '$to'";
    $smtp->quit()      or die "can't send email to '$to'";
}

sub square_km {
    my ( $x1, $y1, $x2, $y2 ) = @_;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 );
    my $width  = GIS::Distance::Lite::distance( $x2, $y1 => $x2, $y2 );

    return int( $height / 1_000 * $width / 1_000 );
}

# save request in incoming spool
sub save_request {
    my $obj = shift;

    my $json      = new JSON;
    my $json_text = $json->pretty->encode($obj);

    my $key      = md5_hex( $json_text . rand() );
    my $incoming = $spool->{"incoming"} . "/$key.json";

    my $fh = new IO::File $incoming, "w";
    if ( !defined $fh ) {
        warn "Cannot open $incoming: $!\n";
        return 0;
    }
    print $fh $json_text, "\n";
    $fh->close;

    return $key;
}

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
qq{<p class="error">I'm so sorry, I could find a key for your request.\n},
          qq{Please contact the BBBike.org maintainer!</p>};
    }
    else {
        print
          qq{<p class="success">Thanks - your request has been confirmed.\n},
qq{The extract will be ready in 30-120 minutes. You will be notified by e-mail\n};
    }

    print &footer($q);
}

sub homepage {
    my %args = @_;

    my $q = $args{'q'};

    print &header($q);
    print &layout($q);

    print &message;

    print $q->start_form( -method => 'GET' );

    print $q->table(
        $q->Tr(
            {},
            [
                $q->td(
                    [
                        "Name of city or area",
                        $q->textfield( -name => 'city', -size => 40 )
                    ]
                ),
                $q->td(
                    [
                        "Your email address",
                        $q->textfield( -name => 'email', -size => 40 )
                    ]
                ),
                $q->td(
                    [
                        "Left lower corner (SW)",
                        "lat: "
                          . $q->textfield( -name => 'sw_lat', -size => 14 )
                          . " lng: "
                          . $q->textfield( -name => 'sw_lng', -size => 14 )
                    ]
                ),
                $q->td(
                    [
                        "Right top corner (NE)",
                        "lat: "
                          . $q->textfield( -name => 'ne_lat', -size => 14 )
                          . " lng: "
                          . $q->textfield( -name => 'ne_lng', -size => 14 )
                    ]
                ),

                $q->td(
                    [
                        "Output Format",
                        $q->popup_menu(
                            -name    => 'format',
                            -values  => [ sort keys %$formats ],
                            -labels  => $formats,
                            -default => $option->{'default_format'}
                        )
                    ]
                ),

            ]
        )
    );

    print $q->p;
    print $q->submit( -name => 'submit', -value => 'extract' );
    print $q->end_form;

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
