#!/usr/local/bin/perl
# Copyright (c) April 2014-2014 Wolfram Schneider, http://bbbike.org
#
# mkdir ../osm
# ls *.zip | perl -MFile::Basename -ne 'chomp; $num = 10_000 if !$num; print qq{zcat $_ | perl -npe "s, (ref|id)=\\\"10, \\\$1=\\\"$num," | osmconvert --fake-version - | pigz > ../osm/}, basename($_, ".zip"), ".gz\0"; $num++' | nice -20 time xargs -n1 -P6 -0 /bin/sh -c >& a.log
#
# TODO: multi-process. At the moment osmosis is multi-threaded, with up to 300% CPU
#       usage (good enough for now)

use IO::File;
use Getopt::Long;
use File::Temp;
use Digest::MD5 qw(md5_hex);
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
my $random    = 0;

sub usage {
    my $message = shift || "";

    <<EOF;
@{[$message]}
    
usage: $0 [options] file1.pbf file2.pbf ....

--debug=0..2              debug option
--max-files=2..100        max. files merged default: $max_files
--merge-dir=/path/to/dir  where to write results, default: $merge_dir
--max-cpu=1..N            max. number of parallel processes, default: $max_cpu
--random=0|1              merge files in random order, default: $random

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

sub create_script {
    my %args = @_;

    my $files     = $args{'files'};
    my $max_files = $args{'max_files'};
    my $merge_dir = $args{'merge_dir'};
    my $max_cpu   = $args{'max_cpu'};
    my @files     = @$files;

    warn Dumper( \%args ) if $debug >= 2;

    # up top 2^N rounds, 26 should be enough
    foreach my $round ( 'a' .. 'z' ) {
        my @round;
        my @data;
        my @script;
        my $counter = 0;
        my $out;

        for ( my $i = 0 ; $i < @files ; $i++ ) {
            my $file = $files[$i];

            push @data, $file;
            if ( scalar(@data) == $max_files || ( @data && $i == $#files ) ) {
                $out = "$merge_dir/$round-$counter.pbf";
                my $script = create_merge( $out, \@data );
                push @script, $script;
                $counter++;
                undef @data;
                push @round, $out;
            }
        }

        if (@script) {
            print "# round: $round\n";
            print join "\n", @script, "";
        }

        # another round?
        if ( @round > 1 ) {
            @files = @round;
        }
        else {
            @files = ();
            print "# Last round: $out\n";
            last;
        }
    }
}

sub create_merge {
    my ( $merge_file, $data ) = @_;
    my @files = @$data;

    my @script = ( "time", "osmosis", "-q" );
    my @todo;
    foreach my $file (@files) {
        push @script, ( "--read-pbf", $file );
        push @todo, "--merge";
    }

    pop @todo;
    push @script, @todo;
    push @script, ( "--write-pbf", "omitmetadata=true", "$merge_file.tmp" );
    push @script, (" && mv -f $merge_file.tmp $merge_file");

    return join " ", @script;
}

sub random_files {
    my @files = @_;

    my %hash = map { $_ => md5_hex($_) } @files;
    my @list = sort { $hash{$a} cmp $hash{$b} } @files;

    return @list;
}

sub check_merge_dir {
    my $merge_dir = shift;

    if ( -d $merge_dir ) {
        warn "Merge directory '$merge_dir' exists\n" if $debug >= 2;
    }
    else {
        system( "mkdir", "-p", $merge_dir ) == 0
          or die "mkdir exit status: $?\n";
    }
}

#############################################################################
# main
#
GetOptions(
    "debug=i"     => \$debug,
    "max-files=i" => \$max_files,
    "merge-dir=s" => \$merge_dir,
    "max-cpu=i"   => \$max_cpu,
    "random=i"    => \$random,
    "help"        => \$help,
) or die usage;

my @files = @ARGV;
die &usage if $help;
die usage("No files given") if !@files;

if ($random) {
    warn "Re-sort files in random order\n" if $debug >= 1;
    @files = &random_files(@files);
}

&validate_input();
&check_merge_dir($merge_dir);

&create_script(
    'files'     => \@files,
    'merge_dir' => $merge_dir,
    'max_cpu'   => $max_cpu,
    'max_files' => $max_files
);

