#!/usr/local/bin/perl -T
# Copyright (c) June 2012-2022 Wolfram Schneider, https://bbbike.org
#
# timestamp.cgi - show time stamp of database

use CGI;
use CGI::Carp;
use File::stat;
use IO::File;
use lib qw(../world/lib ../lib);
use Extract::Config;
use File::Basename;

use strict;
use warnings;

$ENV{PATH} = "/bin:/usr/bin";

my $debug = 0;

sub get_file_content {
    my $file = shift;

    warn "Open file '$file'\n" if $debug >= 2;

    my $fh = new IO::File $file, "r" or die "open '$file': $!\n";
    binmode $fh, ":raw";

    my $text;
    while (<$fh>) {
        $text .= $_;
    }
    $fh->close;

    return $text;
}

sub get_timestamp {
    my $q = shift;

    my $format = $q->param('format') // 'planet.osm';

    my $planet_osm = $Extract::Config::planet_osm;

    my $file =
      exists $planet_osm->{$format}
      ? $planet_osm->{$format}
      : $planet_osm->{'planet.osm'};
    my $namespace = basename( $file, ".osm.pbf" );

    # this scripts runs in ./cgi
    my $pwd = "../";

    my $timestamp_file = "${pwd}${file}.timestamp";
    my $timestamp      = "1970-0l-01T00:00:00Z";

    if ( -e $timestamp_file ) {
        $timestamp = &get_file_content($timestamp_file);
        chomp($timestamp);
    }
    else {
        warn "timestamp file $timestamp_file does not exists\n";
    }

    return <<EOF;
{
  "format":    "$format",
  "database":  "$namespace",
  "timestamp": "$timestamp"
}
EOF
}

######################################################################
# GET /cgi/timestamp?ns=planet-latest
#
# ns: planet-latest, planet-daily, planet-realtime, srtm
#

binmode( \*STDERR, ":raw" );
binmode( \*STDOUT, ":raw" );

my $q = new CGI;

if ( my $d = $q->param('debug') || $q->param('d') ) {
    $debug = $d if defined $d && $d >= 0 && $d <= 3;
}

my $expire = $debug >= 2 ? '+1s' : '+1h';

my $res = &get_timestamp($q);
my $status = $res ? 200 : 500;

print $q->header(
    -type                        => 'text/javascript',
    -charset                     => 'utf-8',
    -expires                     => $expire,
    -status                      => $status,
    -access_control_allow_origin => '*',
);

print $res;

1;
