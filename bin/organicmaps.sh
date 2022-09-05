#!/bin/sh
# Copyright (c) Sep 2022 Wolfram Schneider, https://bbbike.org
#
# organicmaps - convert a osm/pbf file to organicmaps
#

set -e
PATH=/bin:/usr/bin:/usr/local/bin; export PATH

#: ${OMIM_PATH=/var/lib/bbbike/opt/omim}
: ${OMIM_PATH="$HOME/projects/organicmaps"}
: ${BBBIKE_TMPDIR="/bbbike/tmp"}
: ${BBBIKE_TMPFS="/tmp"}
: ${debug=false}

# avoid locale warnings
unset LANGUAGE LOCALE LANG
pwd=$(pwd)

# use RAM disk
tmpdir=$(mktemp -d ${BBBIKE_TMPFS}/organicmaps.XXXXXXXXXXX)

usage () {
   echo "$@"
   echo "usage file.pbf file.poly [style]"
   rm -rf $tmpdir
   exit 1
}


# no spaces in filenames please
file=$1
poly=$2

test -z "$file" && usage "missing file"
test -e $file || usage "file '$file' does not exists"

# create missing poly file based on PBF info on the fly
if [ -z "$poly" ]; then
  poly=$tmpdir/$(basename $file .osm.pbf).poly
  $(dirname $0)/pbf-bounds-poly.sh $file > $poly 
fi

test -e $poly || usage "file '$poly' does not exists"

# we need absolute file path
case $file in /*) ;; *) file=$pwd/$file ;; esac
case $poly in /*) ;; *) poly=$pwd/$poly ;; esac

# we need a copy of organicmaps/data
rsync -r -Hl --exclude=borders $OMIM_PATH/data $tmpdir
mkdir -p $tmpdir/data/borders
cp $poly $tmpdir/data/borders

# default parameters
routing="--make_routing_index=true --make_cross_mwm=true"
basic=" --node_storage=map --generate_features=true --generate_geometry=true --generate_index=true"
file_type="--node_storage=map --osm_file_type=o5m"

input_file=$tmpdir/$(basename $file .pbf).o5m
intermediate_data_path=$tmpdir/intermediate
city=$(basename $file .osm.pbf)
output_file=$(dirname $file)/$city.mwm
mkdir -p $intermediate_data_path

# organicmaps needs o5m files instead PBF
osmconvert --out-o5m $file > $input_file

(
# XXX: needs access to a local ./data directory
cd $tmpdir

# pre-processing
generator_tool $file_type --preprocess=true  --intermediate_data_path=$intermediate_data_path  --osm_file_name=$input_file --data-path=$tmpdir/data

# main
generator_tool $file_type $basic $routing --intermediate_data_path=$intermediate_data_path --osm_file_name=$input_file --data-path=$tmpdir/data --output=$city --stats_general
)

# show mwm statistics
cat $intermediate_data_path/$city.stats

cp -f $tmpdir/data/$city.mwm $output_file.tmp
mv -f $output_file.tmp $output_file

# final cleanup
rm -rf $tmpdir

#EOF
