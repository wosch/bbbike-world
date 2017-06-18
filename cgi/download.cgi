#!/usr/local/bin/perl -T
# Copyright (c) 2012-2017 Wolfram Schneider, https://bbbike.org
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
use Extract::Config;
use Extract::Utils;
use Extract::Locale;
use BBBike::Analytics;

use strict;
use warnings;

###########################################################################
# config

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

$ENV{PATH} = "/bin:/usr/bin";

our $option = {
    'debug'                => "0",
    'homepage_download'    => '//download.bbbike.org/osm/',
    'homepage_extract'     => '//extract.bbbike.org',
    'homepage_extract_pro' => '//extract-pro.bbbike.org',

    'message_path' => "../world/etc/extract",
    'pro'          => 0,

    # spool directory. Should be at least 100GB large
    'spool_dir'     => '/var/cache/extract',
    'spool_dir_pro' => '/var/cache/extract-pro',

    'download'     => '/osm/extract/',
    'download_pro' => '/osm/extract-pro/',

    # cut to long city names
    'max_city_length' => 38,

    'show_heading' => 0,

    'enable_google_analytics' => 1,
};

my $q   = new CGI;
my $max = 2000;

#my $default_date = "36h";     # 36h: today and some hours from yesterday
my $default_date  = "24h";    # 24h: today
my $filter_format = "";       # all formats

my $debug = $option->{'debug'};
if ( defined $q->param('debug') ) {
    $debug = int( $q->param('debug') );
}
if ( defined $q->param('format') ) {
    $filter_format = $q->param('format');
}

my $extract_utils = new Extract::Utils;
my $extract = Extract::Config->new( 'q' => $q, 'option' => $option );

$extract->load_config;
$extract->check_extract_pro;
my $formats = $Extract::Config::formats;
my $spool   = $Extract::Config::spool;

# EOF config
###########################################################################

sub M { return Extract::Locale::M(@_); };    # wrapper

