#!/usr/local/bin/perl
# Copyright (c) April 2014-2014 Wolfram Schneider, http://bbbike.org
#
# mkdir ../osm
# ls *.zip | perl -MFile::Basename -ne 'chomp; $num = 10_000 if !$num; print qq{zcat $_ | perl -npe "s, (ref|id)=\\\"10, \\\$1=\\\"$num," | osmconvert --fake-version - | pigz > ../osm/}, basename($_, ".zip"), ".gz\0"; $num++' | nice -20 time xargs -n1 -P6 -0 /bin/sh -c >& a.log
#

use IO::File;
use Getopt::Long;
use File::Temp;
use Data::Dumper;

use strict;
use warnings;

binmode( \*STDERR, ":raw" );
binmode( \*STDOUT, ":raw" );

my $help;
my $max_cpu   = 2;
my $max_files = 40;
my $debug     = 1;
my $merge_dir = "pbf-merge";

sub usage {
    my $message = shift || "";

    <<EOF;
@{[$message]}
    
usage: $0 [options] file1.pbf file2.pbf ....

--debug=0..2              debug option
--max-files=2..100        max. files merged default: $max_files
--merge-dir=/path/to/dir  where to write results, default: $merge_dir
--max-cpu=1..N            max. number of parallel processes, default: $max_cpu

EOF
}

sub validate_input {
    if ( $max_files < 2 || $max_files > 100 ) {
        warn "max_files out of range 2..100: $max_files\n" if $debug;
        $max_files = 40;
        warn " reset max_files to $max_files\n" if $debug;
    }

    if ( $max_cpu < 1 || $max_cpu > 32 ) {
        warn "max_cpu out of range 1..32: $max_cpu\n" if $debug;
        $max_cpu = 2;
        warn " reset max_cpu to $max_cpu\n" if $debug;
    }
}

GetOptions(
    "debug=i"     => \$debug,
    "max-files=i" => \$max_files,
    "merge-dir=s" => \$merge_dir,
    "max-cpu=i"   => \$max_cpu,
    "help"        => \$help,
) or die usage;

my @files = @ARGV;
die &usage if $help;
die usage("No files given") if !@files;

&validate_input();

#my $max    = `ls *.pbf | wc -l`;    #16767; # 1022; # 1676 16747
#my $factor = 12;
#for ( 1 .. (int($max/$factor) + 1 )) {
#    my $rest = $max - ($_ - 1) * $factor > $factor ? $factor : ($max - ($_ - 1) * $factor);
#
#    print qq{head -}, ( $_ * $factor ),
#      qq{ .list | tail -$rest | },
#q{perl -e '@a=("osmosis", "-q"); while(<>) { chomp; push @a, "--read-pbf",  $_,;  push @b, "--merge"}; pop @b; print join " ", @a, @b, "--write-pbf",  "omitmetadata=true", "../merged/}, "$_.pbf.tmp && mv -f ../merged/$_.pbf.tmp ../merged/$_.pbf", qq{" ' | /bin/sh\n};
#
#}

