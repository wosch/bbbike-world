#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# extract config load

package Extract::Config;

use CGI;
use JSON;
use Data::Dumper;

use strict;
use warnings;

###########################################################################
# config
#

our $formats = {
    'osm.pbf' => 'Protocolbuffer (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",

    'shp.zip' => "Shapefile (Esri)",

    'garmin-osm.zip'     => "Garmin OSM",
    'garmin-cycle.zip'   => "Garmin Cycle",
    'garmin-leisure.zip' => "Garmin Leisure",
    'garmin-bbbike.zip'  => "Garmin BBBike",

    'svg-google.zip'     => 'SVG google',
    'svg-hiking.zip'     => 'SVG hiking',
    'svg-osm.zip'        => 'SVG mapnik',
    'svg-urbanight.zip', => 'SVG night',
    'svg-wireframe.zip'  => 'SVG wireframe',
    'svg-cadastre.zip'   => 'SVG cadastre',

    'png-google.zip'     => 'PNG google',
    'png-hiking.zip'     => 'PNG hiking',
    'png-osm.zip'        => 'PNG mapnik',
    'png-urbanight.zip', => 'PNG night',
    'png-wireframe.zip'  => 'PNG wireframe',
    'png-cadastre.zip'   => 'PNG cadastre',

    'navit.zip' => "Navit",

    'obf.zip' => "Osmand (OBF)",

    'o5m.gz' => "o5m gzip'd",
    'o5m.xz' => "o5m 7z (xz)",

    'opl.xz' => "OPL 7z (xz)",
    'csv.gz' => "csv gzip'd",
    'csv.xz' => "csv 7z (xz)",

    'mapsforge-osm.zip' => "Mapsforge OSM",

    'srtm-europe.osm.pbf'         => 'SRTM Europe PBF (25m)',
    'srtm-europe.osm.xz'          => 'SRTM Europe XML 7z (25m)',
    'srtm-europe.garmin-srtm.zip' => 'SRTM Europe Garmin (25m)',
    'srtm-europe.obf.zip'         => 'SRTM Europe Osmand (25m)',

    'srtm.osm.pbf'         => 'SRTM World PBF (40m)',
    'srtm.osm.xz'          => 'SRTM World XML 7z (40m)',
    'srtm.garmin-srtm.zip' => 'SRTM World Garmin (40m)',
    'srtm.obf.zip'         => 'SRTM World Osmand (40m)',

    #'srtm-europe.mapsforge-osm.zip' => 'SRTM Europe Mapsforge',
    #'srtm-southamerica.osm.pbf' => 'SRTM South America PBF',

};

our $formats_menu = {
    'osm' => {
        'title'   => "OSM",
        'formats' => [
            'osm.pbf', 'osm.xz', 'osm.gz', 'osm.bz2', 'o5m.xz', 'o5m.gz',
            'opl.xz',  'csv.xz', 'csv.gz'
        ]
    },
    'garmin' => {
        'title'   => "Garmin",
        'formats' => [
            'garmin-osm.zip',     'garmin-cycle.zip',
            'garmin-leisure.zip', 'garmin-bbbike.zip'
        ]
    },
    'android' => {
        'title'   => "Android",
        'formats' => [ 'obf.zip', 'mapsforge-osm.zip', 'navit.zip' ]
    },
    'shape' => { 'title' => "Shapefile", 'formats' => ['shp.zip'] },
    'svg'   => {
        'title'   => "SVG",
        'formats' => [
            qw/svg-google.zip svg-hiking.zip svg-osm.zip svg-urbanight.zip svg-wireframe.zip svg-cadastre.zip/
        ]
    },
    'png' => {
        'title'   => "PNG",
        'formats' => [
            qw/png-google.zip png-hiking.zip png-osm.zip png-urbanight.zip png-wireframe.zip png-cadastre.zip/
        ]
    },
    'srtm' => {
        'title'   => "Elevation (SRTM)",
        'formats' => [
            'srtm-europe.osm.pbf',         'srtm-europe.osm.xz',
            'srtm-europe.garmin-srtm.zip', 'srtm-europe.obf.zip',
            'srtm.osm.pbf',                'srtm.osm.xz',
            'srtm.garmin-srtm.zip',        'srtm.obf.zip'
        ]
    }
};

our $spool = {
    'incoming'  => "incoming",     # incoming request, not confirmed yet
    'confirmed' => "confirmed",    # ready to run
    'running'   => "running",      # currently running job
    'osm'       => "osm",          # cache older runs
    'download'  => "download",     # final directory for download
    'trash'     => "trash",        # keep a copy of the config for debugging
    'failed'    => "failed",       # keep record of failed runs
};

our $spool_dir = '/var/cache/extract';

our $planet_osm = {

    #'planet.osm' => '../osm/download/planet-latest.osm.pbf',
    'planet.osm' => '../osm/download/planet-latest-nometa.osm.pbf',

    'srtm-europe.osm.pbf' =>
      '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
    'srtm-europe.osm.xz' =>
      '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
    'srtm-europe.garmin-srtm.zip' =>
      '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
    'srtm-europe.obf.zip' =>
      '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
    'srtm-europe.mapsforge-osm.zip' =>
      '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',

    'srtm.osm.pbf'           => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.osm.xz'            => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.garmin-srtm.zip'   => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.obf.zip'           => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.mapsforge-osm.zip' => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
};

