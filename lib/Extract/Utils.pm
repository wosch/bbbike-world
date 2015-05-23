#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# extract config and libraries

package Extract::Utils;

use JSON;
use File::Basename;
use File::stat;
use Data::Dumper;

require Exporter;
@EXPORT = qw(normalize_polygon);

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

# Extract::Utils::new->('q'=> $q, 'option' => $option)
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
}

# scale file size in x.y MB
sub file_size_mb {
    my $self = shift;
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

sub parse_json_file {
    my $self      = shift;
    my $file      = shift;
    my $non_fatal = shift;

    warn "Open file '$file'\n" if $debug >= 2;

    my $fh = new IO::File $file, "r" or die "open '$file': $!\n";
    binmode $fh, ":utf8";

    my $json_text;
    while (<$fh>) {
        $json_text .= $_;
    }
    $fh->close;

    my $json = new JSON;
    my $json_perl = eval { $json->decode($json_text) };
    if ($@) {
        warn "parse json file '$file' $@\n";
        exit(1) if $non_fatal;
    }

    warn Dumper($json_perl) if $debug >= 3;
    return $json_perl;
}

# random sort of filenames
sub random_filename_sort {
    my $self = shift;
    return $self->random_sort(@_);
}

sub random_sort {
    my $self  = shift;
    my @files = @_;

    my %hash = map { $_ => rand() } @files;

    return sort { $hash{$a} <=> $hash{$b} } keys %hash;
}

# compare 2 files and return the modification diff time in seconds
sub file_mtime_diff {
    my $self  = shift;
    my $file1 = shift;
    my $file2 = shift;

    my $st1 = stat($file1) or die "stat $file1: $!\n";
    my $st2 = stat($file2) or die "stat $file2: $!\n";

    return $st1->mtime - $st2->mtime;
}

###########################################################################
# from extract.cgi
#

# fewer points, max. 1024 points in a polygon
sub normalize_polygon {
    my $poly = shift;
    my $max = shift || 1024;

    my $same = '0.001';
    warn "Polygon input: " . Dumper($poly) if $debug >= 3;

    # max. 10 meters accuracy
    my @poly = polygon_simplify( 'same' => $same, @$poly );

    # but not more than N points
    if ( scalar(@poly) > $max ) {
        warn "Resize 0.01 $#poly\n" if $debug >= 1;
        @poly = polygon_simplify( 'same' => 0.01, @$poly );
        if ( scalar(@poly) > $max ) {
            warn "Resize $max points $#poly\n" if $debug >= 1;
            @poly = polygon_simplify( max_points => $max, @poly );
        }
    }

    return @poly;
}

# save request in confirmed spool
sub save_request {
    my $obj       = shift;
    my $spool_dir = shift;
    my $confirmed = shift;

    my $spool_dir_confirmed = "$spool_dir/$confirmed";

    my $json      = new JSON;
    my $json_text = $json->pretty->encode($obj);

    my $key = md5_hex( encode_utf8($json_text) . rand() );
    my $job = "$spool_dir_confirmed/$key.json.tmp";

    warn "Store request $job: $json_text\n" if $debug;

    my $fh = new IO::File $job, "w";
    if ( !defined $fh ) {
        warn "Cannot open $job: $!\n";
        return;
    }
    binmode $fh, ":utf8";

    print $fh $json_text, "\n";
    $fh->close;

    return ( $key, $job );
}

# foo.json.tmp -> foo.json
sub complete_save_request {
    my $file = shift;
    if ( !$file || !-e $file ) {
        warn "file '$file' does not exists\n";
        return;
    }

    my $temp_file = $file;
    $temp_file =~ s/\.tmp$//;

    if ( $file eq $temp_file ) {
        warn "$file has no .tmp extension\n";
        return;
    }

    if ( rename( $file, $temp_file ) ) {
        return $temp_file;
    }
    else {
        warn "rename $file -> $temp_file: $!\n";
        return;
    }
}

1;

__DATA__;
