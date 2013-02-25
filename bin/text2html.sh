#!/bin/sh
# Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
#
# text2html - convert a README.txt to README.html
#

#set -e
#PATH=$HOME/bin:/bin:/usr/bin; export PATH

(
  echo "<html><head><title>README</title></head><body><pre>"
  perl -npe 's,(http://\S+),<a href="$1">$1</a>,g'
  echo "</pre></body></html>"
) | tidy -raw -i /dev/stdin 2>/dev/null

exit 0
