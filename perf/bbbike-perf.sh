#!/bin/sh
# Copyright (c) 2011-2014 Wolfram Schneider, https://bbbike.org
#
# bbbike-memory - check perl memory usage of a city

: ${data_osm=data-osm}
: ${debug=""}
: ${time=""} # time=time
: ${strace="strace -o bbbike.strace"} # 
: ${nytprof="-d:NYTProf"}
: ${nocache=false}

# die on exit
#set -e

#############################################
# Strassburg
#
# https://www.bbbike.org/Strassburg/?start=Rue+de+la+Tour%2FRue+du+Muhlbruchel+%5B7.71584%2C48.57808%2C0%5D&via=&ziel=Pont+de+la+Dinsenm%C3%BChle%2FRue+des+Moulins+%5B7.74175%2C48.58069%2C0%5D&scope=
#
# "7.71584,48.57808"
# "7.74175,48.58069"

city=${1-"Strassburg"}
prog=$(echo $0 | perl -npe 's/\.sh$/.pl/')

if $nocache; then
    rm -rf cache
fi

env DATA_DIR="data-osm/$city" BBBIKE_DATADIR="data-osm/$city" \
    $time perl -MDevel::Size=total_size $nytprof $prog

# generated HTML page of profiler
if [ -n "$nytprof" ]; then
    nytprofhtml
fi

