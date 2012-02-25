#!/usr/local/bin/perl
# Copyright (c) 2011-2012 Wolfram Schneider, http://bbbike.org
#
# extract.pl - extracts areas in a batch job
#
# spool area
#   /incoming	- request to extract an area, email sent out to user
#   /confirmed	- user confirmed request by clicking on a link in the email
#   /running    - the request is running
#   /osm	- the request is done, files are saved for further usage
#   /download  	- where the user can download the files, email sent out
#  /jobN.pid	- running jobs
#
# todo:
# - xxx
#

use IO::File;
use IO::Dir;
use JSON;
use Data::Dumper;
use Encode qw/encode_utf8/;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use CGI qw(escapeHTML);
use Getopt::Long;
use File::Basename;
use File::stat;

use strict;
use warnings;

$ENV{'PATH'} = "/usr/local/bin:/bin:/usr/bin";
my $config_file = "$ENV{HOME}/.bbbike-extract";

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $planet_osm = "../osm-streetnames/download/planet-latest.osm.pbf";
my $debug      = 0;
my $test       = 0;

# spool directory. Should be at least 100GB large
my $spool_dir = '/usr/local/www/tmp/extract';

# max. area in square km
our $max_skm = 200_000;

# sent out emails as
our $email_from = 'bbbike@bbbike.org';

our $option = {
    'max_areas' => 12,
    'homepage'  => 'http://download.bbbike.org/osm/extract',
    'max_jobs'  => 3,

    # not used yet
    'max_extracts'   => 50,
    'min_wait_time'  => 5 * 60,    # in seconds
    'default_format' => 'pbf',

    'bcc' => $email_from,
};

my $formats = {
    'pbf'     => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
};

my $spool = {
    'incoming' =>
      "$spool_dir/incoming",    # incoming request, need to be confirmed
    'confirmed' => "$spool_dir/confirmed",    # ready to run
    'running'   => "$spool_dir/running",      # currently running job
    'osm'       => "$spool_dir/osm",          # cache older runs
    'download'  => "$spool_dir/download",     # final directory for download
    'trash' => "$spool_dir/trash",     # keep a copy of the config for debugging
    'job1'  => "$spool_dir/job1.pid",  # lock file for current job
};

# parse config file
if ( -e $config_file ) {
    require $config_file;
}

# up to N parallel jobs
foreach my $number ( 1 .. $option->{'max_jobs'} ) {
    $spool->{"job$number"} = "$spool_dir/job" . $number . ".pid";
}

# group writable file
umask(002);

my $nice_level = 10;

# test & debug
$planet_osm =
"/home/wosch/projects/osm-streetnames/download/geofabrik/europe/germany/brandenburg.osm.pbf"
  if $test;

######################################################################
#
#
sub get_jobs {
    my $dir = shift;

    my $d = IO::Dir->new($dir);
    if ( !defined $d ) {
        warn "error directory $dir: $!\n";
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
        binmode $fh, ":utf8";

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

    my $key = md5_hex( encode_utf8($data) );
    return $key;
}

# store lat,lng in filename
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

    my $spool         = $args{'spool'};
    my $osm_dir       = $spool->{'osm'};
    my $confirmed_dir = $spool->{'confirmed'};

    my @list = @$list;

    if ( -e $job_dir ) {
        warn "directory $job_dir already exists!\n";
        return;
    }

    warn "create job dir $job_dir\n" if $debug >= 1;
    mkdir($job_dir) or die "mkdir $job_dir $!\n";

    my %hash;
    my @poly;
    foreach my $job (@list) {
        my $file      = &file_latlng($job);
        my $poly_file = "$job_dir/$file.poly";
        my $pbf_file  = "$job_dir/$file.pbf";

        $job->{pbf_file} = $pbf_file;
        if ( exists $hash{$file} ) {
            warn "ignore duplicate: $file\n" if $debug;
            next;
        }
        $hash{$file} = 1;

        if ( !$file ) {
            warn "ignore job: ", Dumper($job), "\n";
            next;
        }

        if ( -e $pbf_file && -s $pbf_file ) {
            warn "file $pbf_file already exists, skiped\n";
            &touch_file($pbf_file);
            next;
        }

        &create_poly_file( 'file' => $poly_file, 'job' => $job );
        push @poly, $poly_file;

        $job->{poly_file} = $poly_file;
    }

    my @json;
    foreach my $job (@list) {
        my $from = "$confirmed_dir/$job->{'file'}";
        my $to   = "$job_dir/$job->{'file'}";

        warn "rename $from -> $to\n" if $debug >= 2;
        my $json = new JSON;
        my $data = $json->pretty->encode($job);

        store_data( $to, $data );
        unlink($from) or die "unlink $from: $!\n";
        push @json, $to;
    }

    if ($debug) {
        warn "number of poly files: ", scalar(@poly),
          ", number of json files: ", scalar(@json), "\n";
    }
    return ( \@poly, \@json );
}

