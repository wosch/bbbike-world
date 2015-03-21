#!/usr/local/bin/perl -T
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# extract-download.cgi - extract.bbbike.org live extracts

use CGI qw/-utf-8 unescape escapeHTML/;
use CGI::Carp;

use IO::File;
use JSON;
use Data::Dumper;
use File::stat;
use File::Basename;
use HTTP::Date;

use lib qw[../world/lib ../lib];
use BBBikeLocale;
use BBBikeAnalytics;

use strict;
use warnings;

###########################################################################
# config
my $max          = 2000;
my $debug        = 0;
my $default_date = "36h";    # 36h: today and some hours from yesterday

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $q = new CGI;

if ( defined $q->param('debug') ) {
    $debug = int( $q->param('debug') );
}

our $option = {
    'homepage_download'    => 'http://download.bbbike.org/osm/',
    'homepage_extract'     => 'http://extract.bbbike.org',
    'homepage_extract_pro' => 'http://extract-pro.bbbike.org',

    'message_path' => "../world/etc/extract",
    'pro'          => 0,

    # spool directory. Should be at least 100GB large
    'spool_dir'     => '/var/cache/extract',
    'spool_dir_pro' => '/var/cache/extract-pro',

    # cut to long city names
    'max_city_length' => 38,

    'show_heading' => 0,

    'enable_google_analytics' => 1,
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

# EOF config
###########################################################################

sub M { return BBBikeLocale::M(@_); };    # wrapper

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
    my %args = @_;

    my $log_dir = $args{'log_dir'};
    my $max     = $args{'max'};
    my $devel   = $args{'devel'} || 0;
    my $sort_by = $args{'sort_by'} || "time";
    my $date    = $args{'date'} || "";

    warn
      "download: log dir: $log_dir, max: $max, devel: $devel, date: '$date'\n"
      if $debug;

    my %hash;
    foreach my $f ( glob("$log_dir/*.json") ) {
        my $st = stat($f) or die "stat $f: $!\n";
        $hash{$f} = $st->mtime;
    }

    # newest first
    my @list = reverse sort { $hash{$a} <=> $hash{$b} } keys %hash;

    my @area;
    my $json         = new JSON;
    my $download_dir = $option->{"spool_dir"} . "/" . $spool->{"download"};
    my $time         = time();

    my %unique;
    for ( my $i = 0 ; $i < scalar(@list) && $i < $max ; $i++ ) {
        my $file = $list[$i];
        my $fh = new IO::File $file, "r" or die "open $file: $!\n";
        binmode $fh, ":utf8";

        my $data = "";
        while (<$fh>) {
            $data .= $_;
        }

        my $obj;
        eval { $obj = $json->decode($data) };
        if ($@) {
            warn "Cannot parse json file $file: $@\n";
            next;
        }

        next if !exists $obj->{'date'};

        my $pbf_file = $download_dir . "/" . basename( $obj->{"pbf_file"} );
        my $format   = $obj->{"format"};

        my $download_file = $pbf_file;
        $download_file =~ s/\.pbf$//;
        my $format_display = $format;
        $format_display =~ s/^(osm|srtm|srtm-europe)\.//;

        $download_file .= "." . $format_display;

        # other languages ?
        my $lang = $obj->{"lang"};
        if ( $lang ne "en" && $lang ne "" ) {
            $download_file =~ s/\.zip$/.${lang}.zip/;
        }

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

        if ( $date =~ /^(\d+)h$/ ) {
            my $hours = $1;
            if ( $obj->{"extract_time"} + $hours * 3600 < $time ) {
                warn "filtered by $hours: $download_file\n" if $debug >= 2;
                next;
            }
        }

        warn "found download file $download_file\n" if $debug >= 3;

        warn "xxx: ", Dumper($obj) if $debug >= 3;
        push @area, $obj;
    }

    return sort_extracts( $sort_by, @area );
}

sub sort_extracts {
    my $sort_by = shift;
    my @area    = @_;

    # newest first, or otherwise
    if ( $sort_by eq 'name' ) {
        return sort { $a->{"city"} cmp $b->{"city"} } @area;
    }
    elsif ( $sort_by eq 'format' ) {
        return sort {
                $a->{"format"} cmp $b->{"format"}
              ? $a->{"format"} cmp $b->{"format"}
              : ( $a->{"extract_size"} <=> $b->{"extract_size"} ) * -1
        } @area;
    }
    elsif ( $sort_by eq 'size' ) {
        return
          reverse sort { $a->{"extract_size"} <=> $b->{"extract_size"} } @area;
    }
    else {
        return
          reverse sort { $a->{"extract_time"} <=> $b->{"extract_time"} } @area;
    }
}

