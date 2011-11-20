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
my $max_qkm = 10_000;

# sent out emails as
my $email_from = 'bbbike@bbbike.org';

my $option = {
    'max_extracts'  => 50,
    'min_wait_time' => 5 * 60,    # in seconds
};

my $formats = {
    'pbf'     => 'BPF',
    'osm.gz'  => "OSM XML, gzip'd",
    'osm.bz2' => "OSM XML, bzip'd",
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

    return <<EOF;


<div id="footer">
<div id="footer_top">
<a href="../">home</a> 
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
This site allow you to extracts areas from the <a href="http://wiki.openstreetmap.org/wiki/Planet.osm">planet.osm</a>.<br/>

It takes between 30-120 minutes to extract an area. You will be notified by e-mail if your extract is ready.
</p>
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
                        "Left lower corner (lat,lng)",
                        $q->textfield( -name => 'sw_latlng', -size => 20 )
                    ]
                ),
                $q->td(
                    [
                        "Right top corner (lat,lng)",
                        $q->textfield( -name => 'no_latlng', -size => 20 )
                    ]
                )
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

if (1) {
    &homepage( 'q' => $q );
}

1;
