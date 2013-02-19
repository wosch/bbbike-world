#!/bin/sh
# Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
#
# extract-cron.sh - wrapper for extract.pl script 
#
# the subject line contains the exit status

PATH=/bin:/usr/bin; export PATH
set -e

prog=$(echo $0 | perl -npe 's/-cron\.sh$/.pl/')
subject="bbbike extract status:"

tmp=$(mktemp -t extract.XXXXXXXXXXX)

$prog --debug=1 $@ > $tmp 2>&1
error=$?

# it run
if [ -s $tmp ]; then
    mail -s "$subject $error" $(whoami) < $tmp
fi
rm -f $tmp

