#!/bin/sh
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# world.cgi - cgi/shell wrapper for bbbike @ world city


name="`basename $0 .cgi`"
dirname=`dirname "$0"`

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

# set CPU and memory limits
# max. 120 seconds
ulimit -t 180

# max. 512MB RAM
ulimit -v 1212000 

time env TMPDIR=$cache_dir DATA_DIR="data-osm/$name" BBBIKE_DATADIR="data-osm/$name" perl $dirname/bbbike.cgi

