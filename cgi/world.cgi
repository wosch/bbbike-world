#!/bin/sh
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# world.cgi - cgi/shell wrapper for bbbike @ world city


name="`basename $0 .cgi`"
dirname=`dirname "$0"`
dirname_original=$dirname

# new directory layout
case "$name" in
	index | index.?? ) 
		name=`basename $dirname`
		dirname="../../../cgi"
		;;
esac

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"

# English Version
case $name in 
	*.en) 
		name=`basename $name .en`
		;;
esac

server=$SERVER_NAME
if [ -z "$server" ]; then
	server=bbbike.org
fi

cache_dir=/var/cache/bbbike/${server}/$name
mkdir -p $cache_dir

#trap 'rm -rf "$cache_dir"; exit 1' 1 2 3 13 15
#trap 'rm -rf "$cache_dir"' 0

# set CPU time and memory limits
# max. 3min 
ulimit -t 180

# max. 1.5GB RAM
ulimit -v 1512000 

time env TMPDIR=$cache_dir DATA_DIR="data-osm/$name" BBBIKE_DATADIR="data-osm/$name" \
	$dirname_original/$name.cgi #$dirname/bbbike.cgi

