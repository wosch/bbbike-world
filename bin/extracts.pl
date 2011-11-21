#!/usr/local/bin/perl
# Copyright (c) 2011 Wolfram Schneider, http://bbbike.org
#
# extracts.pl - extracts areas in a batch job

use IO::File;
use IO::Dir;
use JSON;
use Data::Dumper;
use Encode;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use CGI qw(escapeHTML);
use Getopt::Long;

use strict;
use warnings;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/var/tmp/bbbike/extracts';

# max. area in square km
my $max_skm = 50_000;

# sent out emails as
my $email_from = 'bbbike@bbbike.org';

my $option = {
    'max_extracts'   => 50,
    'min_wait_time'  => 5 * 60,    # in seconds
    'default_format' => 'pbf',
};

my $formats = {
    'pbf'     => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
};

my $spool = {
    'incoming'  => "$spool_dir/incoming",
    'confirmed' => "$spool_dir/confirmed",
    'running'   => "$spool_dir/running",
    'osm'       => "$spool_dir/osm",
    'download'  => "$spool_dir/download",
    'job1'      => "$spool_dir/job1.pid",
};

# group writable file
umask(002);

######################################################################
#
#
sub get_jobs {
    my $dir = shift;

    my $d = IO::Dir->new($dir);
    if ( !defined $d ) {
        warn "Error directory $dir: $!\n";
        return ();
    }

    my @data;
    while ( defined( $_ = $d->read ) ) {
        next if !/\.json$/;
        push @data, $_;
    }
    undef $d;

    return @data;
}

# fair scheduler, take one from each customer first until
# we reach the limit
sub parse_jobs {
    my %args = @_;

    my $dir   = $args{'dir'};
    my $files = $args{'files'};
    my $max   = $args{'max'};

    my $hash;
    foreach my $f (@$files) {
        my $file = "$dir/$f";

        my $fh = new IO::File $file, "r" or die "open $file: $!\n";
        my $json_text;
        while (<$fh>) {
            $json_text .= $_;
        }
        $fh->close;

        my $json = new JSON;
        my $json_perl = eval { $json->decode($json_text) };
        die "json $file $@" if $@;

        $json_perl->{"file"} = $f;

        # a slot for every user
        push @{ $hash->{ $json_perl->{'email'} } }, $json_perl;
    }

    # sort by user and date, oldest first
    foreach my $email ( keys %$hash ) {
        $hash->{$email} =
          [ sort { $a->{"time"} <=> $b->{"time"} } @{ $hash->{$email} } ];
    }

    # fair scheduler, take one from each customer first
    my @list;
    my $counter = $max;
    while ( $counter-- > 0 ) {
        foreach my $email ( sort keys %$hash ) {
            if ( scalar( @{ $hash->{$email} } ) ) {
                my $obj = shift @{ $hash->{$email} };
                push @list, $obj;
            }
            last if scalar(@list) >= $max;
        }
        last if scalar(@list) >= $max;
    }

    return @list;
}

sub get_job_id {
    my @list = @_;

    my $json = new JSON;
    my $data = "";
    foreach my $key (@list) {
        $data .= $json->encode($key);
    }

    my $key = md5_hex($data);
    return $key;

}

sub file_latlng {
    my $obj  = shift;
    my $file = "";

    $file = "$obj->{sw_lat},$obj->{sw_lng}-$obj->{ne_lat},$obj->{ne_lng}";

    return $file;
}

sub create_poly_files {
    my %args    = @_;
    my $job_dir = $args{'job_dir'};
    my $list    = $args{'list'};

    my $spool = $args{'spool'};
    my $osm_dir = $spool->{'osm'};
    my $confirmed_dir = $spool->{'confirmed'};

    my @list = @$list;

    if ( -e $job_dir ) {
        warn "directory $job_dir already exists!\n";
        return;
    }

    warn "create job dir $job_dir\n" if $debug;
    mkdir($job_dir) or die "mkdir $job_dir $!\n";

    my %hash;
    foreach my $job (@list) {
        my $file = &file_latlng($job);

        if ( exists $hash{$file} ) {
            warn "ignore duplicate: $file\n" if $debug;
            next;
        }
        $hash{$file} = 1;

        if ( !$file ) {
            warn "Ignore job: ", Dumper($job), "\n";
            next;
        }

        my $poly_file = "$job_dir/$file.poly";
        my $pbf_file  = "$osm_dir/$file.pbf";

        if ( -e $pbf_file && -s $pbf_file ) {
            warn "File $pbf_file already exists, skiped\n";
            next;
        }

        &create_poly_file( 'file' => $poly_file, 'job' => $job );
	$job->{poly_file} = $poly_file;
	$job->{pbf_file} = $pbf_file;

    }
    foreach my $job (@list) {
	my $from = "$confirmed_dir/$job->{'file'}";
	my $to = "$job_dir/$job->{'file'}";

	warn "rename $from -> $to\n" if $debug >= 2;
	my $json = new JSON;
	my $data = $json->pretty->encode($job);

	store_data($to, $data);
	unlink($from) or die "unlink $from: $!\n";
    }
}

sub store_data {
  my ($file, $data) = @_;

  my $fh = new IO::File $file, "w" or die "open $file: $!\n";
  print $fh $data;
  $fh->close;
}


sub create_poly_file {
    my %args = @_;
    my $file = $args{'file'};
    my $obj  = $args{'job'};

    my $data = "";

    my $city = escapeHTML( $obj->{city} );
    $data .= "$city\n";
    $data .= "1\n";

    $data .= "   $obj->{sw_lng}  $obj->{sw_lat}\n";
    $data .= "   $obj->{ne_lng}  $obj->{sw_lat}\n";
    $data .= "   $obj->{ne_lng}  $obj->{ne_lat}\n";
    $data .= "   $obj->{sw_lng}  $obj->{ne_lat}\n";

    $data .= "END\n";
    $data .= "END\n";

    if ( -e $file ) {
        warn "poly file $file already exists!\n";
        return;
    }

    warn "Create poly file $file\n" if $debug >= 2;
    store_data($file, $data);
}

sub usage () {
    <<EOF;
usage: $0 [--debug={0..2}]
EOF
}

######################################################################
# main
#

GetOptions( "debug=i" => \$debug, ) or die usage;

my @files = get_jobs( $spool->{'confirmed'} );

if ( !scalar(@files) ) {
    print "Nothing to do\n" if $debug;
}
else {
    my @list = parse_jobs(
        'files' => \@files,
        'dir'   => $spool->{'confirmed'},
        'max'   => 8
    );
    print Dumper( \@list ) if $debug >= 3;

    my $key = get_job_id(@list);
    create_poly_files(
        'job_dir'       => $spool->{'running'} . "/$key",
        'list'          => \@list,
        'spool' => $spool,
    );
}

