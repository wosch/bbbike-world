#!/usr/local/bin/perl
# Copyright (c) April 2014-2014 Wolfram Schneider, http://bbbike.org
#
# osm-upgrade - upgrade osm 0.5 to osm 0.6 with osmconvert
#               create unique IDs across all input files
#

use Getopt::Long;
use File::Basename;
use Data::Dumper;

use strict;
use warnings;

binmode( \*STDERR, ":raw" );
binmode( \*STDOUT, ":raw" );

my $help;
my $max_nodes = 1;
my $debug     = 0;
my $out_dir   = "osm";

sub usage {
    my $message = shift || "";

    <<EOF;
@{[$message]}
    
usage: $0 [options] file1.osm.zip file2.osm.gz ....

--debug=0..2              debug option
--max-nodes=0..1          old osmosis with max. 65000 nodes in a way, default: $max_nodes
--out-dir=/path/to/dir    where to write results, default: $out_dir

EOF
}

# ls *.zip | perl -MFile::Basename -ne 'chomp; $num = 10_000 if !$num;
#   print qq{zcat $_ | perl -npe "s, (ref|id)=\\\"10, \\\$1=\\\"$num," | },
#         qq{osmconvert --fake-version - | },
#         qq{perl -ne 'if (/<nd /) {$a++; if ($a > 65_000) { next} } else {$a=0}
#         qq{pigz > ../osm/}, basename($_, ".zip"), ".gz\0"; $num++' |
#   nice -20 time xargs -n1 -P6 -0 /bin/sh -c >& a.log

sub create_script {
    my %args = @_;

    my $files     = $args{'files'};
    my $max_nodes = $args{'max_nodes'};
    my $out_dir   = $args{'out_dir'};
    my @files     = @$files;

    warn Dumper( \%args ) if $debug >= 2;

    # find the fastest gzip program
    my $gzip = `which pigz gzip | head -1`;
    chomp($gzip);

    my $num = 10_000;
    foreach my $file (@files) {

        print qq{$gzip -dc $file | },
          qq{perl -npe "s, (ref|id)=\\\"10, \\\$1=\\\"$num," | },
          qq{osmconvert --fake-version - | };

        print
q{perl -ne 'if (/<nd /) { $a++; if ($a > 65_000) { next } } else { $a=0 }; print' | }
          if $max_nodes;

        my $out_file = "$out_dir/" . basename( $file, ".zip", ".gz" ) . ".gz";
        print qq{$gzip > $out_file.tmp && mv -f $out_file.tmp $out_file\0};
        $num++;
    }
}

sub check_out_dir {
    my $out_dir = shift;

    if ( -d $out_dir ) {
        warn "Merge directory '$out_dir' exists\n" if $debug >= 1;
    }
    else {
        warn "Create out_dir directory '$out_dir'\n" if $debug >= 1;
        system( "mkdir", "-p", $out_dir ) == 0
          or die "mkdir exit status: $?\n";
    }
}

#############################################################################
# main
#
GetOptions(
    "debug=i"     => \$debug,
    "max-nodes=i" => \$max_nodes,
    "out-dir=s"   => \$out_dir,
    "help"        => \$help,
) or die usage;

my @files = @ARGV;
die &usage if $help;
die usage("No files given") if !@files;

&check_out_dir($out_dir);
&create_script(
    'files'     => \@files,
    'out_dir'   => $out_dir,
    'max_nodes' => $max_nodes
);

