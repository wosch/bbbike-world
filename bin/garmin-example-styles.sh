#!/bin/bash
# Copyright (c) June 2022 Wolfram Schneider, https://bbbike.org
#
# garmin-example-styles - convert some example countries to all garmin styles
#

set -e
set -o pipefail

DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"
countries="europe/luxembourg-latest.osm.pbf asia/jordan-latest.osm.pbf asia/cambodia-latest.osm.pbf"
: ${time=time}

download_region ()
{
  region="$1"
  url="$DOWNLOAD_URL_PREFIX/$region"
  out=$(basename $url -latest.osm.pbf).osm.pbf

  curl --connect-timeout 10 -sSf -L "$url" | osmconvert --drop-author --drop-version --out-pbf - > $out.tmp
  mv -f $out.tmp $out

  echo $out
}

for region in $countries
do
(
  echo "region=$region"
  name=$(basename $region -latest.osm.pbf)
  dir=$(mktemp -d $name.XXXXXXXX)
  cd $dir

  out=$(download_region $region)
  env osm2xxx_max_jobs="8" OSM_CHECKSUM=false \
      nice -11 $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-all $out $name
  env osm2xxx_max_jobs="8" OSM_CHECKSUM=false \
      nice -12 $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-all-latin1 $out $name
  rm -f $out

  # rename directory
  cd ..
  if [ -e $name ]; then 
    mv $name $dir.old
  fi
  mv $dir $name
  chmod a+rx $name
  rm -rf $dir.old
)
done

