#!/usr/local/bin/perl
# Copyright (c) 2012-2016 Wolfram Schneider, https://bbbike.org
#
# extract config and libraries

package Extract::Test::Archive;
use Test::More;
use Data::Dumper;
use BBBike::Test;

require Exporter;

#use base qw/Exporter/;
#our @EXPORT = qw(save_request complete_save_request check_queue Param large_int square_km);

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

# global URL hash per class
our $url_hash = {};

# Extract::Utils::new->('q'=> $q, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {
        'supported_languages' => [ "de", "en" ],
        'lang'                => 'en',
        'format'              => '',
        'format_name'         => '',
        'url'                 => '',
        'coords'              => '',
        'file'                => '',
        'style'               => '',

        %args
    };

    bless $self, $class;
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    if ( defined $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }

    $self->{'counter'} = 0;

    $self->init_env;
    $self->init_lang;
}

#############################################################################
# !!! Keep in sync !!!
# /cgi/extract.pl
#
#
## parameters for osm2XXX shell scripts
#$ENV{BBBIKE_EXTRACT_URL} = &script_url( $option, $obj );
#$ENV{BBBIKE_EXTRACT_COORDS} = qq[$obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}];
#$ENV{'BBBIKE_EXTRACT_LANG'} = $lang;

sub init_env {
    my $self = shift;

    my $option = {
        'pbf2osm' => {
            'garmin_version'     => 'mkgmap',
            'mbtiles_version'    => 'mbtiles',
            'maperitive_version' => 'Maperitive',
            'osmand_version'     => 'OsmAndMapCreator',
            'mapsforge_version'  => 'mapsforge',
            'bbbike_version'     => 'bbbike',
            'shape_version'      => 'osmium2shape',
            'mapsme_version'     => 'mapsme',
        }
    };

    $ENV{'BBBIKE_EXTRACT_GARMIN_VERSION'} =
      $option->{pbf2osm}->{garmin_version};
    $ENV{'BBBIKE_EXTRACT_MBTILES_VERSION'} =
      $option->{pbf2osm}->{mbtiles_version};
    $ENV{'BBBIKE_EXTRACT_MAPERITIVE_VERSION'} =
      $option->{pbf2osm}->{maperitive_version};
    $ENV{'BBBIKE_EXTRACT_OSMAND_VERSION'} =
      $option->{pbf2osm}->{osmand_version};
    $ENV{'BBBIKE_EXTRACT_MAPSFORGE_VERSION'} =
      $option->{pbf2osm}->{mapsforge_version};
    $ENV{'BBBIKE_EXTRACT_BBBIKE_VERSION'} =
      $option->{pbf2osm}->{bbbike_version};
    $ENV{'BBBIKE_EXTRACT_SHAPE_VERSION'} = $option->{pbf2osm}->{shape_version};
    $ENV{'BBBIKE_EXTRACT_MAPSME_VERSION'} =
      $option->{pbf2osm}->{mapsme_version};

#$ENV{BBBIKE_EXTRACT_URL}  = 'https://extract.bbbike.org/?sw_lng=-72.33&sw_lat=-13.712&ne_lng=-71.532&ne_lat=-13.217&format=png-google.zip&city=Cusco%2C%20Peru';
#$ENV{BBBIKE_EXTRACT_COORDS} = '-72.33,-13.712 x -71.532,-13.217';
}

# default env values for Cusco test
sub init_cusco {
    my $self = shift;

    my $format = $self->{'format'};
    my $lang   = $self->{'lang'};

    $ENV{BBBIKE_EXTRACT_URL} =
"https://extract.bbbike.org/?sw_lng=-72.33&sw_lat=-13.712&ne_lng=-71.532&ne_lat=-13.217&format=$format.zip&city=Cusco%2C%20Peru"
      . ( $lang ? "&lang=$lang" : "" );

    $ENV{BBBIKE_EXTRACT_COORDS} = "-72.329,-13.711 x -71.531,-13.216";

    return $self->{'city'} = 'Cusco';
}

sub init_lang {
    my $self = shift;
    my $lang = $self->{'lang'};

    $ENV{'BBBIKE_EXTRACT_LANG'} = $lang;

    # delete empty value
    if ( !$ENV{'BBBIKE_EXTRACT_LANG'} || $ENV{'BBBIKE_EXTRACT_LANG'} eq "" ) {
        delete $ENV{'BBBIKE_EXTRACT_LANG'};
        $lang = "";
    }

    return $self->{'lang'} = $lang;
}

