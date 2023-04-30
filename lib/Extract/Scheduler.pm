#!/usr/local/bin/perl
# Copyright (c) 2012-2017 Wolfram Schneider, https://bbbike.org
#
# extract config and libraries

package Extract::Scheduler;

use JSON;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Config;
use Extract::Utils qw(read_data);

use strict;
use warnings;

##########################
# helper functions
#

our $debug  = 0;
our $option = {};

# Extract::Scheduler::new->('q'=> $q, 'option' => $option)
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

    my $utils = Extract::Utils->new( 'debug' => $debug );
}

sub running_users {
    my $self  = shift;
    my $files = shift;

    my @files = $files ? @$files : ();

    my $spool_dir       = $Extract::Config::spool_dir;
    my $extract_running = $Extract::Config::spool->{'running'};

    # check for absolute path, and prefix it if necessary
    if ( $extract_running !~ m,^/, ) {
        $extract_running = "$spool_dir/$extract_running";
    }

    # without arguments, get the files from the running directory
    if ( !@files ) {
        my $pattern = "$extract_running/[0-9a-f]*[0-9-a-f]/*json";
        warn "Glob jobs path $pattern debug=$debug\n" if $debug >= 2;

        @files = glob($pattern);
    }

    warn join "\n", @files if $debug >= 3;
    return $self->_running_users( \@files );
}

sub _running_users {
    my $self  = shift;
    my $files = shift;

    return {} if !$files || ref $files ne 'ARRAY';
    my @files = @$files;

    my $hash = {};

    foreach my $file (@files) {
        warn "parse file $file\n" if $debug >= 2;

        my $json_text;
        if ( -z $file ) {
            warn "Warning: File is empty, ignore: $file\n";
            unlink($file);
            next;
        }
        elsif ( -f $file ) {
            eval { $json_text = read_data($file) };
            if ($@) {
                warn "Race condition, job already done (?): $file\n";
                next;
            }
        }
        else {
            warn "Warning: File does not exists, ignore: $file\n";
            next;
        }

        my $json      = new JSON;
        my $json_perl = eval { $json->decode($json_text) };
        die "json $file $@" if $@;

        #json_compat($json_perl);
        print $json_perl->{'email'}, "\n" if $debug >= 3;

        $hash->{ $json_perl->{'email'} } += 1;
    }

    return $hash;
}

# detect bots by user agent, or other meta data
sub is_bot {
    my $self = shift;
    my $obj  = shift;

    my @bots       = @{ $option->{'bots'}{'names'} };
    my $user_agent = $obj->{'user_agent'};

    # legacy config jobs
    if ( !defined $user_agent ) {
        $user_agent = "";
    }

    return ( grep { $user_agent =~ /$_/ } @bots ) ? 1 : 0;
}

# returns 1 if we want to ignore a bot, otherwise 0
sub ignore_bot {
    my $self = shift;
    my %args = @_;

    my $loadavg    = $args{'loadavg'};
    my $city       = $args{'city'};
    my $obj        = $args{'obj'};
    my $job_number = $args{'job_number'};

    warn
      "detect bot for area '$city', user agent: '@{[ $obj->{'user_agent'} ]}'\n"
      if $debug >= 1;

    if (   $option->{'bots'}{'detecation'}
        && $loadavg >= $option->{'bots'}{'max_loadavg'} )
    {

        # soft bot handle
        if (   $option->{'bots'}{'scheduler'} == 1
            && $job_number == 1 )
        {
            warn
"accepts bot request for area '$city' for first job queue: $loadavg\n"
              if $debug >= 1;
        }

        # hard ignore
        else {
            warn
"ignore bot request for area '$city' due high load average: $loadavg\n"
              if $debug >= 1;
            return 1;
        }
    }

    return 0;
}

# returns number of total running jobs (all users)
sub total_jobs {
    my $self = shift;
    my %args = @_;

    my $hash    = $args{'email'};
    my $counter = 0;

    foreach my $key ( keys %$hash ) {
        $counter += $hash->{$key};
    }

    return $counter;
}

1;

__DATA__;