# running or ready to run
sub running_extract_areas {
    my %args = @_;

    my $log_dir = $args{'log_dir'};
    my $max     = $args{'max'};
    my $devel   = $args{'devel'} || 0;
    my $sort_by = $args{'sort_by'} || "time";

    warn "download: log dir: $log_dir, max: $max, devel: $devel\n" if $debug;

    my %hash;
    foreach my $f ( glob("$log_dir/*.json"), glob("$log_dir/*/*.json") ) {
        my $st = stat($f) or die "stat $f: $!\n";
        $hash{$f} = $st->mtime;
    }

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

        my $obj;
        eval { $obj = $json->decode($data); };
        if ($@) {
            warn "Cannot parse json file $file: $@\n";
            next;
        }

        next if !exists $obj->{'date'};
        my $script_url = $obj->{"script_url"};

        if ( $unique{$script_url} ) {
            warn "ignore duplicated $script_url\n" if $debug >= 2;
            next;
        }
        $unique{$script_url} = 1;

        warn "xxx: ", Dumper($obj) if $debug >= 3;
        push @area, $obj;
    }

    return reverse sort { $a->{"time"} <=> $b->{"time"} } @area;
}

sub footer {
    my %args = @_;
    my $date = $args{'date'};

    return <<EOF;
    
<p align="center"><a href="/community.html"><img src="/images/btn_donateCC_LG.gif" alt="donate" /></a></p>

<div id="bottom">
<p>
  @{[ M("Last update") ]}: $date
</p>

<div id="footer">
  <div id="footer_top">
    <a href="@{[ $option->{'homepage_download'} ]}">home</a> |
    <a href="/extract.html">@{[ M("help") ]}</a> |
    <a href="/community.html">@{[ M("donate") ]}</a>
    <hr/>
  </div> <!-- footer_top -->

  <div id="copyright">
    (&copy;) 2008-2015 <a href="http://bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="http://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
  </div> <!-- copyright -->

</div> <!-- footer -->

</div> <!-- bottom -->
</div> <!-- nomap -->
EOF
}

sub load_javascript_libs {
    my @js = qw(
      OpenLayers/2.12/OpenLayers-min.js
      OpenLayers/2.12/OpenStreetMap.js
      jquery/jquery-1.8.3.min.js
      extract-download.js
    );

    my $javascript = join "\n",
      map { qq{<script src="/html/$_" type="text/javascript"></script>} } @js;

    my $dom_ready = <<'EOF';
    
<script type="text/javascript">
$(document).ready(function () {
    download_init_map();
    parse_areas_from_links();
});
</script>
EOF

    return $javascript . $dom_ready;
}

sub css_map {
    return <<EOF;
EOF
}

# osm.pbf -> format_osm_pbf
sub class_format {
    my $format = shift;

    $format =~ s/[\.\-]/_/g;

    return "format_" . $format;
}

