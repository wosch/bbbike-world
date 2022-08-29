#!/bin/bash
# Copyright (c) June 2022 Wolfram Schneider, https://bbbike.org
#
# garmin-example-styles - convert some example countries to all garmin styles
#

PATH="/bin:/usr/bin:/usr/local/bin"; export PATH

set -e
set -o pipefail

: ${debug=false}
countries="europe/luxembourg asia/jordan asia/cambodia"
example_dir="/usr/local/www/download.bbbike.org/osm/garmin/example"

$debug && time=time
mkdir -p $example_dir

cd $example_dir
env debug=$debug osm2xxx_max_jobs="8" regions="$countries" garmin_formats="all-latin1" max_days="3" \
  time $HOME/projects/bbbike-download/bin/garmin-all.sh > /var/tmp/garmin-$(basename $0).log 2>&1

#EOF
