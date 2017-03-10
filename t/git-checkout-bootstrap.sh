#!/bin/sh
# Copyright (c) Aug 2015-2015 Wolfram Schneider, https://bbbike.org
#
# check if git checkout bootstrapping is working

set -e
dir=$(mktemp -d)
cd $dir

curl -sSfL https://github.com/wosch/bbbike-world/raw/world/bin/bbbike-bootstrap | /bin/sh
rm -rf $dir


