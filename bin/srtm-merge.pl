#!/usr/bin/perl
#
# mkdir ../osm
# ls *.zip | perl -MFile::Basename -ne 'chomp; $num = 10_000 if !$num; print qq{zcat $_ | perl -npe "s, (ref|id)=\\\"10, \\\$1=\\\"$num," | osmconvert --fake-version - | pigz > ../osm/}, basename($_, ".zip"), ".gz\0"; $num++' | nice -20 time xargs -n1 -P6 -0 /bin/sh -c >& a.log
#

use strict;
use warnings;

my ( @a, @b );

my $max = `ls *.pbf | wc -l`; #16767; # 1022; # 1676 16747
my $factor = 12;

for ( 1 .. (int($max/$factor) + 1 )) {
    my $rest = $max - ($_ - 1) * $factor > $factor ? $factor : ($max - ($_ - 1) * $factor);

    print qq{head -}, ( $_ * $factor ),
      qq{ .list | tail -$rest | },
q{perl -e '@a=("osmosis", "-q"); while(<>) { chomp; push @a, "--read-pbf",  $_,;  push @b, "--merge"}; pop @b; print join " ", @a, @b, "--write-pbf",  "omitmetadata=true", "../merged/}, "$_.pbf.tmp && mv -f ../merged/$_.pbf.tmp ../merged/$_.pbf", qq{" ' | /bin/sh\n};

}