sub out {
    my $self     = shift;
    my $pbf_file = $self->{'pbf_file'};
    my $style    = shift;

    my $prefix = $pbf_file;
    $prefix =~ s/\.pbf$//;

    my $lang   = $self->{'lang'};
    my $format = $self->{'format'};

    return $self->{'file'} =
        "$prefix.$format"
      . ( $style ? "-$style" : "" )
      . (    $lang
          && $lang ne "en" ? ".$ENV{'BBBIKE_EXTRACT_LANG'}.zip" : ".zip" );
}

sub validate {
    my $self = shift;

    my %args  = @_;
    my $style = $args{'style'};
    if ( defined $style ) {
        $self->{'style'} = $style;
    }

    if ( $self->{format} =~ /shp|perltk/ ) {
        $self->check_checksum_multi;
    }
    else {
        $self->check_checksum;
    }

    $self->check_readme;
    $self->check_readme_html;
    $self->check_logfile;

    return $self->{'counter'};
}

sub extract_file {
    my $self = shift;

    my $file     = shift;
    my $zip_file = $self->{'file'};

    my @data = ();
    if ( !-e $zip_file ) {
        die "zip file '$zip_file' does not exists\n";
    }

    if ( !open( IN, "unzip -p $zip_file '*/$file' |" ) ) {
        warn "unzip -p $zip_file: $!\n";
        return @data;
    }

    while (<IN>) {
        push @data, $_;
    }
    close IN;

    return @data;
}

sub counter {
    my $self = shift;

    return $self->{'counter'};
}

sub check_logfile {
    my $self = shift;

    my $format = $self->{'format'};

    if ( $format =~ /^garmin-/ ) {
        return $self->check_logfile_garmin;
    }
}

sub check_logfile_garmin {
    my $self  = shift;
    my $style = $self->{'style'};

    my $counter = 0;
    my @data    = $self->extract_file('logfile.txt');

    my $res;
    $res = grep { /--code-page=65001/ } @data;

    if ( $style =~ /-ascii$/ ) {
        ok( !$res, "No codepage set (us-ascii)" );
    }
    else {
        ok( $res, "Unicode codepage set (utf-8)" );
    }
    $counter++;

    $res = grep { /--add-pois-to-areas/ } @data;
    if ( $style =~ /^oseam/ ) {
        ok( !$res, "No --add-pois-to-areas for OpenSeaMap" );
    }
    else {
        ok( $res, "Set parameter --add-pois-to-areas" );
    }
    $counter++;

    $self->{'counter'} += $counter;
}

sub check_checksum {
    my $self = shift;

    my @data = $self->extract_file('CHECKSUM.txt');

    is( scalar(@data), 2, "two checksums" );
    cmp_ok( length( $data[0] ), ">", 34, "md5 + text is larger than 32 bytes" );
    cmp_ok( length( $data[1] ),
        ">", 66, "sha256 + text is larger than 64 bytes" );

    $self->{'counter'} += 3;
}

sub check_checksum_multi {
    my $self = shift;

    my @data = $self->extract_file('CHECKSUM.txt');

    cmp_ok( scalar(@data), '>=', 2, "more than two checksums" );

    $self->{'counter'} += 1;
}

