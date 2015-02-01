#!/usr/local/bin/perl -T
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# download.cgi - extractbbbike.org live extracts

use CGI qw/-utf-8 unescape escapeHTML/;
use CGI::Carp;
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

my $max   = 25;
my $debug = 1;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $q = new CGI;

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

    warn "extract route: log dir: $log_dir, max: $max\n" if $debug;

    my %hash;
    my $dh = IO::Dir->new($log_dir) or die "open $log_dir: $!\n";

    while ( defined( my $file = $dh->read ) ) {
        next if $file !~ /\.json$/;

        my $f = "$log_dir/$file";
        my $st = stat($f) or die "stat $f: $!\n";
        $hash{$f} = $st->mtime;
    }
    $dh->close;

    # newest first
    my @list = reverse sort { $hash{$a} <=> $hash{$b} } keys %hash;

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

        push @area, $obj;
    }

    return @area;
}

sub footer {
    my $q = new CGI;

    return <<EOF;

<div id="bottom">
<div id="footer">
<div id="footer_top">
<a href="../">home</a>
</div>
</div>

<div id="copyright">
<hr>
(&copy;) 2008-2015 <a href="http://bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
<div id="footer_community">
</div>
</div> <!-- footer -->
</div> <!-- bottom -->
EOF
}

sub css_map {
    return <<EOF;
<style type="text/css">
</style>

EOF
}

#
sub download {
    my $q = shift;

    my $ns = $q->param("namespace") || $q->param("ns") || "";
    $ns = "text" if $ns =~ /^(text|ascii|plain)$/;

    print $q->header( -charset => 'utf-8', -expires => '+30m' );

    print $q->start_html(
        -title => 'BBBike extract livesearch',
        -head  => [
            $q->meta(
                {
                    -http_equiv => 'Content-Type',
                    -content    => 'text/html; charset=utf-8'
                }
            ),
            $q->meta(
                { -name => "robots", -content => "nofollow,noindex,noarchive" }
            ),
            $q->meta(
                { -rel => "shortcut icon", -href => "/images/srtbike16.gif" }
            )
        ],

        -style  => { 'src' => ["../html/bbbike.css"] },
        -script => [

            #{ 'src' => "../html/bbbike-js.js" }
            { 'src' => "/html/maps3.js" },
            { 'src' => "/html/bbbike.js" },
            { 'src' => "/html/jquery/jquery-1.8.3.min.js " }
        ],
    );

    print &css_map;
    print qq{<div id="sidebar">\n\t<div id="formats"></div>\n</div>\n\n};

    print <<'EOF';
    <script type="text/javascript">
    </script>
EOF

    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 5_000;
    }

    my $date = $q->param('date') || "";
    my $stat = $q->param('stat') || "name";
    my @d = &extract_areas( $log_dir, $max * 1.5, &is_production($q), $date );

    print
qq{<noscript><p>You must enable JavaScript and CSS to run this application!</p>\n</noscript>\n};
    print "</div>\n";

    #print "<pre>" . Dumper(\@d) . "</pre>";

    print &footer;

    print $q->end_html;
}

##############################################################################################
#
# main
#

&download($q);
