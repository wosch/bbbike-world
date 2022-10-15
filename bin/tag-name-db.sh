#!/bin/sh
# Copyright (c) Sep 2022 Wolfram Schneider, https://extract.bbbike.org
#
# tag-name-db.sh - create a database of OSM tag name / description

set -e

PATH="/usr/local/bin:/bin:/usr/bin"; export PATH
database_name="tag-name.csv.xz"
: ${planet_osm="planet-daily.osm.pbf"}

cd $HOME/projects/osm/download
mkdir -p tmp
tmpfile=$(mktemp tmp/.${database_name}.XXXXXXXXXX)

osmconvert --out-csv --csv="name description @oname @id" $planet_osm |
  # faster pipe on linux
  mbuffer -q -m 128m |

  # filter out objects without description, GNU grep
  egrep -v  '^[[:space:]]+[a-z]+[[:space:]][0-9]+$' | 

  # node -> n, way -> w, relation -> r
  perl -npe 's/(\tn)ode\t(\d+)$/$1$2/ || s/(\tw)ay\t(\d+)$/$1$2/ || s/(\tr)elation\t(\d+)$/$1$2/' |

  # sort by description, not by node id
  sort |

  # high compression
  pixz -9 > $tmpfile

mv -f $tmpfile $database_name

#EOF

