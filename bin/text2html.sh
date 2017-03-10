#!/bin/sh
# Copyright (c) 2013 Wolfram Schneider, https://bbbike.org
#
# text2html - convert a README.txt to README.html
#

#set -e
PATH=/usr/local/bin:/bin:/usr/bin; export PATH

(
  echo "<html><head><title>README</title></head><body><pre>"
  perl -npe 's,(https?://\S+),<a href="$1">$1</a>,gi'
  echo "</pre></body></html>"
) | tidy -wrap -raw -i /dev/stdin 2>/dev/null |
    perl -npe 's,^  <meta name="generator" content="HTML Tidy.*\n,  <meta http-equiv="content-type" content="text/html; charset=utf-8">,'

exit 0
