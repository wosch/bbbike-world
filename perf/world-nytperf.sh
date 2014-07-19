#!/bin/sh
# Copyright (c) 2009-2014 Wolfram Schneider, http://bbbike.org
#
# world-nytperf.sh - cgi/shell wrapper for bbbike @ world city perf testing
#
# city=Strassburg ./world/perf/world-nytperf.sh
#
# SCRIPT_FILENAME=/home/wosch/projects/bbbike/world/web/Strassburg/index.cgi
# REQUEST_URI=/Strassburg/?start=Rue+du+Charron+%5B7.7485%2C48.56803%2C0%5D&via=&ziel=Rue+de+la+Somme%2F+%5B7.77475%2C48.583%2C0%5D&scope=
# HTTP_REFERER=http://dev2.bbbike.org/Strassburg/
# PWD=/bbbike/projects/bbbike/world/web/Strassburg
# SCRIPT_NAME=/Strassburg/index.cgi

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"
: ${city="Strassburg"}
: ${QUERY_STRING=""}
server=nytperf
export SCRIPT_NAME=/cgi/world.cgi

umask 002
set -e

cache_dir=/var/cache/bbbike/${server}/$city
if [ "$server" = "localhost" ]; then
    cache_dir=/tmp/bbbike-${server}-$(whoami)/$city
fi
mkdir -p $cache_dir

export NYTPROF=trace=0:start=init:file=/tmp/nytprof.out
#export NYTPROF=trace=2:start=init:file=/tmp/nytprof.out
data="data-osm/$city"

# run from world web directory, as the cgi scripts
cd world/web/$city

export REQUEST_URI="/$city/"
export SCRIPT_NAME="/$city/index.cgi"

time env TMPDIR=$cache_dir DATA_DIR="$data" BBBIKE_DATADIR="$data" \
	perl -d:NYTProf $(pwd)/$city.cgi