sub check_readme {
    my $self = shift;

    my $lang        = $self->{'lang'};
    my $format      = $self->{'format'};
    my $format_name = $self->{'format_name'};

    my @data = $self->extract_file('README.txt');

    cmp_ok( scalar(@data), ">", "20",
        "README.txt must be at least 20 lines long $#data, lang='$lang'" );

    like(
        $data[0],
qr"^Map data.*? OpenStreetMap contributors, https://www.openstreetmap.org",
        "map data"
    );

    like(
        $data[1],
        qr"^Extracts created by BBBike, https?://extract.bbbike.org",
        "by bbbike.org"
    );

    like( $data[2], qr"^\S+\s+by(\s\w+,)?\s+https?://\S+", "by software" );

    $self->{'counter'} += 4;

    if ( $format =~ /garmin-/ ) {
        like(
            $data[4],
            qr"^Map style.*? by OpenStreetMap.org, BBBike.org, openfietsmap.nl",
            "map style"
        );
        $self->{'counter'} += 1;
    }

    if ( $lang eq 'de' ) {
        ok(
            (
                grep {
/^Dieses? $format_name (Karte|Datei|file) wurde erzeugt am: \S+\s+.*UTC.+$/
                } @data
            ),
            "format_name + datum check: '$format_name'"
        );

        ok(
            (
                grep {
/^GPS Rechteck Koordinaten \(lng,lat\): [\-0-9\.]+,.* [\-0-9\.]+,/
                } @data
            ),
            "gps"
        );
        ok(
            (
                grep {
qr"^Script URL: https?://.*bbbike.org/.*\?.*format=.+.*city="
                } @data
            ),
            "url"
        );
        ok( ( grep { /^Name des Gebietes: \S+/ } @data ), "name" );

        ok( ( grep { /^Spenden sind willkommen/ } @data ), "feedback" );
        ok(
            (
                grep {
                    qr"unterstuetzen: https?://www.bbbike.org/community.de.html"
                } @data
            ),
            "donate"
        );
        ok( ( grep { /^Danke, Wolfram Schneider/ } @data ), "thanks" );
        ok(
            (
                grep {
                    qr"^https?://www.BBBike.org - Dein Fahrrad-Routenplaner"
                } @data
            ),
            "footer"
        );

        $self->{'counter'} += 8;
    }
    else {
        ok(
            (
                grep {
/^This $format_name (file|map) was created on: \S+\s+.*UTC.+$/
                } @data
            ),
            "format_name + date check: '$format_name'"
        );
        ok(
            (
                grep {
/^GPS rectangle coordinates \(lng,lat\): [\-0-9\.]+,.* [\-0-9\.]+,/
                } @data
            ),
            "gps"
        );
        ok(
            (
                grep {
qr"^Script URL: https?://.*bbbike.org/.*\?.*format=.+.*city="
                } @data
            ),
            "url"
        );
        ok( ( grep { /^Name of area: \S+/ } @data ), "name" );

        ok( ( grep { /^We appreciate any feedback/ } @data ), "feedback" );
        ok(
            (
                grep {
qr"^PayPal or bank wire transfer: https?://www.BBBike.org/community.html"
                } @data
            ),
            "donate"
        );
        ok( ( grep { /^thanks, Wolfram Schneider/ } @data ), "thanks" );
        ok(
            (
                grep { qr"^https?://www.BBBike.org - Your Cycle Route Planner" }
                  @data
            ),
            "footer"
        );

        $self->{'counter'} += 8;
    }

}

sub check_readme_html {
    my $self = shift;

    my $lang        = $self->{'lang'};
    my $format      = $self->{'format'};
    my $format_name = $self->{'format_name'};

    my @data = $self->extract_file('README.html');

    cmp_ok( scalar(@data), ">", "20",
        "README.html must be at least 20 lines long $#data, lang='$lang'" );

    ok( ( grep { / charset=utf-8"/ } @data ), "charset" );

    ok( ( grep { qr"<title>.+</title>" } @data ), "<title/>" );
    ok( ( grep { qr"<body>" } @data ),            "<body>" );
    ok( ( grep { qr"</pre>" } @data ),            "</pre>" );
    ok( ( grep { qr"</body>" } @data ),           "</body>" );
    ok( ( grep { qr"</html>" } @data ),           "</html>" );

    my @url;
    foreach my $url (@data) {
        push @url, $1 if $url =~ /href="(.+?)"/;
    }

    $self->{'counter'} += 7;

    $self->validate_url(@url);
}

sub validate_url {
    my $self = shift;
    my @url  = @_;

    if ( $ENV{'BBBIKE_TEST_NO_NETWORK'} ) {
        diag "Ignore URL check due no network";
        return;
    }

    my $test = BBBike::Test->new();
    my $hash = $url_hash;

    foreach my $url (@url) {
        $url =~ s,^(https?://(www\.)?)BBBike\.org,${1}bbbike\.org,;

        diag "url: $url" if $debug;
        if ( exists $hash->{$url} ) {

            #diag "cache";
        }

        # check external links only in long runs
        elsif ( $ENV{"BBBIKE_TEST_LONG"} || $url =~ /bbbike\.org/i ) {
            my $res = $test->myget_head($url);
            $hash->{$url} = $res;
            $self->{'counter'} += 3;
        }
    }

    #$url_hash = $hash;
}
1;

__DATA__;
