#!/usr/local/bin/perl
# Copyright (c) 2012-2021 Wolfram Schneider, https://bbbike.org
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

#
# global config object, it will be filled by
#
# 1. this config module
# 2. overriden by a config from an other module
# 3. overriden by a user config file ~/.bbbike-extract.rc
#
our $option = {};

# keep in sync with world/etc/munin/plugins/bbbike-extract

our $formats = {
    'osm.pbf' => 'Protocolbuffer (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",

    'shp.zip' => "Shapefile (Esri)",

    'garmin-osm.zip'                  => "Garmin OSM (UTF-8)",
    'garmin-osm-ascii.zip'            => "Garmin OSM (ASCII)",
    'garmin-osm-latin1.zip'           => "Garmin OSM (latin1)",
    'garmin-cycle.zip'                => "Garmin Cycle (UTF-8)",
    'garmin-cycle-ascii.zip'          => "Garmin Cycle (ASCII)",
    'garmin-cycle-latin1.zip'         => "Garmin Cycle (latin1)",
    'garmin-leisure.zip'              => "Garmin Leisure (UTF-8)",
    'garmin-leisure-ascii.zip'        => "Garmin Leisure (ASCII)",
    'garmin-leisure-latin1.zip'       => "Garmin Leisure (latin1)",
    'garmin-bbbike.zip'               => "Garmin BBBike (UTF-8)",
    'garmin-bbbike-ascii.zip'         => "Garmin BBBike (ASCII)",
    'garmin-bbbike-latin1.zip'        => "Garmin BBBike (latin1)",
    'garmin-onroad.zip'               => "Garmin Onroad (UTF-8)",
    'garmin-onroad-ascii.zip'         => "Garmin Onroad (ASCII)",
    'garmin-onroad-latin1.zip'        => "Garmin Onroad (latin1)",
    'garmin-ontrail.zip'              => "Garmin Ontrail (UTF-8)",
    'garmin-ontrail-ascii.zip'        => "Garmin Ontrail (ASCII)",
    'garmin-ontrail-latin1.zip'       => "Garmin Ontrail (latin1)",
    'garmin-openfietslite.zip'        => "Garmin Openfietsmap Lite (UTF-8)",
    'garmin-openfietslite-ascii.zip'  => "Garmin Openfietsmap Lite (ASCII)",
    'garmin-openfietslite-latin1.zip' => "Garmin Openfietsmap Lite (latin1)",
    'garmin-openfietsfull.zip'        => "Garmin Openfietsmap Full (UTF-8)",
    'garmin-openfietsfull-ascii.zip'  => "Garmin Openfietsmap Full (ASCII)",
    'garmin-openfietsfull-latin1.zip' => "Garmin Openfietsmap Full (latin1)",
    'garmin-oseam.zip'                => "Garmin OpenSeaMap (UTF-8)",
    'garmin-oseam-ascii.zip'          => "Garmin OpenSeaMap (ASCII)",
    'garmin-oseam-latin1.zip'         => "Garmin OpenSeaMap (latin1)",
    'garmin-opentopo.zip'             => "Garmin OpenTopoMap (UTF-8)",
    'garmin-opentopo-ascii.zip'       => "Garmin OpenTopoMap (ASCII)",
    'garmin-opentopo-latin1.zip'      => "Garmin OpenTopoMap (latin1)",

    'mbtiles-basic.zip'        => "MB vector tiles basic",
    'mbtiles-openmaptiles.zip' => "MB vector tiles openmaptiles",

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

    'bbbike-perltk.zip' => "BBBike Perl/Tk",

    'obf.zip' => "Osmand (OBF)",

    'o5m.gz' => "o5m gzip'd",
    'o5m.xz' => "o5m 7z (xz)",

    'opl.xz'        => "Osmium OPL 7z (xz)",
    'geojson.xz'    => "Osmium GeoJSON 7z (xz)",
    'geojsonseq.xz' => "Osmium GeoJSONseq 7z (xz)",
    'text.xz'       => "Osmium Text 7z (xz)",
    'sqlite.xz'     => "Osmium SQLite 7z (xz)",

    'csv.gz' => "csv gzip'd",
    'csv.xz' => "csv 7z (xz)",

    'mapsforge-osm.zip' => "Mapsforge OSM",
    'mapsme-osm.zip'    => "maps.me OSM",

    #'srtm-europe.osm.pbf'         => 'SRTM Europe PBF (25m)',
    #'srtm-europe.osm.xz'          => 'SRTM Europe OSM XML 7z (25m)',
    #'srtm-europe.garmin-srtm.zip' => 'SRTM Europe Garmin (25m)',
    #'srtm-europe.obf.zip'         => 'SRTM Europe Osmand (25m)',

    'srtm.osm.pbf'         => 'SRTM World PBF (40m)',
    'srtm.osm.xz'          => 'SRTM World OSM XML 7z (40m)',
    'srtm.garmin-srtm.zip' => 'SRTM World Garmin (40m)',
    'srtm.obf.zip'         => 'SRTM World Osmand (40m)',

    #'srtm-europe.mapsforge-osm.zip' => 'SRTM Europe Mapsforge',
    #'srtm-southamerica.osm.pbf' => 'SRTM South America PBF',

};

