#!/bin/bash
# Copyright (c) 2009-2023 Wolfram Schneider, https://bbbike.org
#
# srtm-download - download SRTM planet
#

set -e
PATH="/usr/local/bin:/bin:/usr/bin"; export PATH

files="CHECKSUM.txt planet-srtm-e40.osm.pbf.timestamp planet-srtm-e40.osm.pbf"
srtm_download_url="https://download3.bbbike.org/osm/planet/srtm"

if [ -e "$bbbikerc" ]; then
    . "$bbbikerc"
fi

dir=$HOME/projects/osm/download/srtm

mkdir -p $dir
cd $dir

for i in $files
do
  if [ ! -e "$i" ]; then
    curl -sSf --connect-timeout 5 -m 3600 -O "$srtm_download_url/$i"
  fi
done

#EOF
