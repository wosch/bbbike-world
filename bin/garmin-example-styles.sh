#!/bin/bash
# Copyright (c) June 2022 Wolfram Schneider, https://bbbike.org
#
# garmin-example-styles - convert some example countries to all garmin styles
#

PATH="/bin:/usr/bin:/usr/local/bin"; export PATH

set -e
set -o pipefail

: ${debug=false}
: ${max_days="3"}
#: ${garmin_formats="all-latin1"}
: ${garmin_formats="osm:ajt03:cycle:leisure:bbbike:onroad:ontrail:openfietslite:openfietsfull:oseam:opentopo:osm-latin1:ajt03-latin1:cycle-latin1:leisure-latin1:bbbike-latin1:onroad-latin1:ontrail-latin1:openfietslite-latin1:openfietsfull-latin1:oseam-latin1:opentopo-latin1"}
countries="europe/luxembourg asia/jordan asia/cambodia"
example_dir="/usr/local/www/download.bbbike.org/osm/garmin/example"

$debug && time=time
mkdir -p $example_dir

cd $example_dir
env debug=$debug osm2xxx_max_jobs="8" regions="$countries" garmin_formats="$garmin_formats" max_days=$max_days \
  time $HOME/projects/bbbike-download/bin/garmin-all.sh > /var/tmp/garmin-$(basename $0).log 2>&1

#EOF
