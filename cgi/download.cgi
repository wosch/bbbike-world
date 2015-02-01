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
use File::Basename;
use HTTP::Date;

use strict;
use warnings;

my $max   = 3000;
my $debug = 2;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $q = new CGI;

our $option = {
    'homepage'        => 'http://download.bbbike.org/osm/extract',
    'script_homepage' => 'http://extract.bbbike.org',

    'supported_languages' => [qw/en de/],
    'message_path'        => "../world/etc/extract",
    'pro'                 => 0,

    # spool directory. Should be at least 100GB large
    'spool_dir' => '/var/cache/extract',

    # cut to long city names
    'max_city_length' => 40,
};

our $formats = {
    'osm.pbf' => 'Protocolbuffer (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",

    'shp.zip'            => "Shapefile (Esri)",
    'garmin-osm.zip'     => "Garmin OSM",
    'garmin-cycle.zip'   => "Garmin Cycle",
    'garmin-leisure.zip' => "Garmin Leisure",

    'garmin-bbbike.zip' => "Garmin BBBike",
    'navit.zip'         => "Navit",
    'obf.zip'           => "Osmand (OBF)",

    'o5m.gz' => "o5m gzip'd",
    'o5m.xz' => "o5m 7z (xz)",

    'opl.xz' => "OPL 7z (xz)",
    'csv.gz' => "csv gzip'd",
    'csv.xz' => "csv 7z (xz)",

    'mapsforge-osm.zip' => "Mapsforge OSM",

    'srtm-europe.osm.pbf'         => 'SRTM Europe PBF (25m)',
    'srtm-europe.garmin-srtm.zip' => 'SRTM Europe Garmin (25m)',
    'srtm-europe.obf.zip'         => 'SRTM Europe Osmand (25m)',

    'srtm.osm.pbf'         => 'SRTM World PBF (40m)',
    'srtm.garmin-srtm.zip' => 'SRTM World Garmin (40m)',
    'srtm.obf.zip'         => 'SRTM World Osmand (40m)',

    #'srtm-europe.mapsforge-osm.zip' => 'SRTM Europe Mapsforge',
    #'srtm-southamerica.osm.pbf' => 'SRTM South America PBF',
};

my $spool = {
    'confirmed' => "confirmed",    # ready to run
    'running'   => "running",      # currently running job
    'osm'       => "osm",          # cache older runs
    'download'  => "download",     # final directory for download
    'trash'     => "trash",        # keep a copy of the config for debugging
    'failed'    => "failed",       # keep record of failed runs
};

sub is_production {
    my $q = shift;

    return 1 if -e "/tmp/is_production";
    return $q->virtual_host() =~ /^extract\.bbbike\.org$/i ? 1 : 0;
}

# sacle file size in x.y MB
sub file_size_mb {
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

# extract areas from trash can
sub extract_areas {
    my $log_dir = shift;
    my $max     = shift;
    my $devel   = shift || 0;

    warn "download: log dir: $log_dir, max: $max, devel: $devel\n" if $debug;

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
    my $json         = new JSON;
    my $download_dir = $option->{"spool_dir"} . "/" . $spool->{"download"};

    my %unique;
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

        my $pbf_file = $download_dir . "/" . basename( $obj->{"pbf_file"} );
        my $format   = $obj->{"format"};

        my $download_file = $pbf_file;
        $download_file =~ s/\.pbf$//;
        my $format_display = $format;
        $format_display =~ s/^(osm|srtm)\.//;

        $download_file .= "." . $format_display;

        if ( !-e $download_file ) {
            warn "ignore missing $download_file\n" if $debug >= 2;
            next;
        }

        if ( $unique{$download_file} ) {
            warn "ignore duplicated $download_file\n" if $debug >= 2;
            next;
        }
        $unique{$download_file} = 1;

        $obj->{"download_file"} = basename($download_file);

        my $st = stat($download_file) or die "stat $download_file: $!\n";
        $obj->{"extract_time"} = $st->mtime;
        $obj->{"extract_size"} = $st->size;

        warn "found download file $download_file\n" if $debug >= 3;

        warn "xxx: ", Dumper($obj) if $debug >= 3;
        push @area, $obj;
    }

    return reverse sort { $a->{"extract_time"} <=> $b->{"extract_time"} } @area;
}

# running or ready to run
sub running_areas {
    my $log_dir = shift;
    my $max     = shift;
    my $devel   = shift || 0;

    warn "download: log dir: $log_dir, max: $max, devel: $devel\n" if $debug;

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
    my $json         = new JSON;
    my $download_dir = $option->{"spool_dir"} . "/" . $spool->{"download"};

    my %unique;
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

        my $pbf_file = $download_dir . "/" . basename( $obj->{"pbf_file"} );
        my $format   = $obj->{"format"};

        my $download_file = $pbf_file;
        $download_file =~ s/\.pbf$//;
        my $format_display = $format;
        $format_display =~ s/^(osm|srtm)\.//;

        $download_file .= "." . $format_display;

        if ( $unique{$download_file} ) {
            warn "ignore duplicated $download_file\n" if $debug >= 2;
            next;
        }
        $unique{$download_file} = 1;

        warn "xxx: ", Dumper($obj) if $debug >= 3;
        push @area, $obj;
    }

    return sort { $a->{"time"} <=> $b->{"time"} } @area;
}

