#!/bin/sh
# Copyright (c) 2009-2014 Wolfram Schneider, http://bbbike.org
#
# world-nytperf.sh - cgi/shell wrapper for bbbike @ world city perf testing
#
# city=Cottbus ./world/perf/world-nytperf.sh

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"
: ${city="Cottbus"}
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

# run from world cgi directory
cd world/cgi 
time env TMPDIR=$cache_dir DATA_DIR="$data" BBBIKE_DATADIR="$data" \
	perl -d:NYTProf ./bbbike.cgi 