#
# config for tile size databases
#
# available databases:
#
# world/etc/tile/tile-csv.xz.csv
# world/etc/tile/tile-garmin-osm.zip.csv
# world/etc/tile/tile-mapsforge-osm.zip.csv
# world/etc/tile/tile-navit.zip.csv
# world/etc/tile/tile-obf.zip.csv
# world/etc/tile/tile-osm.gz.csv
# world/etc/tile/tile-pbf.csv
# world/etc/tile/tile-shp.zip.csv
# world/etc/tile/tile-srtm-europe.garmin-srtm.zip.csv
# world/etc/tile/tile-srtm-europe.obf.zip.csv
# world/etc/tile/tile-srtm-europe.pbf.csv
# world/etc/tile/tile-srtm-garmin-srtm.zip.csv
# world/etc/tile/tile-srtm-obf.zip.csv
# world/etc/tile/tile-srtm-pbf.csv
# world/etc/tile/tile-test.csv
#
# all others must be matched to a known database
#
our $tile_format = {
    "osm.pbf" => "pbf",
    "pbf"     => "pbf",

    "osm.gz"  => "osm.gz",
    "osm"     => "osm.gz",
    "gz"      => "osm.gz",
    "osm.xz"  => "osm.gz",
    "osm.bz2" => "osm.gz",

    "shp.zip" => "shp.zip",
    "shp"     => "shp.zip",

    "obf.zip" => "obf.zip",
    "obf"     => "obf.zip",

    "garmin-cycle.zip"   => "garmin-osm.zip",
    "garmin-osm.zip"     => "garmin-osm.zip",
    "garmin-leisure.zip" => "garmin-osm.zip",
    "garmin-bbbike.zip"  => "garmin-osm.zip",

    "navit.zip" => "navit.zip",
    "navit"     => "navit.zip",

    "mapsforge-osm.zip" => "mapsforge-osm.zip",

    "o5m.gz"  => "pbf",
    "o5m.bz2" => "pbf",
    "o5m.xz"  => "pbf",

    "csv.xz"  => "pbf",
    "csv.gz"  => "pbf",
    "csv.bz2" => "pbf",

    "opl.xz" => "pbf",

    "srtm-europe.osm.pbf"         => "srtm-europe.pbf",
    "srtm-europe.osm.xz"          => "srtm-europe.pbf",
    "srtm-europe.garmin-srtm.zip" => "srtm-europe.garmin-srtm.zip",
    "srtm-europe.obf.zip"         => "srtm-europe.obf.zip",

    "srtm.osm.pbf"         => "srtm-pbf",
    "srtm.osm.xz"          => "srtm-pbf",
    "srtm.garmin-srtm.zip" => "srtm-garmin-srtm.zip",
    "srtm.obf.zip"         => "srtm-obf.zip",
};

##########################
# helper functions
#

# Extract::Config::new->('q'=> $q, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {%args};

    bless $self, $class;

    return $self;
}

#
# Parse user config file by extract.cgi
# This allows to override standard config values
#

sub load_config {
    my $self = shift;

    my $config_file = shift || "../.bbbike-extract.rc";

    my $q = $self->{'q'};
    our $option = $self->{'option'};

    my $debug = $q->param("debug") || $self->{'debug'} || $option->{'debug'};
    $self->{'debug'} = $debug;

    if (   $q->param('pro')
        || $q->url( -full => 1 ) =~ m,^http://extract-pro[1-4]?\., )
    {
        $option->{'pro'} = 1;

        $config_file = '../.bbbike-extract-pro.rc';
        warn "Use extract pro config file $config_file\n"
          if $debug >= 2;
    }

    # you can run "require" in perl only once
    if ( $INC{$config_file} ) {
        warn "WARNING: Config file $config_file was already loaded, ignored.\n";
        warn
qq{did you called Extract::Config->load_config("$config_file") twice?\n};
        return;
    }

    if ( -e $config_file ) {
        warn "Load config file: $config_file\n" if $debug >= 2;
        require $config_file;

        # double-check
        if ( $q->param("pro") ) {
            my $token = $option->{'email_token'} || "";
            if ( $token ne $q->param('pro') ) {
                warn Dumper($option) if $debug;
                die "Pro parameter does not match token\n";
            }
        }
    }

    else {
        warn "config file: $config_file not found, ignored\n"
          if $debug >= 2;
    }

    $self->config_format_menu;
}

sub config_format_menu {
    my $self = shift;

    our $option = $self->{'option'};

    my $formats_order = $option->{'formats_order'};
    foreach my $f (@$formats_order) {
        push @{ $option->{'formats'} }, $formats_menu->{$f};
    }
}

#
# Parse user config file.
# This allows to override standard config values
#
sub load_config_nocgi {
    my $self = shift;

    our $option = $self->{'option'};
    my $debug = $self->{'debug'} || $option->{'debug'};

    my $config_file = "$ENV{HOME}/.bbbike-extract.rc";
    if ( $ENV{BBBIKE_EXTRACT_PROFILE} ) {
        $config_file = $ENV{BBBIKE_EXTRACT_PROFILE};
    }
    if ( -e $config_file ) {
        warn "Load config file nocgi: $config_file\n" if $debug >= 2;
        require $config_file;
    }
    else {
        warn "config file: $config_file not found, ignored\n"
          if $debug >= 2;
    }
}

# re-set values for extract-pro service
sub check_extract_pro {
    my $self = shift;

    my $q = $self->{'q'};
    our $option = $self->{'option'};

    my $url = $q->url( -full => 1 );

    # basic version, skip
    return if !( $q->param("pro") || $url =~ m,/extract-pro/, );

    foreach my $key (qw/homepage_extract spool_dir download/) {
        my $key_pro = $key . "_pro";
        $option->{$key} = $option->{$key_pro};
    }

    $option->{"pro"} = 1;
}

sub is_production {
    my $self = shift;

    my $q = $self->{'q'};

    return 1 if -e "/tmp/is_production";

    return $q->virtual_host() =~ /^extract\.bbbike\.org$/i ? 1 : 0;
}

1;

__DATA__;
