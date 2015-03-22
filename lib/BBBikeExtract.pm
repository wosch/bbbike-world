# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikeExtract.pm - extract config and libraries

package BBBikeExtract;

use CGI;
use CGI::Carp;

use Data::Dumper;

require Exporter;
@EXPORT = qw();

use strict;
use warnings;

#binmode \*STDOUT, ":utf8";
#binmode \*STDERR, ":utf8";

###########################################################################
# config
#

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

our $spool = {
    'incoming'  => "incoming",     # incoming request, not confirmed yet
    'confirmed' => "confirmed",    # ready to run
    'running'   => "running",      # currently running job
    'osm'       => "osm",          # cache older runs
    'download'  => "download",     # final directory for download
    'trash'     => "trash",        # keep a copy of the config for debugging
    'failed'    => "failed",       # keep record of failed runs
};


##########################
# helper functions
#

# BBBikeExtract::new->('q'=> $q, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = { %args };

    bless $self, $class;
    
    return $self;
}


#
# Parse user config file.
# This allows to override standard config values
#

sub load_config {
    my $self = shift;
    
    my $config_file = "../.bbbike-extract.rc";
    my $q = $self->{'q'};
    our $option = $self->{'option'};
    my $debug = $q->param("debug") || $option->{'debug'};
    
    if (   $q->param('pro')
        || $q->url( -full => 1 ) =~ m,^http://extract-pro[1-4]?\., )
    {
        $option->{'pro'} = 1;

        $config_file = '../.bbbike-extract-pro.rc';
        warn "Use extract pro config file $config_file\n"
          if $debug >= 2;
    }
    

    if ( -e $config_file ) {
        warn "Load config file: $config_file\n" if $debug >= 2;
        require $config_file;
        
        # double-check
        if ($q->param("pro")) {
            my $token = $option->{'email_token'} || "";
            if ($token ne $q->param('pro')) {
                warn Dumper($option) if $debug;
                die "Pro parameter does not match token\n";
            }
        }
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

# scale file size in x.y MB
sub file_size_mb {
    my $self = shift;
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

1;

__DATA__;
