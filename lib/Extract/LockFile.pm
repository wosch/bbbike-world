#!/usr/local/bin/perl
# Copyright (c) 2012-2017 Wolfram Schneider, https://bbbike.org
#
# extract config and libraries

package Extract::LockFile;

use LockFile::Simple;
use Data::Dumper;

use Extract::Utils;

require Exporter;
use base qw/Exporter/;
our @EXPORT = qw(create_lock remove_lock);

use strict;
use warnings;

##########################
# helper functions
#

our $debug  = 0;
our $option = {};

# Extract::LockFile::new->('debug' => 2)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = { 'wait' => 0, %args };

    bless $self, $class;
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    if ( defined $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }
    if ( defined $self->{'option'} ) {
        $option = $self->{'option'};
    }
}

sub create_lock {
    my $self = shift;
    my %args = @_;

    my $lockfile = $args{'lockfile'};
    my $wait     = defined $args{'wait'} ? $args{'wait'} : $self->{'wait'};
    my $max      = $args{'max'} // 11;

    if ( -z $lockfile ) {
        warn "Empty lockfile $lockfile - maybe the filesystem is broken\n";
        unlink($lockfile);
    }

    warn
      "Try to create lockfile: $lockfile, value: $$, wait: $wait, max: $max\n"
      if $debug >= 1;

    my $lockmgr = LockFile::Simple->make(
        -hold      => 7200,
        -autoclean => 1,
        -max       => $max,
        -stale     => 1,
        -ext       => ".lock",
    );

    my $res;

    if ( !$wait ) {
        $res = $lockmgr->trylock($lockfile);
    }
    else {
        #
        # We have to implement our own wait for a lock
        # We need to wait a random value, not a fixed time in seconds to
        # avoid a clash with other scripts
        #
        foreach my $i ( 1 .. $max ) {
            $res = $lockmgr->trylock($lockfile);
            if ($res) {
                last;
            }
            else {
                my $random = rand();
                warn "sleep random to get lockfile: $random\n" if $debug >= 3;
                select( undef, undef, undef, $random );
            }
        }
    }

    if ($res) {
        return $lockmgr;
    }

    # return undefined for failure
    else {
        warn "Cannot get lockfile, apparently in use: "
          . "$lockfile, max: $max, wait: $wait\n"
          if $debug >= 1;
        warn `ls -l $lockfile*` if $debug >= 2;

        return;
    }
}

sub remove_lock {
    my $self = shift;
    my %args = @_;

    my $lockfile = $args{'lockfile'};
    my $lockmgr  = $args{'lockmgr'};

    my $pid = read_data("$lockfile.lock");    # -ext => ".lock"
    chomp($pid);

    warn "Remove lockfile: $lockfile, pid $pid\n" if $debug >= 1;

    $lockmgr->unlock($lockfile);

    #unlink($lockfile) or die "unlink $lockfile: $!\n";
}

1;

__DATA__;
