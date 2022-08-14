#!/bin/bash
# Copyright (c) June 2022 Wolfram Schneider, https://bbbike.org
#
# garmin-example-styles - convert some example countries to all garmin styles
#

PATH=/bin:/usr/bin:/usr/local/bin; export PATH

set -e
set -o pipefail

DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"
countries="europe/luxembourg-latest.osm.pbf asia/jordan-latest.osm.pbf asia/cambodia-latest.osm.pbf"
: ${debug=false}
$debug && time=time

download_region ()
{
  region="$1"
  url="$DOWNLOAD_URL_PREFIX/$region"
  out=$(basename $url -latest.osm.pbf).osm.pbf

  curl --connect-timeout 10 --retry 10 --max-time 200 -sSf -L "$url" | \
    osmconvert --drop-author --drop-version --out-pbf - > $out.tmp
  mv -f $out.tmp $out

  echo $out
}

for region in $countries
do
(
  $debug && echo "region=$region"
  name=$(basename $region -latest.osm.pbf)
  dir=$(mktemp -d $name.XXXXXXXX)
  cd $dir

  out=$(download_region $region)
  env osm2xxx_max_jobs="8" OSM_CHECKSUM=false BBBIKE_TMPFS=/tmp \
      nice -11 $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-all $out $name
  env osm2xxx_max_jobs="8" OSM_CHECKSUM=false BBBIKE_TMPFS=/tmp \
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

#EOF