# refresh mod time of file, to keep in cache
sub touch_file {
    my $file = shift;

    my @system = ( "touch", $file );

    system(@system) == 0
      or die "system @system failed: $?";

}

# store a blob of data in a file
sub store_data {
    my ( $file, $data ) = @_;

    my $fh = new IO::File $file, "w" or die "open $file: $!\n";
    binmode $fh, ":utf8";

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

    warn "create poly file $file\n" if $debug >= 2;
    store_data( $file, $data );
}

#
# extract area(s) from planet.osm with osmosis tool
#
sub run_extracts {
    my %args  = @_;
    my $spool = $args{'spool'};
    my $poly  = $args{'poly'};

    my $osm = $spool->{'osm'};

    warn Dumper($poly) if $debug >= 3;
    return () if !defined $poly || scalar(@$poly) <= 0;

    my @data = ( "nice", "-n", $nice_level, "osmosis", "-q" );
    push @data, qq{--read-pbf $planet_osm --buffer bufferCapacity=12000};

    my @pbf;
    my $tee = 0;
    foreach my $p (@$poly) {
        my $out = $p;
        $out =~ s/\.poly$/.pbf/;

        my $osm = $spool->{'osm'} . "/" . basename($out);
        if ( -e $osm ) {
            warn "File $osm already exists, skip\n" if $debug;

            link( $osm, $out ) or die "link $osm => $out: $!\n";
            next;
        }

        push @pbf, "--bp", "file=$p";
        push @pbf, "--write-pbf", "file=$out", "omitmetadata=true";
        $tee++;
    }

    if (@pbf) {
        push @data, "--tee", $tee;
        push @data, @pbf;
    }
    else {

        # nothing to do
        @data = "true";
    }

    warn join( " ", @data ), "\n" if $debug >= 2;
    return @data;
}

# compuate MD5 checksum for extract file
sub checksum {
    my $file = shift;
    die "file $file does not exists\n" if !-f $file;

    my $md5_command = 'md5sum';

    if ( my $pid = open( C, "-|" ) ) {
    }

    # child
    else {
        exec( $md5_command, $file ) or die "Alert! Cannot fork: $!\n";
    }

    my $data;
    while (<C>) {
        my @a = split;
        $data = shift @a;
        last;
    }
    close C;

    return $data;
}

# SMTP wrapper
sub _send_email {
    my ( $to, $subject, $text, $bcc ) = @_;
    my $mail_server = "localhost";
    my @to = split /,/, $to;

    my $from         = $email_from;
    my @bcc          = split /,/, $bcc;
    my $content_type = "Content-Type: text/plain; charset=UTF-8\n"
      . "Content-Transfer-Encoding: binary";

    my $data =
      "From: $from\nTo: $to\nSubject: $subject\n" . "$content_type\n\n$text";
    warn "send email to $to\nbcc: $bcc\n$subject\n" if $debug >= 1;
    warn "$text\n"                                  if $debug >= 2;

    my $smtp = new Net::SMTP( $mail_server, Hello => "localhost" )
      or die "can't make SMTP object";

    $smtp->mail($from) or die "can't send email from $from";
    $smtp->to(@to)     or die "can't use SMTP recipient '$to'";
    if ($bcc) {
        $smtp->bcc(@bcc) or die "can't use SMTP recipient '$bcc'";
    }
    $smtp->data($data) or die "can't email data to '$to'";
    $smtp->quit() or die "can't send email to '$to'";

    warn "\n$data\n" if $debug >= 3;
}

