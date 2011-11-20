#!/usr/local/bin/perl
# Copyright (c) 2011 Wolfram Schneider, http://bbbike.org
#
# extracts.cgi - extracts areas in a batch job

use CGI qw/-utf-8 unescape/;

use IO::File;
use JSON;
use Data::Dumper;
use Encode;

use strict;
use warnings;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/var/tmp/bbbike/spool';

# max. area in square km
my $max_skm = 10_000;

# sent out emails as
my $email_from = 'bbbike@bbbike.org';

my $option = {
    'max_extracts'   => 50,
    'min_wait_time'  => 5 * 60,    # in seconds
    'default_format' => 'pbf',
};

my $format = {
    'pbf'     => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
};

######################################################################
#
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

    my $extracts = $q->param('submit') ? qq,| <a href="$url">extracts</a>, : "";
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

    print &header($q);
    print &layout($q);

    print &message;
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
                            -values  => [ sort keys %$format ],
                            -labels  => $format,
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

my $action = $q->param("submit") || "";
if ( $action eq "extract" ) {
    &check_input( 'q' => $q );
}
else {
    &homepage( 'q' => $q );
}

1;