# extract areas from trash can
sub extract_areas {
    my %args = @_;

    my $log_dir       = $args{'log_dir'};
    my $max           = $args{'max'};
    my $devel         = $args{'devel'} || 0;
    my $sort_by       = $args{'sort_by'} || "time";
    my $date          = $args{'date'} || "";
    my $filter_format = $args{'filter_format'} || "";

    warn
"download: log dir: $log_dir, max: $max, devel: $devel, date: '$date', format='$filter_format'\n"
      if $debug;

    my %hash;
    foreach my $f (`find $log_dir/ -name '*.json' -mtime -6 -print`) {
        chomp $f;
        my $st = stat($f) or die "stat $f: $!\n";
        $hash{$f} = $st->mtime;
    }

    # newest first
    my @list = reverse sort { $hash{$a} <=> $hash{$b} } keys %hash;

    my @area;
    my $download_dir = $option->{"spool_dir"} . "/" . $spool->{"download"};
    my $time         = time();

    my %unique;
    for ( my $i = 0 ; $i < scalar(@list) && $i < $max ; $i++ ) {
        my $file = $list[$i];
        my $obj = $extract_utils->parse_json_file( $file, 1 );

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

        if ( $filter_format ne "" ) {
            if ( index( $obj->{"format"}, $filter_format ) == -1 ) {
                warn
"filtered by $format: $download_file, $obj->{'format'} != $filter_format\n"
                  if $debug >= 2;
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

    my $homepage_extract = $option->{'homepage_extract'};
    return <<EOF;

<p align="center"><a href="$homepage_extract/community.html"><img src="/images/btn_donateCC_LG.gif" alt="donate" /></a></p>

<div id="bottom">
<p>
@{[ M("Last update") ]}: $date
</p>

<div id="footer">
<div id="footer_top">
<a href="@{[ $option->{'homepage_download'} ]}">home</a> |
<a href="$homepage_extract/extract.html">@{[ M("help") ]}</a> |
<a href="$homepage_extract/community.html">@{[ M("donate") ]}</a>
<hr/>
</div> <!-- footer_top -->

<div id="copyright">
(&copy;) 2008-2017 <a href="https://www.bbbike.org">BBBike.org</a> // Map data (&copy;) <a href="https://www.openstreetmap.org/copyright" title="OpenStreetMap License">OpenStreetMap.org</a> contributors
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
        print qq{<p>@{[ M("none") ]}</p>\n};
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

    my $sub_title = "";
    if ( !@downloads ) {
        warn "Nothing todo for $type\n" if $debug >= 2;
        $sub_title = ": " . M("none");
    }
    elsif ($message) {
        $sub_title = ": " . M($message);
    }

    print qq{<h4 title="}
      . scalar(@downloads)
      . qq{ extracts">@{[ M($name) ]}$sub_title</h4>\n\n};

    # no waiting or running extracts - done
    return if !@downloads;

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

        # name of area
        print "<td>";
        print qq{<span title="}
          . escapeHTML($city) . qq{">}
          . escapeHTML( substr( $city, 0, $option->{"max_city_length"} ) )
          . qq{</span>};
        print "</td>\n";

        # Format
        print "<td>";
        print qq{<span class="}
          . class_format( $download->{"format"} ) . qq{">};
        print escapeHTML( $formats->{ $download->{"format"} } );
        print "</span>";
        print "</td>\n";

        # size (in MB)
        print "<td>";
        if ( $download->{"extract_size"} ) {
            print kb_to_mb( $download->{"extract_size"} ) . " MB";
        }
        else {
            print "-";
        }
        print "</td>\n";

        # download link if available
        print "<td>";
        if ( $download->{"download_file"} ) {
            my $prefix = $option->{"download"};

            print qq{<a title="$date" href="$prefix}
              . escapeHTML( $download->{"download_file"} )
              . qq{">download</a>};
        }
        else {
            print "-";
        }
        print "</td>\n";

        print "<td>";
        my @coords = @{ $download->{"coords"} };

        # protocol independent links
        my $script_url = $download->{"script_url"};
        $script_url =~ s,^http:,,;

        print qq{<a class="polygon}
          . ( scalar(@coords) ? 1 : 0 )
          . qq{" title="}
          . ( scalar(@coords) ? "polygon" : "rectangle" )
          . qq{" href="}
          . escapeHTML($script_url)
          . qq{">map</a>};
        print "</td>\n";

        print "</tr>\n";
    }
    print "</tbody>\n";
    print "</table>\n";
    print "<hr/>\n\n";
}

sub uniqe_users {
    my @extracts_trash = @_;

    my %hash;
    foreach my $download (@extracts_trash) {
        $hash{ $download->{"email"} } += 1;
    }

    return scalar( keys %hash );
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
            'src' => ["/html/extract-download.css"],
            -code => &css_map
        },

        #-script => [
        #    { 'src' => "/html/bbbike.js" },
        #    { 'src' => "/html/jquery/jquery-1.8.3.min.js " }
        #],
    );

# print qq{<noscript><p>}, qq{You must enable JavaScript and CSS to run this application!}, qq{</p>\n</noscript>\n};
    print qq{<div id="all">\n};

    #print qq{  <div id="border">\n};
    #print qq{    <div id="main">\n};
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
    my $locale = Extract::Locale->new( 'q' => $q );

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

    print qq{<div id="map_area">\n};
    print $q->h2( qq{<a href="}
          . $q->url( -relative => 1 )
          . qq{">Extracts ready to download</a>} )
      if $option->{'show_heading'};

    print <<EOF;
<span id="noscript"><noscript>Please enable JavaScript in your browser. Thanks!</noscript></span>
<div id="map" style="height:480px"></div> <!-- map -->
<div id="map_after">
<span id="debug"></span>

EOF

    print $locale->language_links( 'with_separator' => 1 );

    my $current_date     = time2str(time);
    my $homepage_extract = $option->{'homepage_extract'};
    my $spool_dir        = $option->{"spool_dir"};

    my @extracts = ();

    my $sort_by = $q->param('sort_by') || $q->param("sort");
    my @extracts_trash = &extract_areas(
        'log_dir'       => "$spool_dir/" . $spool->{"trash"},
        'max'           => $max,
        'sort_by'       => $sort_by,
        'filter_format' => $filter_format,
        'date'          => $date
    );

    print <<EOF;

<table id="donate">
<tr>
<td>
 <span title='@{[ M("Number of extracts") . ': ' .  scalar(@extracts_trash) ]}, @{[ M("uniqe users") . ': ' . &uniqe_users(@extracts_trash) ]}'>
   @{[ M("Newest extracts are first") ]}.
 </span>
 @{[ M("Last update") ]}: $current_date
</td>
<td><a href="$homepage_extract/community.html"><img src="/images/btn_donateCC_LG.gif" alt="donate" /></a></td>
</tr>
</table>

EOF

    print <<EOF;
<p>
</p>

</div> <!-- map_after -->
</div> <!-- map_area -->
<div id="nomap">
EOF
    @extracts = &running_extract_areas(
        'log_dir' => "$spool_dir/" . $spool->{"confirmed"},
        'max'     => $max
    );

    result(
        'type'    => 'confirmed',
        'files'   => \@extracts,
        'name'    => 'Waiting extracts',
        'message' => 'Will start in the next 1-5 minutes',
    );

    @extracts = &running_extract_areas(
        'log_dir' => "$spool_dir/" . $spool->{"running"},
        'max'     => $max
    );

    result(
        'type'    => 'running',
        'files'   => \@extracts,
        'name'    => 'Running extracts',
        'message' => 'Will be ready in the next 3-10 minutes',
    );

    @extracts = @extracts_trash;
    result(
        'type'  => 'download',
        'name'  => 'Ready extracts',
        'files' => \@extracts
    );

    filter_date( 'filter_date' => \@filter_date, 'date' => $date );
    statistic( 'files' => \@extracts, 'summary' => 1 );

    print &footer( 'date' => $current_date );

    #print qq{    </div> <!-- main -->\n};
    #print qq{  </div> <!-- border -->\n};
    print qq{</div> <!-- all -->\n};

    # load javascript code late
    print &load_javascript_libs;
    print $option->{"enable_google_analytics"}
      ? BBBike::Analytics->new( 'q' => $q )->google_analytics
      : "";

    print $q->end_html;
}

##############################################################################################
#
# main
#
&download($q);