# prepare to sent mail about extracted area
sub send_email {
    my %args = @_;
    my $json = $args{'json'};

    # all scripts are in these directory
    my $dirname = dirname($0);

    my @unlink;
    foreach my $json_file (@$json) {
        my @system;

        my $json_text = read_data($json_file);
        my $json      = new JSON;
        my $obj       = $json->decode($json_text);

        warn "json: $json_file\n" if $debug >= 3;
        warn "json: $json_text\n" if $debug >= 3;

        my $pbf_file = $obj->{'pbf_file'};

        ###################################################################
        # converted file name
        my $file = $pbf_file;

        # convert .pbf to .osm if requested
        my @nice = ( "nice", "-n", $nice_level );
        if ( $obj->{'format'} eq 'osm.bz2' ) {
            $file =~ s/\.pbf$/.osm.bz2/;
            @system = ( @nice, "$dirname/pbf2osm", "--bzip2", $pbf_file );

            warn "@system\n" if $debug >= 2;
            system(@system) == 0 or die "system @system failed: $?";
        }
        elsif ( $obj->{'format'} eq 'osm.gz' ) {
            $file =~ s/\.pbf$/.osm.gz/;
            @system = ( @nice, "$dirname/pbf2osm", "--gzip", $pbf_file );

            warn "@system\n" if $debug >= 2;
            system(@system) == 0 or die "system @system failed: $?";
        }

        ###################################################################
        # keep a copy of .pbf in ./osm for further usage
        my $to = $spool->{'osm'} . "/" . basename($pbf_file);

        unlink($to);
        warn "link $pbf_file => $to\n" if $debug >= 2;
        link( $pbf_file, $to ) or die "link $pbf_file => $to: $!\n";

        my $file_size = file_size($to) . " MB";
        warn "file size $to: $file_size\n" if $debug >= 2;

        ###################################################################
        # copy for downloading in /download
        $to = $spool->{'download'} . "/" . basename($pbf_file);
        unlink($to);
        warn "link $pbf_file => $to\n" if $debug >= 1;
        link( $pbf_file, $to ) or die "link $pbf_file => $to: $!\n";

        push @unlink, $pbf_file;

        ###################################################################
        # .osm.gz or .osm.bzip2 files?
        if ( $file ne $pbf_file ) {
            $to = $spool->{'download'} . "/" . basename($file);
            unlink($to);

            link( $file, $to ) or die "link $pbf_file => $to: $!\n";

            $file_size = file_size($to) . " MB";
            warn "file size $to: $file_size\n" if $debug >= 2;
        }

        my $url = $option->{'homepage'} . "/" . basename($to);

        my $checksum = checksum($to);

        ###################################################################
        # mail

        my $message = <<EOF;
Hi,

your requested OpenStreetMap area "$obj->{'city'}" was extracted 
from planet.osm

 City: $obj->{"city"}
 Area: $obj->{"sw_lat"},$obj->{"sw_lng"} x $obj->{"ne_lat"},$obj->{"ne_lng"}
 Format: $obj->{"format"}
 Granularity: 10000 (1.1 meters)
 File size: $file_size
 MD5 checksum: $checksum
 License: OpenStreetMap License

To download the file, please click on the following link:

  $url

The file will be available for the next 48 hours. Please 
download the file as soon as possible.

Sincerely, your BBBike admin

--
http://BBBike.org - Your Cycle Route Planner
http://BBBike.org/community.html - We appreciate any feedback, suggestions and a donation! 
EOF

        eval {
            _send_email( $obj->{'email'},
                "Extracted area is ready for download: " . $obj->{'city'},
                $message, $option->{'bcc'} );
        };

        if ($@) {
            warn "$@";
            return 0;
        }

    }

    # unlink temporary .pbf files after all files are proceeds
    unlink(@unlink) or die "unlink: @unlink: $!\n";

    warn "number of email sent: ", scalar(@$json), "\n" if $debug >= 1;
}

