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

    my $self = {%args};

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

    warn "Try to create lockfile: $lockfile, value: $$\n" if $debug >= 1;
    my $delay = $self->{'delay'} || 3;
    my $wait = $self->{'wait'};

    my $max = 29;

    my $lockmgr = LockFile::Simple->make(
        -hold      => 7200,
        -autoclean => 1,
        -max       => $max,
        -stale     => 1,
        -delay     => $delay
    );

    my $res = $wait ? $lockmgr->lock($lockfile) : $lockmgr->trylock($lockfile);

    if ($res) {
        return $lockmgr;
    }

    # return undefined for failure
    else {
        warn "Cannot get lockfile, apparently in use: "
          . "$lockfile, delay: $delay seconds, max: $max, wait: $wait\n"
          if $debug >= 1;
        return;
    }
}

sub remove_lock {
    my $self = shift;
    my %args = @_;

    my $lockfile = $args{'lockfile'};
    my $lockmgr  = $args{'lockmgr'};

    my $pid = read_data("$lockfile.lock");    # xxx
    chomp($pid);

    warn "Remove lockfile: $lockfile, pid $pid\n" if $debug >= 1;

    $lockmgr->unlock($lockfile);

    #unlink($lockfile) or die "unlink $lockfile: $!\n";
}

1;

__DATA__;
