#!/bin/sh
# Copyright (c) 2009-2014 Wolfram Schneider, https://bbbike.org
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
# REQUEST_METHOD="GET"

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"
: ${city="Strassburg"}
#: ${QUERY_STRING=""}
server=nytperf
: ${nytprof="-d:NYTProf"}


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

# local dir?
if [ $(dirname $0) = '.' ]; then
    cd ../..
fi

export REQUEST_METHOD="GET"
export SCRIPT_NAME="/$city/index.cgi"
export QUERY_STRING="output_as=yaml&$(./world/bin/bbbike-db --startc $city)"
export REQUEST_URI="/$city/?$QUERY_STRING"

# run from world web directory, as the cgi scripts
cd world/web/$city

exit=0
export NYTPROF="trace=0:start=init:file=./nytprof.out"
time env TMPDIR=$cache_dir DATA_DIR="$data" BBBIKE_DATADIR="$data" \
	perl $nytprof $(pwd)/$city.cgi || exit=$?

# generated HTML page of profiler
if [ -n "$nytprof" ]; then
    echo "Running profiler HTML output in: $(pwd)"
    nytprofhtml
fi

exit $exit

