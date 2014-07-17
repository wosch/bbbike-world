#!/bin/sh
# Copyright (c) 2009-2014 Wolfram Schneider, http://bbbike.org
#
# world-nytperf.sh - cgi/shell wrapper for bbbike @ world city perf testing

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"
: ${city="Cottbus"}
server=nytperf

umask 002

cache_dir=/var/cache/bbbike/${server}/$city
if [ "$server" = "localhost" ]; then
    cache_dir=/tmp/bbbike-${server}-$(whoami)/$city
fi
mkdir -p $cache_dir

export NYTPROF=trace=2:start=init:file=/tmp/nytprof.out
data="data-osm/$city"

# run from bbbike top directory
time env TMPDIR=$cache_dir DATA_DIR="$data" BBBIKE_DATADIR="$data" \
	perl -d:NYTProf cgi/bbbike.cgi 

