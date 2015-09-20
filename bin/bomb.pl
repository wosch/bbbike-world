#!/usr/bin/perl
# Copyright (c) 2015 Wolfram Schneider, http://bbbike.org
#
# bomb.pl - wrapper to stop a process after N seconds
#

use Getopt::Long;

use strict;
use warnings;

my $debug = 0;
my $help;
my $timeout = 100;
my $pid;
my $screenshot_file;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

sub usage () {
    <<EOF;
usage: $0 [ options ] command args ....

--debug=0..3    debug option, default: $debug
--timeout=1..N  timeout in seconds, default: $timeout
--screenshot-file=/path/to/image.png if set, does a screen shot
EOF
}

GetOptions(
    "help"              => \$help,
    "debug=i"           => \$debug,
    "timeout=f"         => \$timeout,
    "screenshot-file=s" => \$screenshot_file,
) or die usage;

my @system = @ARGV;

die usage if $help;
die usage if !@system;

#
# configure signal handlers
#
$SIG{ALRM} = sub {
    my $pgid = getpgrp();

    warn "Alarm handler got called after $timeout seconds\n";
    warn "Kill now the process group $pgid\n\n";
    warn "Command: @system\n";

    if ($screenshot_file) {
        if ( $ENV{DISPLAY} ) {
            system(
"xwd -root -display $ENV{DISPLAY} | xwdtopnm | pnmtopng > $screenshot_file"
              ) == 0
              or warn "system screenshot failed: $? $!\n";
            warn "Screenshot file:  $screenshot_file\n";
        }
        else {
            warn "env DISPLAY not set, cannot take a screen shot\n";
        }

    }

    # kill process group
    kill "TERM", -$pgid;

    # wait a little bit
    sleep 3;
    system("pgrep -l -g $pgid");

    warn "Final kill -9 now the process group $pgid\n";
    kill "KILL", -$pgid;
};

# don't kill ourself
$SIG{TERM} = "IGNORE";

alarm($timeout);

system(@system) == 0
  or die "system('@system') failed: ?='$?', !='$!'\n";

1;