sub footer {
    my %args = @_;
    my $date = $args{'date'};

    return <<EOF;

<div id="bottom">
<p>
  Last update: $date
</p>

<div id="footer">
<div id="footer_top">
<a href="@{[ $option->{'script_homepage'} ]}">home</a> |
<a href="/community.html">donate</a>
<hr>
</div> <!-- footer_top -->

<div id="copyright">
(&copy;) 2008-2015 <a href="http://bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
</div> <!-- copyright -->

</div> <!-- footer -->
</div> <!-- bottom -->
EOF
}

sub css_map {
    return <<EOF;
<style type="text/css">

tbody tr:nth-child(odd)  { background-color: #EEE; }
tbody tr:nth-child(even) { background-color: #FFF; }
tbody tr:nth-child(odd):hover, tr:nth-child(even):hover { background-color:silver; }

tbody tr td:nth-child(1)  { text-align: right; }
tbody tr td:nth-child(2)  { text-align: right; }
tbody tr td:nth-child(3)  { text-align: right; }

table#download td, table.download th {
  border: 1px solid #DDD;
  padding-left: 4px !important;
  padding-right: 4px !important;
}

th { border-left: 1px solid #b9b8b6; }
/* no line breaks in table header */
th { white-space: nowrap; }
tr { border: 0px solid; }

div#bottom {
    margin-top: 2em;
}

h2 { text-aling: center; }
</style>

EOF
}

# osm.pbf -> format_osm_pbf
sub class_format {
    my $format = shift;

    $format =~ s/\./_/g;

    return "format_" . $format;
}

sub result {
    my %args = @_;

    my $type  = $args{'type'};
    my $name  = $args{'name'};
    my $files = $args{'files'};

    my @downloads = @$files;

    if ( !@downloads ) {
        warn "Nothing todo for $type\n" if $debug >= 2;
        return;
    }

    print qq{<h3>$name</h3>\n\n};

    print qq{<table id="$type">\n};
    print qq{<thead>\n<tr>\n}
      . qq{<th>Name of area</th>\n<th>Format</th>\n<th>Size</th><th>Link</th>\n<th>Map</th>\n}
      . qq{</tr>\n</thead>\n};
    print qq{<tbody>\n};

    foreach my $download (@downloads) {
        print "<tr>\n";

        my $date = time2str( $download->{"extract_time"} );
        my $city = $download->{"city"};

        print "<td>";
        print qq{<span title="}
          . escapeHTML($city) . qq{">}
          . escapeHTML( substr( $city, 0, $option->{"max_city_length"} ) )
          . qq{</span>};
        print "</td>\n";

        print "<td>";
        print qq{<span class="}
          . class_format( $download->{"format"} ) . qq{">};
        print escapeHTML( $formats->{ $download->{"format"} } );
        print "</span>";
        print "</td>\n";

        print "<td>";
        print file_size_mb( $download->{"extract_size"} ) . " MB";
        print "</td>\n";

        print "<td>";
        print qq{<a title="$date" href="/osm/extract/}
          . escapeHTML( $download->{"download_file"} )
          . qq{">download</a>};
        print "</td>\n";

        print "<td>";
        print qq{<a href="}
          . escapeHTML( $download->{"script_url"} )
          . qq{">map</a>};
        print "</td>\n";

        print "</tr>\n";
    }
    print "</tbody>\n";
    print "</table>\n";
}

sub header {
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

        -style  => { 'src' => [ "/html/bbbike.css", "/html/luft.css" ] },
        -script => [

            #{ 'src' => "../html/bbbike-js.js" }
            { 'src' => "/html/maps3.js" },
            { 'src' => "/html/bbbike.js" },
            { 'src' => "/html/jquery/jquery-1.8.3.min.js " }
        ],
    );

    print &css_map;
    print
qq{<noscript><p>You must enable JavaScript and CSS to run this application!</p>\n</noscript>\n};
    print qq{<div id="all">\n};
    print qq{  <div id="border">\n};
    print qq{    <div id="main">\n};
}

###########################################################################
#
sub download {
    my $q = shift;

    header($q);

    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 5_000;
    }

    print qq{<div id="intro">\n};
    print $q->h2("Extracts ready to download");

    my $date = time2str(time);
    print <<EOF;
    
<p>
Last update: $date<br/>
Newest extracts are first.
</p>
EOF

    print <<EOF;
<p>
</p>
EOF

    print qq{\n</div> <!-- intro -->\n\n};

    my @extracts;
    @extracts =
      &running_areas( $option->{"spool_dir"} . "/" . $spool->{"confirmed"},
        $max );

#result('type' => 'confirmed', 'name' => 'Waiting extracts', 'files' => \@extracts);

    my @extracts =
      &running_areas( $option->{"spool_dir"} . "/" . $spool->{"running"},
        $max );

#result('type' => 'running', 'name' => 'Running extracts', 'files' => \@extracts);

    @extracts =
      &extract_areas( $option->{"spool_dir"} . "/" . $spool->{"trash"}, $max );
    result(
        'type'  => 'download',
        'name'  => 'Ready extracts',
        'files' => \@extracts
    );

    print &footer( 'date' => $date );

    print qq{    </div> <!-- main -->\n};
    print qq{  </div> <!-- border -->\n};
    print qq{</div> <!-- all -->\n};

    print $q->end_html;
}

##############################################################################################
#
# main
#

&download($q);
