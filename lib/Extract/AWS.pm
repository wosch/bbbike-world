#!/usr/local/bin/perl
# Copyright (c) 2012-2017 Wolfram Schneider, https://bbbike.org
#
# extract AWS S3 functions

package Extract::AWS;

use strict;
use warnings;

##########################
# helper functions
#

our $debug  = 0;
our $option = {};

# Extract::LockFile::new->('debug' => 2, 'option' => $option)
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

sub aws_s3_put {
    my $self = shift;
    my %args = @_;

    my $file = $args{'file'};

    if ( !$option->{"aws_s3_enabled"} ) {
        warn "AWS S3 upload disabled\n" if $debug >= 3;
        return;
    }

    if ( !defined $file || !-e $file ) {
        warn "No file '$file' given or exists for AWS S3 upload\n";
        return;
    }

    my $file_size = file_size_mb($file) . " MB";
    warn "Upload $file with size $file_size to AWS S3\n" if $debug >= 1;

    my $sep = "/";
    my @system =
      ( $option->{"aws_s3"}->{"put_command"}, aws_s3_path($file), $file );
    warn join( " ", @system, "\n" ) if $debug >= 2;

    system(@system) == 0
      or die "system @system failed: $?";
}

sub aws_s3_path {
    my $self = shift;
    my $file = shift;

    my $sep = "/";

    my $aws_path =
        $option->{"aws_s3"}->{"bucket"}
      . $sep
      . $option->{"aws_s3"}->{"path"}
      . $sep
      . basename($file);

    return $aws_path;
}

1;

__DATA__;