# file size in x.y MB
sub file_size {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";

    return int( 10 * $st->size / 1024 / 1024 ) / 10;
}

# cat file
sub read_data {
    my ($file) = @_;

    my $fh = new IO::File $file, "r" or die "open $file: $!\n";
    binmode $fh, ":utf8";
    my $data;

    while (<$fh>) {
        $data .= $_;
    }
    $fh->close;

    return $data;
}

sub create_lock {
    my %args = @_;

    my $lockfile = $args{'lockfile'};

    if ( -e $lockfile ) {
        my $pid = read_data($lockfile);
        if ( kill( 0, $pid ) ) {
            warn "$pid is still running\n";
            return 0;
        }
        else {
            warn "$pid is no longer running\n";
            remove_lock( 'lockfile' => $lockfile );
        }
    }

    warn "create lockfile: $lockfile\n" if $debug >= 2;
    store_data( $lockfile, $$ );
    return 1;
}

sub remove_lock {
    my %args = @_;

    my $lockfile = $args{'lockfile'};

    warn "remove lockfile: $lockfile\n" if $debug >= 2;
    unlink($lockfile) or die "unlink $lockfile: $!\n";
}

sub cleanup_jobdir {
    my %args    = @_;
    my $job_dir = $args{'job_dir'};

    my $spool = $args{'spool'};
    my $json  = $args{'json'};

    # keep a copy of the config file for a request in trash can
    my $keep = $args{'keep'} || 0;

    my $trash_dir = $spool->{'trash'};
    if ($keep) {
        warn "Keep copy of json config files\n" if $debug >= 2;

        foreach my $file (@$json) {
            my $to = "$trash_dir/" . basename($file);
            unlink($to);
            warn "keep copy of json file: $to\n" if $debug >= 3;
            link( $file, $to ) or die "link $file => $to: $!\n";
        }
    }

    warn "remove job dir: $job_dir\n" if $debug >= 2;

    if ( -d $job_dir ) {
        my @system = ( 'rm', '-rf', $job_dir );
        system(@system) == 0
          or die "system @system failed: $?";
    }
}

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}		debug level
--nice-level={0..20}	nice level for osmosis
--job={1..4}		job number for parallels runs
EOF
}

######################################################################
# main
#

# current running parallel job number (1..4)
my $job = 1;

GetOptions(
    "debug=i"      => \$debug,
    "nice-level=i" => \$nice_level,
    "job=i"        => \$job,
) or die usage;

my @files = get_jobs( $spool->{'confirmed'} );

if ( !scalar(@files) ) {
    print "Nothing to do\n" if $debug >= 2;
}
else {
    my @list = parse_jobs(
        'files' => \@files,
        'dir'   => $spool->{'confirmed'},
        'max'   => $option->{'max_areas'},
    );
    print Dumper( \@list ) if $debug >= 3;

    my $key      = get_job_id(@list);
    my $job_dir  = $spool->{'running'} . "/$key";
    my $lockfile = $spool->{"job$job"};

    # lock pid
    &create_lock( 'lockfile' => $lockfile ) or die "Cannot get lock\n";

    my ( $poly, $json ) = create_poly_files(
        'job_dir' => $job_dir,
        'list'    => \@list,
        'spool'   => $spool,
    );

    my @system = run_extracts( 'spool' => $spool, 'poly' => $poly );

    my $time = time();
    warn "Run ", join " ", @system, "\n" if $debug > 2;
    system(@system) == 0
      or die "system @system failed: $?";

    warn "Running extract time: ", time() - $time, " seconds\n" if $debug;

    # send out mail
    $time = time();
    &send_email( 'json' => $json );
    warn "Running convert time: ", time() - $time, " seconds\n" if $debug;

    # unlock pid
    &remove_lock( 'lockfile' => $lockfile );

    &cleanup_jobdir(
        'job_dir' => $job_dir,
        'spool'   => $spool,
        'json'    => $json,
        'keep'    => 1
    );
}

1;