sub statistic {
    my %args = @_;

    my $files     = $args{'files'};
    my $summary   = $args{'summary'};
    my @downloads = @$files;

    print qq{<h3>@{[ M("Statistic") ]}</h3>\n\n};

    if ( !@downloads ) {
        print qq{<p>@{[ M("None") ]}</p>\n};
        print "<hr/>\n\n";
        return;
    }

    print qq{<p>@{[ M("Number of extracts") ]}: }
      . scalar(@downloads)
      . qq{</p>\n};

    sub strip_format {
        my $f = shift;
        $f =~ s/\-.*//;
        $f =~ s/\..*//;
        return $f;
    }

    my %format_counter;
    my %format_counter_all;
    foreach my $download (@downloads) {
        $format_counter{ $download->{"format"} } += 1;
        $format_counter_all{ strip_format( $download->{"format"} ) } += 1;
    }

    foreach my $f (
        reverse sort { $format_counter{$a} <=> $format_counter{$b} }
        keys %format_counter
      )
    {
        print qq{<span class="}
          . class_format($f)
          . qq{" title="}
          . sprintf( "%2.2f", $format_counter{$f} * 100 / scalar(@downloads) )
          . qq{%">};
        print $formats->{$f} . " (" . $format_counter{$f} . ")";
        print "</span><br/>\n";
    }
    print "<hr/>\n\n";

    return if !$summary;
    foreach my $f (
        reverse sort { $format_counter_all{$a} <=> $format_counter_all{$b} }
        keys %format_counter_all
      )
    {
        print qq{<span title="} . $format_counter_all{$f} . qq{">};
        printf( "%s (%2.2f%%)",
            $f, $format_counter_all{$f} * 100 / scalar(@downloads) );
        print "</span><br/>\n";
    }
    print "<hr/>\n\n";
}

sub result {
    my %args = @_;

    my $type    = $args{'type'};
    my $name    = $args{'name'};
    my $files   = $args{'files'};
    my $message = $args{'message'};

    my @downloads = @$files;

    print qq{<h4 title="}
      . scalar(@downloads)
      . qq{ extracts">@{[ M($name) ]}</h4>\n\n};

    if ( !@downloads ) {
        warn "Nothing todo for $type\n" if $debug >= 2;
        print qq{<p>@{[ M("None") ]}</p>\n};
        print "<hr/>\n\n";
        return;
    }

    if ($message) {
        print qq{<p>@{[ M($message) ]}</p>\n\n};
    }

    print qq{<table id="$type">\n};
    print qq{<thead>\n<tr>\n};

    table_head( $type, 'name',   M("Name of area") );
    table_head( $type, 'format', M("Format") );
    table_head( $type, 'size',   M("Size") );

    print qq{<th>Link</th>\n<th>@{[ M("Map") ]}</th>\n} . qq{</tr>\n</thead>\n};
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
        if ( $download->{"extract_size"} ) {
            print file_size_mb( $download->{"extract_size"} ) . " MB";
        }
        else {
            print "-";
        }
        print "</td>\n";

        # download link if available
        print "<td>";
        if ( $download->{"download_file"} ) {

            print qq{<a title="$date" href="/osm/extract/}
              . escapeHTML( $download->{"download_file"} )
              . qq{">download</a>};
        }
        else {
            print "-";
        }
        print "</td>\n";

        print "<td>";
        my @coords = @{ $download->{"coords"} };
        print qq{<a class="polygon}
          . ( scalar(@coords) ? 1 : 0 )
          . qq{" title="}
          . ( scalar(@coords) ? "polygon" : "rectangle" )
          . qq{" href="}
          . escapeHTML( $download->{"script_url"} )
          . qq{">map</a>};
        print "</td>\n";

        print "</tr>\n";
    }
    print "</tbody>\n";
    print "</table>\n";
    print "<hr/>\n\n";
}

# sort table by name, size, format
sub table_head {
    my ( $type, $sort_by, $name ) = @_;

    my $q = new CGI;

    print "<th>";

    my $sort_by_param = $q->param("sort_by") || "";
    if ( $type eq 'download' && $sort_by ne $sort_by_param ) {
        $q->param( "sort_by", $sort_by );
        print $q->a(
            {
                href  => $q->url( -query => 1, -relative => 1 ),
                title => "Sort by $name"
            },
            $name
        );
    }
    else {
        print $name;
    }

    print "</th>";
}

sub download_header {
    my $q = shift;

    my $ns = $q->param("namespace") || $q->param("ns") || "";
    $ns = "text" if $ns =~ /^(text|ascii|plain)$/;

    print $q->header( -charset => 'utf-8', -expires => '+0s' );

    print $q->start_html(
        -title => 'Extracts ready to download | BBBike.org',
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
            $q->Link(
                { -rel => "shortcut icon", -href => "/images/srtbike16.gif" }
            )
        ],

        -style => {
            'src' => [ "/html/bbbike.css", "/html/extract-download.css" ],
            -code => &css_map
        },

        #-script => [
        #    { 'src' => "/html/bbbike.js" },
        #    { 'src' => "/html/jquery/jquery-1.8.3.min.js " }
        #],
    );

# print qq{<noscript><p>}, qq{You must enable JavaScript and CSS to run this application!}, qq{</p>\n</noscript>\n};
    print qq{<div id="all">\n};
    print qq{  <div id="border">\n};
    print qq{    <div id="main">\n};
}

sub filter_date {
    my %args = @_;

    my $filter_date    = $args{'filter_date'};
    my $current_filter = $args{'date'};

    sub display_filter {
        my $filter = shift;
        return $filter =~ /^d+/ ? $filter : M($filter);
    }

    my $q    = new CGI;
    my $data = "";

    foreach my $filter (@$filter_date) {
        $q->param( "date", $filter );
        $data .= " |\n" if $data;
        $data .=
            $filter eq $current_filter
          ? &display_filter($filter)
          : $q->a( { href => $q->url( -query => 1, -relative => 1 ) },
            &display_filter($filter) );
    }

    print M("Limit to date") . ": $data\n\n";
}

###########################################################################
#
sub download {
    my $q = shift;
    my $locale = BBBikeLocale->new( 'q' => $q );

    download_header($q);
    my @filter_date = qw/1h 3h 6h 12h 24h 36h 48h 72h all/;

    if ( $q->param('max') ) {
        my $m = $q->param('max');
        $max = $m if $m > 0 && $m <= 5_000;
    }

    my $date = $q->param('date') || $default_date;
    if ( $date ne "" && !grep { $date eq $_ } @filter_date ) {
        warn "Reset date: '$date'\n" if $debug;
        $date = "";
    }

    print qq{      <div id="intro">\n};
    print $q->h2( qq{<a href="}
          . $q->url( -relative => 1 )
          . qq{">Extracts ready to download</a>} )
      if $option->{'show_heading'};

    print <<EOF;
        <span id="noscript"><noscript>Please enable JavaScript in your browser. Thanks!</noscript></span>
        <div id="map" style="height:320px"></div>

        <span id="debug"></span>

        <div id="nomap">
EOF

    print $locale->language_links( 'with_separator' => 1 );

    my $current_date = time2str(time);

    print <<EOF;
    
<table id="donate">
  <tr>
    <td>@{[ M("Newest extracts are first") ]}. @{[ M("Last update") ]}: $current_date</td>
    <td><a href="/community.html"><img src="/images/btn_donateCC_LG.gif" alt="donate" /></a></td>
  </tr>
</table>

EOF

    print <<EOF;
<p>
</p>
EOF

    print qq{\n</div> <!-- intro -->\n\n};

    my @extracts;
    my $spool_dir = $option->{"spool_dir"};
    @extracts = &running_extract_areas(
        'log_dir' => "$spool_dir/" . $spool->{"confirmed"},
        'max'     => $max
    );
    result(
        'type'    => 'confirmed',
        'files'   => \@extracts,
        'name'    => 'Waiting extracts',
        'message' => 'Will start in the next 5 minutes.',
    );

    @extracts = &running_extract_areas(
        'log_dir' => "$spool_dir/" . $spool->{"running"},
        'max'     => $max
    );
    result(
        'type'    => 'running',
        'files'   => \@extracts,
        'name'    => 'Running extracts',
        'message' => 'Will be ready in the next 5-30 minutes.',
    );

    my $sort_by = $q->param('sort_by') || $q->param("sort");
    @extracts = &extract_areas(
        'log_dir' => "$spool_dir/" . $spool->{"trash"},
        'max'     => $max,
        'sort_by' => $sort_by,
        'date'    => $date
    );
    result(
        'type'  => 'download',
        'name'  => 'Ready extracts',
        'files' => \@extracts
    );

    filter_date( 'filter_date' => \@filter_date, 'date' => $date );
    statistic( 'files' => \@extracts, 'summary' => 1 );

    print &footer( 'date' => $current_date );

    print qq{    </div> <!-- main -->\n};
    print qq{  </div> <!-- border -->\n};
    print qq{</div> <!-- all -->\n};

    # load javascript code late
    print &load_javascript_libs;
    print $option->{"enable_google_analytics"}
      ? BBBikeAnalytics->new( 'q' => $q )->google_analytics
      : "";

    print $q->end_html;
}

# re-set values for extract-pro service
sub check_extract_pro {
    my $q = shift;

    return if !$q->param("pro");

    foreach my $key (qw/homepage_extract spool_dir/) {
        my $key_pro = $key . "_pro";
        $option->{$key} = $option->{$key_pro};
    }

    $option->{"pro"} = 1;
}

##############################################################################################
#
# main
#
&check_extract_pro($q);
&download($q);
