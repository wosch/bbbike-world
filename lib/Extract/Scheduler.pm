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

#require Exporter;
#use base qw/Exporter/;
#our @EXPORT = qw(save_request complete_save_request check_queue Param large_int square_km);

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

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

    my $utils = Extract::Utils->new( 'debug' => $debug );
}

sub running_users {
    my $self  = shift;
    my $files = shift;

    my @files = $files ? @$files : ();

    my $spool_dir       = $Extract::Config::spool_dir;
    my $extract_running = "$spool_dir/" . $Extract::Config::spool->{'running'};

    # without arguments, get the files from the running directory
    if ( !@files ) {
        my $pattern = "$extract_running/[0-9a-f]*[0-9-a-f]/*json";
        warn "Glob $pattern\n" if $debug >= 2;

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
        if ( -f $file ) {
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

        my $json = new JSON;
        my $json_perl = eval { $json->decode($json_text) };
        die "json $file $@" if $@;

        #json_compat($json_perl);
        print $json_perl->{'email'}, "\n" if $debug >= 3;

        $hash->{ $json_perl->{'email'} } += 1;
    }

    return $hash;
}

#my $hash = &running_users( \@files );
#print Dumper($hash);

1;

__DATA__;
