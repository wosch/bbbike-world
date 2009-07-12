#!/bin/sh

name="`basename $0 .cgi`"
dirname=`dirname "$0"`

export LANG="C"
export PATH="/opt/local/bin:/bin:/usr/bin:/usr/local/bin"

# English Version
case $name in 
	*.en) 
		name=`basename $name .en`
		;;
esac

tmpdir=`mktemp -d /tmp/bbbike.XXXXXXXXXXXXXXX`

trap 'rm -rf "$tmpdir"; exit 1' 1 2 3 13 15
trap 'rm -rf "$tmpdir"' 0


# set CPU and memory limits

# max. 120 seconds
ulimit -t 120

# max. 512MB RAM
ulimit -v 512000 

env TMPDIR=$tmpdir DATA_DIR="data-osm/$name" BBBIKE_DATADIR="data-osm/$name" perl $dirname/bbbike.cgi

