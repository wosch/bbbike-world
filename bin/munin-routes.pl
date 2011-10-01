#!/usr/local/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# munin-routes - munin statistics for BBBike, searches per interval

use Getopt::Long;
use Data::Dumper;
use File::stat;
use IO::File;

use strict;
use warnings;

#binmode \*STDIN,  ":utf8";
#binmode \*STDOUT, ":utf8";

my $debug    = 1;                              # 0: quiet, 1: normal, 2: verbose
my $database = '/var/tmp/munin-routes.txt';
my $logfile  = '/var/log/lighttpd/bbbike.log';

sub usage {
    <<EOF;
usage: $0 [--debug={0..2}] config

--debug=0..2    		debug option
--logfile=/path/to/logfile	default: $logfile
--database=/path/to/logfile	default: $database
EOF
}

sub config () {
    print <<EOF;
graph_title Load average
graph_vlabel load
load.label load
EOF

    return 0;
}

sub parse_log {
    my %args = @_;

    my $logfile  = $args{'logfile'};
    my $database = $args{'database'};

    if ( !-f $logfile ) {
        die "logfile $logfile does not exists\n";
    }

    my $st = stat($logfile) or die "stat $logfile: $!";

    my $offset = $st->size;

    # first run, save file offset of logfile, do nothing
    if ( !-e $database ) {
        write_offset( $database, $offset );
        return 0;
    }
    my $last_offset = get_offset($database);

    my $route_count =
      count_routes( 'logfile' => $logfile, 'offset' => $offset );

    return $route_count;
}

sub get_offset {
    my $file = shift;

    my $fh = IO::File->new( $file, "r" ) or die "open $file: $!\n";
    my $number = <$fh>;

    chomp($number);

    warn "Got offset $number from $file\n" if $debug;
    return $number;
}

sub write_offset {
    my $file   = shift;
    my $offset = shift;

    warn "Store offset $offset in $file\n" if $debug;
    my $fh = IO::File->new( $file, "w" ) or die "open $file: $!\n";
    print $fh $offset;
    $fh->close;
}

######################################################################
# main
#

GetOptions(
    "debug=i"    => \$debug,
    "database=s" => \$database,
) or die usage;

if ( defined $ARGV[0] && $ARGV[0] eq 'config' ) {
    exit(&config);
}
else {
    &parse_log( 'logfile' => $logfile, 'database' => $database );
}