our $formats_menu = {
    'osm' => {
        'title'   => "OSM",
        'formats' => [
            'osm.pbf', 'osm.xz', 'osm.gz',    #'osm.bz2',
            'csv.xz',  'o5m.xz',
            'opl.xz',  'text.xz',
        ]
    },
    'geojson' => {
        'title'   => "GeoJSON",
        'formats' => [ 'geojson.xz', 'geojsonseq.xz' ]

    },
    'sql' => {
        'title'   => "SQL",
        'formats' => ['sqlite.xz']
    },

    'mbtiles' => {
        'title'   => "Vector Tiles",
        'formats' => ['mbtiles-openmaptiles.zip']    # 'mbtiles-basic.zip'
    },
    'garmin' => {
        'title'   => "Garmin",
        'formats' => [
            'garmin-osm-latin1.zip',           'garmin-osm.zip',
            'garmin-cycle-latin1.zip',         'garmin-cycle.zip',
            'garmin-leisure-latin1.zip',       'garmin-leisure.zip',
            'garmin-onroad-latin1.zip',        'garmin-onroad.zip',
            'garmin-ontrail-latin1.zip',       'garmin-ontrail.zip',
            'garmin-openfietslite-latin1.zip', 'garmin-openfietslite.zip',
            'garmin-openfietsfull-latin1.zip', 'garmin-openfietsfull.zip',
            'garmin-oseam-latin1.zip',         'garmin-oseam.zip',
            'garmin-opentopo-latin1.zip',      'garmin-opentopo.zip',
            'garmin-bbbike-latin1.zip',        'garmin-bbbike.zip',
        ]
    },
    'android' => {
        'title'   => "Android",
        'formats' => [ 'obf.zip', 'mapsforge-osm.zip' ]
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
    'bbbike' => {
        'title'   => "BBBike",
        'formats' => ['bbbike-perltk.zip']
    },
    'srtm' => {
        'title'   => "Contours (SRTM)",
        'formats' => [

            #'srtm-europe.osm.pbf',         'srtm-europe.osm.xz',
            #'srtm-europe.garmin-srtm.zip', 'srtm-europe.obf.zip',
            'srtm.osm.pbf',         'srtm.osm.xz',
            'srtm.garmin-srtm.zip', 'srtm.obf.zip'
        ]
    }
};

# Note: may be later this will be expanded to a full path
# 'confirmed' => '/var/cache/extract/confirmed',
our $spool = {
    'confirmed' => "confirmed",    # ready to run
    'running'   => "running",      # currently running job
    'download'  => "download",     # final directory for download
    'trash'     => "trash",        # keep a copy of the config for debugging
    'failed'    => "failed",       # keep record of failed runs
};

our $spool_dir = '/var/cache/extract';

our $planet_osm = {

    #'planet.osm' => '../osm/download/planet-latest.osm.pbf',
    'planet.osm' => '../osm/download/planet-latest-nometa.osm.pbf',

#'srtm-europe.osm.pbf' => '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
#'srtm-europe.osm.xz' => '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
#'srtm-europe.garmin-srtm.zip' => '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
#'srtm-europe.obf.zip' => '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',
#'srtm-europe.mapsforge-osm.zip' => '../osm/download/srtm/Hoehendaten_Freizeitkarte_Europe.osm.pbf',

    'srtm.osm.pbf'           => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.osm.xz'            => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.garmin-srtm.zip'   => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.obf.zip'           => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
    'srtm.mapsforge-osm.zip' => '../osm/download/srtm/planet-srtm-e40.osm.pbf',
};

# map planet file to sub-planet directory
our $planet_sub_dir = {

    # planet without meta data
    '../osm/download/planet-latest-nometa.osm.pbf' =>
      '../osm/download/sub-planet',

    # compatibility, planet without meta data and 1.1m
    '../osm/download/planet-latest.osm.pbf' => '../osm/download/sub-planet',

    # SRTM planet
    '../osm/download/srtm/planet-srtm-e40.osm.pbf' =>
      '../osm/download/sub-srtm',
};

#
# config for tile size databases
#
# available databases:
#
# world/etc/tile/csv.xz.csv
# world/etc/tile/garmin-osm.zip.csv
# world/etc/tile/mapsforge-osm.zip.csv
# world/etc/tile/obf.zip.csv
# world/etc/tile/osm.gz.csv
# world/etc/tile/pbf.csv
# world/etc/tile/shp.zip.csv
# world/etc/tile/mbtiles-openmaptiles.zip.csv
# world/etc/tile/srtm-europe.garmin-srtm.zip.csv
# world/etc/tile/srtm-europe.obf.zip.csv
# world/etc/tile/srtm-europe.pbf.csv
# world/etc/tile/srtm-garmin-srtm.zip.csv
# world/etc/tile/srtm-obf.zip.csv
# world/etc/tile/srtm-pbf.csv
# world/etc/tile/test.csv
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

    "garmin-osm.zip"                  => "garmin-osm.zip",
    "garmin-osm-ascii.zip"            => "garmin-osm.zip",
    "garmin-osm-latin1.zip"           => "garmin-osm.zip",
    "garmin-cycle.zip"                => "garmin-osm.zip",
    "garmin-cycle-ascii.zip"          => "garmin-osm.zip",
    "garmin-cycle-latin1.zip"         => "garmin-osm.zip",
    "garmin-leisure.zip"              => "garmin-osm.zip",
    "garmin-leisure-ascii.zip"        => "garmin-osm.zip",
    "garmin-leisure-latin1.zip"       => "garmin-osm.zip",
    "garmin-bbbike.zip"               => "garmin-osm.zip",
    "garmin-bbbike-ascii.zip"         => "garmin-osm.zip",
    "garmin-bbbike-latin1.zip"        => "garmin-osm.zip",
    "garmin-openfietslite.zip"        => "garmin-osm.zip",
    "garmin-openfietslite-ascii.zip"  => "garmin-osm.zip",
    "garmin-openfietslite-latin1.zip" => "garmin-osm.zip",
    "garmin-openfietsfull.zip"        => "garmin-osm.zip",
    "garmin-openfietsfull-ascii.zip"  => "garmin-osm.zip",
    "garmin-openfietsfull-latin1.zip" => "garmin-osm.zip",

    "mapsforge-osm.zip" => "mapsforge-osm.zip",
    "mapsme-osm.zip"    => "pbf",
    "bbbike-perltk.zip" => "garmin-osm.zip",

    "o5m.gz"  => "pbf",
    "o5m.bz2" => "pbf",
    "o5m.xz"  => "pbf",

    "csv.xz"  => "pbf",
    "csv.gz"  => "pbf",
    "csv.bz2" => "pbf",

    "opl.xz"        => "pbf",
    "geojson.xz"    => "pbf",
    "geojsonseq.xz" => "pbf",
    "text.xz"       => "pbf",

    "srtm-europe.osm.pbf"         => "srtm-europe-pbf",
    "srtm-europe.osm.xz"          => "srtm-europe-pbf",
    "srtm-europe.garmin-srtm.zip" => "srtm-europe-garmin-srtm.zip",
    "srtm-europe.obf.zip"         => "srtm-europe-obf.zip",

    "srtm.osm.pbf"         => "srtm-pbf",
    "srtm.osm.xz"          => "srtm-pbf",
    "srtm.garmin-srtm.zip" => "srtm-garmin-srtm.zip",
    "srtm.obf.zip"         => "srtm-obf.zip",
};

