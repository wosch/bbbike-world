#!/bin/sh
# Copyright (c) 2014 Wolfram Schneider, https://bbbike.org
#
# run 6 searches, from bottom left to top right
# 2 diagonal searches, and 4 around the rectangle

P=6
host=dev4.bbbike.org

for city in $(./world/bin/bbbike-db --list)
do
 for heap in 0 1
 do
   for i in 1 2 3
   do
     ./world/bin/bbbike-db --coord $city | perl -ne 'chomp; @a=split; foreach my $b ([0,1,2,1], [2,1,2,3], [2,3,0,3], [0,3,0,1], [0,1,2,3], [2,1,0,3]) { print qq{curl -sSf "http://'$host'/'$city'/?startc=$a[$b->[0]],$a[$b->[1]]&zielc=$a[$b->[2]],$a[$b->[3]]&use_heap='$heap'" | egrep real_time\0}}'| time xargs -0 -P${P} -n1 /bin/sh -c 2>&1 | tee /tmp/city.$city.$heap.$i
   done
 done
done