our $server = {
    'dev'      => [qw/dev2.bbbike.org/],
    'www'      => [qw/www.bbbike.org www2.bbbike.org/],
    'extract'  => [qw/extract.bbbike.org extract2.bbbike.org/],
    'download' => [qw/download.bbbike.org download2.bbbike.org/],
    'api'      => [qw/api.bbbike.org api2.bbbike.org/],
    'tile'     => [
        qw/a.tile.bbbike.org b.tile.bbbike.org c.tile.bbbike.org d.tile.bbbike.org/
    ],
    'production' => [
        qw(www.bbbike.org download.bbbike.org extract.bbbike.org mc.bbbike.org a.tile.bbbike.org b.tile.bbbike.org c.tile.bbbike.org d.tile.bbbike.org api.bbbike.org )
    ],
};

# setup for /cgi/route.cgi
our $route_cgi = {
    'email'  => 'nobody',                   # ""
    'format' => 'garmin-cycle-latin1.zip'
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
# get list of active servers per service
# 'www' => (www, www1, www2, www3, www4)
# 'extract' => (extract, extract3)
#
sub get_server_list {
    my $self = shift;
    my @type = @_;

    my $debug = $self->{'debug'};

    my @list = ();
    my $server = $option->{'server'} || $server;
    warn Dumper($server) if $debug >= 2;

    foreach my $type (@type) {
        if ( !$type || !exists $server->{$type} ) {
            warn "Unknown server type '$type'\n";
            return ();
        }

        foreach my $s ( @{ $server->{$type} } ) {
            my $protocol = $s =~ m,^localhost$, ? 'http' : 'https';
            push @list, "$protocol://$s";
        }
    }

    return @list;
}

#
# Parse user config file by extract.cgi
# This allows to override standard config values
#

sub load_config {
    my $self = shift;

    my $config_file = shift || "../.bbbike-extract.rc";

    my $q = $self->{'q'};
    $option = $self->{'option'};

    my $debug =
      $q->param("debug") || $self->{'debug'} || $option->{'debug'} || 0;
    $self->{'debug'} = $debug;

    my $pro = 0;
    if (   $q->param('pro')
        || $q->url( -full => 1 ) =~ m,^https?://extract-pro[1-9]?\.,
        || $q->url( -full => 1 ) =~
        m,^https?://download[1-9]?\.bbbike\.org/osm/extract-pro/, )
    {

        $config_file = '../.bbbike-extract-pro.rc';
        warn "Use extract pro config file $config_file\n"
          if $debug >= 2;
        $pro = 1;

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

        # pro by token (2) or auth (1)
        if ($pro) {
            $option->{'pro'} = $q->param('pro') ? 2 : 1;
        }
        else {
            $option->{'pro'} = 0;
        }

        # double-check
        if ( $q->param("pro") ) {
            my $token = $option->{'email_token'} || "";
            if ( $token ne $q->param('pro') ) {
                warn Dumper($option) if $debug;

               # need to stop here because we already loaded the pro config file
                die "Pro parameter does not match token\n";
            }
        }
    }

    else {
        warn "config file: $config_file not found, ignored\n"
          if $debug >= 2;

        if ( $q->param("pro") ) {
            die
"Extract pro service requires a config file: $config_file, give up\n";
        }
    }

    $self->config_format_menu;
    $self->config_route_cgi;
}

sub config_format_menu {
    my $self = shift;

    $option = $self->{'option'};
    my $debug = $self->{'debug'};

    my $formats_order = $option->{'formats_order'};
    foreach my $f (@$formats_order) {

        # use defaults if not set in Extract::Route or ~/.bbbike-extract.rc
        if ( exists $formats_menu->{$f} ) {
            push @{ $option->{'formats'} }, $formats_menu->{$f};
        }
        else {
            warn "Unknown select menu format: $f, ignored\n" if $debug >= 1;
        }
    }
}

sub config_route_cgi {
    my $self = shift;

    $option = $self->{'option'};
    my $debug = $self->{'debug'};

    foreach my $key ( keys %$route_cgi ) {
        if ( !exists $option->{"route_cgi"}->{$key} ) {
            $option->{"route_cgi"}->{$key} = $route_cgi->{$key};
        }
    }
}

#
# Parse user config file.
# This allows to override standard config values
#
sub load_config_nocgi {
    my $self = shift;

    $option = $self->{'option'};
    my $debug =
        defined $self->{'debug'}   ? $self->{'debug'}
      : defined $ENV{DEBUG}        ? $ENV{DEBUG}
      : defined $option->{'debug'} ? $option->{'debug'}
      :                              0;

    my $config_file = "$ENV{HOME}/.bbbike-extract.rc";
    if ( $ENV{BBBIKE_EXTRACT_PROFILE} ) {
        $config_file = $ENV{BBBIKE_EXTRACT_PROFILE};
    }

    if ( $config_file =~ /-pro/ ) {
        warn
          "detect extract pro config file=$config_file, set option->{'pro'}=1\n"
          if $debug >= 1;
        $option->{'pro'} = 3;
    }

    if ( -e $config_file ) {
        warn "Load config file nocgi: $config_file\n" if $debug >= 1;
        require $config_file;
    }
    else {
        warn "config file: $config_file not found, ignored\n"
          if $debug >= 1;
    }

    $self->{'debug'} = $debug;
    return $self;
}

# re-set values for extract-pro service
#
# The pro service is activated by the CGI parameter pro= or
# the hostname extract-pro
#
sub check_extract_pro {
    my $self = shift;

    my $q = $self->{'q'};
    $option = $self->{'option'};

    my $url = $q->url( -full => 1 );

    # public version, skip
    if ( !( $q->param("pro") || $url =~ m,^https://extract-pro[1-9]?\., ) ) {
        return;
    }

    foreach my $key (qw/homepage_extract spool_dir download/) {
        my $key_pro = $key . "_pro";
        if ( !defined $option->{$key_pro} ) {
            warn "Config $key_pro is not set, ignored. FIXME!\n";
        }
        else {
            warn "Reset config for pro users $key=$option->{$key_pro}\n"
              if $self->{'debug'} >= 2;
            $option->{$key} = $option->{$key_pro};
        }
    }

    # should never happens
    $option->{"pro"} = 0 if !$option->{"pro"};
}

sub is_production {
    my $self = shift;

    my $q = $self->{'q'};

    return 1 if -e "/tmp/is_production";

    return $q->virtual_host() =~ /^extract[0-9]?\.bbbike\.org$/i ? 1 : 0;
}

1;

__DATA__;
