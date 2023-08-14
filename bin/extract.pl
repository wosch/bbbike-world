#!/usr/local/bin/perl
# Copyright (c) 2011-2023 Wolfram Schneider, https://bbbike.org
#
# extract.pl - extracts areas in a batch job
#
# spool area
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
use Encode qw/encode_utf8 decode_utf8/;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;
use CGI qw(escapeHTML);
use URI;
use URI::QueryParam;
use Getopt::Long;
use File::Basename;
use File::stat;
use GIS::Distance::Lite;
use LWP;
use LWP::UserAgent;
use Time::gmtime;
use File::Temp;

use lib qw(world/lib ../lib);

use FindBin;
use lib ("$FindBin::RealBin/..");
use Extract::Config;
use Extract::Utils;
use Extract::Poly;
use Extract::Planet;
use Extract::LockFile;
use Extract::AWS;
use Extract::Scheduler;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

$ENV{'PATH'} = "/usr/local/bin:/bin:/usr/bin";
$ENV{'OSM_CHECKSUM'} = 'false';    # disable md5 checksum files

#$ENV{'BBBIKE_EXTRACT_LANG'} = 'en';       # default language

# group writable file
umask(002);

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

# backward compatible
$ENV{BBBIKE_PLANET_OSM_GRANULARITY} = "granularity=100"
  if !defined $ENV{BBBIKE_PLANET_OSM_GRANULARITY};

our $option = {

    # max. different polygon per extract
    'max_areas' => 1,

    # XXX?
    'homepage' => 'https://download.bbbike.org/osm/extract',

    'script_homepage'     => 'https://extract.bbbike.org',
    'script_homepage_pro' => 'https://extract-pro.bbbike.org',

    'server_status_url'     => 'https://download.bbbike.org/osm/extract',
    'server_status_url_pro' => 'https://download.bbbike.org/osm/extract',

    'max_jobs'   => 3,
    'bcc'        => 'bbbike@bbbike.org',
    'email_from' => 'bbbike@bbbike.org',
    'send_email' => 1,

    # do not run for N seconds if the file /tmp/extract-pause exists
    'pause_seconds' => 3600,
    'pause_file'    => '/tmp/extract-pause',

    # timeout handling
    'alarm'         => 210 * 60,    # extract
    'alarm_convert' => 90 * 60,     # convert

    # run with lower priority
    'nice_level' => 2,

    'planet' => $Extract::Config::planet_osm,

    'debug' => 0,
    'test'  => 0,

    # spool directory. Should be at least 100GB large
    'spool_dir'     => '/opt/bbbike/extract',
    'spool_dir_pro' => '/opt/bbbike/extract',

    'file_prefix' => 'planet_',

    # reset max_jobs if load is to high
    'max_loadavg'      => 9,
    'max_loadavg_jobs' => 3,    # 0: stop running at all
    'loadavg_status_program' => '/etc/munin/plugins/bbbike-extract-jobs',

    # 4196 polygones is enough for the queue
    'max_coords' => 4 * 1024,

    'language'     => "en",
    'message_path' => "world/etc/extract",

    'osmosis_options' => [ $ENV{BBBIKE_PLANET_OSM_GRANULARITY} ],

    'aws_s3_enabled' => 0,
    'aws_s3'         => {
        'bucket'      => 'bbbike',
        'path'        => 'osm/extract',
        'put_command' => 's3put',
        'homepage'    => 'https://s3.amazonaws.com',
    },

    # use web rest service for email sent out
    'email_rest_url'      => 'https://extract.bbbike.org/cgi/extract-email.cgi',
    'email_rest_enabled'  => 0,
    'email_failure_fatal' => 0,

    'show_image_size' => 1,

    'pbf2pbf_postprocess' => 1,
    'osmconvert_enabled'  => 1,
    'osmconvert_options'  => ["--drop-broken-refs"],

    'bots' => {
        'names'       => [qw/curl Wget Zend python-requests/],
        'detecation'  => 1,                                      # 0, 1
        'max_loadavg' => 3,                                      # 3 .. 6
             # 1: only one bot queue (soft blocking)
             # 2: ignore bots (hard blocking)
        'scheduler' => 1,
    },

    # see also cgi/extract.cgi
    'scheduler' => {
        'user_max_loadavg' => 8,
        'user_limit_jobs'  => 2
    },

    'pbf2osm' => {
        'garmin_version'      => 'mkgmap',
        'mbtiles_version'     => 'mbtiles',
        'maperitive_version'  => 'Maperitive',
        'osmand_version'      => 'OsmAndMapCreator',
        'mapsforge_version'   => 'mapsforge',
        'organicmaps_version' => 'organicmaps',
        'bbbike_version'      => 'bbbike',
        'shape_version'       => 'osmium2shape',
    },

    'nice_level_converter_format' => {
        'mapsforge' => 15,
        'obf'       => 12,
        'svg'       => 5,
        'xz'        => 4,
        'garmin'    => 16
    },

    'lwp' => {
        'timeout' => 5,
        'agent'   => 'BBBike Extract/1.0; https://extract.bbbike.org'
    }
};

######################################################################

my $extract = Extract::Config->new( 'option' => $option );
my $formats = $Extract::Config::formats;
my $spool   = $Extract::Config::spool;
$extract->load_config_nocgi;

# translations
my $msg;
my $language = $option->{'language'};

my $alarm      = $option->{"alarm"};
my $nice_level = $option->{"nice_level"};
my $email_from = $option->{"email_from"};
my $planet_osm = $option->{"planet_osm"} || $option->{"planet"}->{"planet.osm"};
my $debug      = $option->{"debug"};
my $test       = $option->{"test"};

if ( $option->{"pro"} ) {
    $option->{"osmosis_options"} = [];
}
my $osmosis_options = join( " ", @{ $option->{"osmosis_options"} } );

# test & debug
$planet_osm =
  "../osm/download/geofabrik/europe/germany/brandenburg-latest.osm.pbf"
  if $test;

my $utils = new Extract::Utils;

######################################################################
#

sub get_sub_planet {
    my $obj = shift;

    my $planet = new Extract::Planet( 'debug' => $debug );
    my $sub_planet_file = $planet->get_smallest_planet_file(
        'obj'        => $obj,
        'planet_osm' => $obj->{'planet_osm'}
    );

    warn "Found sub planet '$sub_planet_file' for city ",
      $obj->{'city'}, " lon,lat: $obj->{'sw_lng'},$obj->{'sw_lat'}",
      " $obj->{'ne_lng'},$obj->{'ne_lat'}\n"
      if $debug >= 1;

    $obj->{"planet_osm_sub"} = $sub_planet_file;

    return $sub_planet_file;
}

# fair scheduler, take one from each customer first until
# we reach the limit
sub parse_jobs {
    my %args = @_;

    my $dir        = $args{'dir'};
    my $files      = $args{'files'};
    my $max        = $args{'max'};
    my $job_number = $args{'job_number'};

    warn "job number is: $job_number\n" if $debug >= 1;

    #####################################
    # get a list of waiting jobs
    #
    my ( $hash, $default_planet_osm, $counter ) = parse_jobs_planet(%args);

    my $sub_planet_file = "";

    # sort by user and date, newest first
    foreach my $email ( keys %$hash ) {
        $hash->{$email} =
          [ reverse sort { $a->{"time"} <=> $b->{"time"} }
              @{ $hash->{$email} } ];
    }

    # fair scheduler, take one from each customer first
    my @list;
    my $counter_coords = 0;

    # 4196 polygones is enough for the queue
    my $max_coords = $option->{max_coords};

    my $loadavg = &get_loadavg;

    my %duplicated_poly = ();
    my $poly = new Extract::Poly( 'debug' => $debug );
    my $scheduler =
      new Extract::Scheduler( 'debug' => $debug, 'option' => $option );

    while ( $counter-- > 0 ) {

        # pick a random user
        foreach my $email ( &random_user( keys %$hash ) ) {
            my $waiting_jobs = scalar( @{ $hash->{$email} } );
            if ($waiting_jobs) {
                warn "User $email has $waiting_jobs jobs waiting\n"
                  if $debug >= 1;

                my $obj  = shift @{ $hash->{$email} };
                my $city = $obj->{'city'};

                my $length_coords = 4;
                if ( exists $obj->{"coords"}
                    && scalar( @{ $obj->{"coords"} } ) )
                {
                    $length_coords = scalar( @{ $obj->{"coords"} } );
                }

                # do not add a large polygone to an existing list
                if ( $length_coords > $max_coords && $counter_coords > 0 ) {
                    warn
                      "do not add a large polygone $city to an existing list\n"
                      if $debug >= 1;
                    next;
                }

                # rate limit for bots, based on load average
                if ( $scheduler->is_bot($obj) ) {
                    next
                      if $scheduler->ignore_bot(
                        'loadavg'    => $loadavg,
                        'job_number' => $job_number,
                        'obj'        => $obj,
                        'city'       => $city
                      );
                }

                # rate limit per user
                my $running_users = $scheduler->running_users;

                my $running_users_jobs = $running_users->{$email} || 0;
                my $total_jobs =
                  $scheduler->total_jobs( 'email' => $running_users );

                my $user_limit_jobs =
                  $option->{'scheduler'}->{'user_limit_jobs'};
                my $user_max_loadavg =
                  $option->{'scheduler'}->{'user_max_loadavg'};

                if ( $loadavg >= $user_max_loadavg ) {
                    warn
                      "Set number of running jobs from $user_limit_jobs to 1 ",
                      "due high load of $loadavg >= $user_max_loadavg\n"
                      if $debug >= 1;
                    $user_limit_jobs = 1;
                }

                warn "Running jobs for user $email: $running_users_jobs, ",
"max per user: $user_limit_jobs, number of running jobs: $total_jobs\n"
                  if $debug >= 1;

                if ( $running_users_jobs >= $user_limit_jobs ) {
                    warn
"Skip user $email due high number of running jobs: $running_users_jobs >= $user_limit_jobs\n"
                      if $debug >= 1;
                    next;
                }

                my $obj_sub_planet_file = get_sub_planet($obj);

                # first sub-planet wins
                if ( scalar(@list) == 0 && $obj_sub_planet_file ) {
                    $sub_planet_file    = $obj_sub_planet_file;
                    $default_planet_osm = $obj_sub_planet_file;
                }

                # ignore different sub-planets
                elsif ( $sub_planet_file ne $obj_sub_planet_file ) {
                    warn
                      "different sub-planet file detected: '$sub_planet_file'",
                      " <=> '$obj_sub_planet_file', ignored\n"
                      if $debug;
                    next;
                }

                push @list, $obj;
                $counter_coords += $length_coords;

                # extract the same area only once
                my ( $poly_data, $counter2 ) =
                  $poly->create_poly_data( 'job' => $obj );
                $duplicated_poly{ md5_hex( encode_utf8($poly_data) ) } += 1;

                warn
"coords total length: $counter_coords, city=$city, length=$length_coords\n"
                  if $debug >= 1;

                # stop here, list is to long
                if ( $counter_coords > $max_coords ) {
                    warn "coords counter length for $city: ",
                      "$counter_coords > $max_coords, stop after\n"
                      if $debug >= 1;
                    return ( \@list, $default_planet_osm );
                }
            }
            last if scalar( keys %duplicated_poly ) > $max;
        }
        last if scalar( keys %duplicated_poly ) > $max;
    }

    # off-by-one correction
    if ( scalar( keys %duplicated_poly ) > $max ) {
        pop @list;
    }

    warn
"number of different poly files detected: @{[ scalar( keys %duplicated_poly) ]}, max: $max\n"
      if $debug >= 1;
    return ( \@list, $default_planet_osm );
}

#
# select a planet.osm based on a given format
# then sort the request by email
#
#
# $obj -> { "foo@example.com" -> [ job1, job2, job3 ], "bar@example.com" => [ job1 ] }
# planet.osm.pbf
# counter=4
#
sub parse_jobs_planet {
    my %args = @_;

    my $dir   = $args{'dir'};
    my $files = $args{'files'};
    my $max   = $args{'max'};

    my $hash;
    my $default_planet_osm = "";
    my $counter            = 0;

    my $extract_utils = new Extract::Utils;
    my @files         = $extract_utils->random_filename_sort(@$files);

    #my $planet = new Extract::Planet( 'debug' => $debug );
    my $sub_planet_file = "";

    foreach my $f (@files) {
        my $file = "$dir/$f";

        my $json_text;
        if ( -z $file ) {
            warn "empty json job file: $file\n";
            rename( $file, "$file.zero" );
            next;
        }

        if ( -e $file ) {
            $json_text = read_data($file);
        }
        else {
            warn "Race condition: $file\n";
            next;
        }

        my $json = new JSON;
        my $json_perl = eval { $json->decode($json_text) };
        if ($@) {
            warn "cannot parse json $file $@";
            rename( $file, "$file.parse" );
            next;
        }
        json_compat($json_perl);

        $json_perl->{"file"} = $f;

        # planet.osm file per job
        my $format = $json_perl->{"format"};
        $json_perl->{'planet_osm'} =
          exists $option->{'planet'}->{$format}
          ? $option->{'planet'}->{$format}
          : $option->{'planet'}->{'planet.osm'};

        # first jobs defines the planet.osm file
        if ( !$default_planet_osm ) {
            $default_planet_osm = $json_perl->{'planet_osm'};
        }

        # only the same planet.osm file
        if ( $json_perl->{'planet_osm'} eq $default_planet_osm ) {

            #$json_perl->{"planet_osm_sub"} = $sub_planet_file;

            # a slot for every user
            push @{ $hash->{ $json_perl->{'email'} } }, $json_perl;
            $counter++;
        }
        else {
            warn
"Ignore job due different planet.osm file: $default_planet_osm <=> $json_perl->{'planet_osm'}\n"
              if $debug >= 1;
        }
    }

    return ( $hash, $default_planet_osm, $counter );
}

# create a unique job id for each extract request
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

#
# Create poly files based on a given list of json config files.
#
# On success, the json config files will be moved
# from the spool "confirmed" to "running"
#
sub create_poly_files {
    my %args    = @_;
    my $job_dir = $args{'job_dir'};
    my $list    = $args{'list'};

    my $spool         = $args{'spool'};
    my $confirmed_dir = $spool->{'confirmed'};

    my @list = @$list;

    if ( -e $job_dir ) {
        warn "directory $job_dir already exists!\n";
        return;
    }

    warn "create job dir $job_dir\n"             if $debug >= 1;
    warn "checked files: @{[ scalar(@list) ]}\n" if $debug >= 1;
    mkdir($job_dir) or die "mkdir $job_dir $!\n";

    my %hash;
    my @poly;
    foreach my $job (@list) {
        my $file      = &file_lnglat( $job, $option );
        my $poly_file = "$job_dir/$file.poly";
        my $pbf_file  = "$job_dir/$file.osm.pbf";

        $job->{pbf_file} = $pbf_file;
        if ( exists $hash{$file} ) {
            warn "ignore duplicate: $file\n" if $debug >= 1;
            next;
        }
        $hash{$file} = 1;

        if ( !$file ) {
            warn "ignore job: ", Dumper($job), "\n";
            next;
        }

        # multiple equal extract request in the same batch job
        if ( -e $pbf_file && -s $pbf_file ) {
            warn "file $pbf_file already exists, skiped\n";

            #&touch_file($pbf_file);
            next;
        }

        &create_poly_file( 'file' => $poly_file, 'job' => $job );
        push @poly, $poly_file;

        $job->{poly_file} = $poly_file;
    }

    my @json;
    my $wait_time = 0;
    foreach my $job (@list) {
        my $from = "$confirmed_dir/$job->{'file'}";
        my $to   = "$job_dir/$job->{'file'}";

        my $st = stat($from) or die "cannot stat $from\n";

        # always keep the latest wait time
        if ( $wait_time < $st->mtime ) {
            $wait_time = $st->mtime;
        }

        warn "rename $from -> $to\n" if $debug >= 1;
        my $json = new JSON;
        my $data = $json->pretty->encode($job);

        store_data( $to, $data );
        unlink($from) or die "unlink from=$from: $!\n";
        push @json, $to;

        if ( $debug >= 1 ) {
            warn "Running city: $job->{'city'}\n";
            warn "Script URL: @{[ script_url($option, $job) ]}\n";
        }
    }

    if ($debug) {
        warn "number of poly files: ", scalar(@poly),
          ", number of json files: ", scalar(@json), "\n";
    }

    return ( \@poly, \@json, ( time() - $wait_time ) );
}

# create a poly file which will be read by osmconvert to extract
# an area from planet.osm
sub create_poly_file {
    my %args = @_;

    my $poly = new Extract::Poly( 'debug' => 1 );
    my ( $data, $counter ) = $poly->create_poly_data(%args);

    my $file = $args{'file'};

    if ( -e $file ) {
        warn "poly file $file already exists!\n";
        return;
    }

    warn "create poly file $file with $counter elements\n" if $debug >= 2;
    store_data( $file, $data );
}

# extract area(s) from planet.osm with osmconvert tool
sub run_extracts {
    my %args       = @_;
    my $spool      = $args{'spool'};
    my $poly       = $args{'poly'};
    my $planet_osm = $args{'planet_osm'};

    my $use_tempfiles = 1;

    warn "Poly: " . Dumper($poly) if $debug >= 3;
    return () if !defined $poly || scalar(@$poly) <= 0;

    my @data = ( "nice", "-n", $nice_level, "osmconvert-wrapper" );

    my @pbf;
    my @fixme;
    my @tempfiles;

    foreach my $p ( shift @$poly ) {
        my $out = $p;
        $out =~ s/\.poly$/.osm.pbf/;

        my $osm = $spool->{'download'} . "/" . basename($out);
        if ( -e $osm ) {
            my $newer = $utils->file_mtime_diff( $osm, $planet_osm );
            if ( $newer > 0 ) {
                warn "File $osm already exists, skip\n" if $debug >= 1;
                symlink( $osm, $out ) or die "symllink $osm => $out: $!\n";
                next;
            }
            else {
                warn "file $osm already exists, ",
                  "but a new planet.osm is here since ", abs($newer),
                  " seconds. Rebuild.\n";
            }
        }

        if ($use_tempfiles) {
            my $tempfile = File::Temp->new( SUFFIX => ".osm.pbf" );

            symlink( $tempfile, $out )
              or die "cannot symlink $tempfile => $out\n";
            push @pbf, "-o", $tempfile;
            push @tempfiles, $tempfile;

        }
        else {
            push @pbf, "-o", $out;
        }

        push @pbf, "-B=$p";
    }

    if (@pbf) {
        push @data, @pbf;
    }
    else {

        # nothing to do
        @data = "true";
    }

    push @data, "--out-pbf";

    # drop broken refs?
    if ( ref $option->{'osmconvert_options'} eq 'ARRAY'
        && scalar( @{ $option->{'osmconvert_options'} } ) )
    {
        push @data, @{ $option->{'osmconvert_options'} };
    }

    if ( !$option->{"pro"} ) {
        push @data, ( "--drop-author", "--drop-version" );
    }

    push @data, $planet_osm;

    warn
"Use planet.osm file $planet_osm, size: @{[ file_size_mb($planet_osm) ]} MB\n"
      if $debug >= 1;
    warn "Run extracts: " . join( " ", @data ), "\n" if $debug >= 2;
    return ( \@data, \@fixme, \@tempfiles );
}

# SMTP wrapper
sub send_email_smtp {
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
    $smtp->data( encode_utf8($data) ) or die "can't email data to '$to'";
    $smtp->quit() or die "can't send email to '$to'";

    warn "\n$data\n" if $debug >= 3;
}

# email REST wrapper
sub send_email_rest {
    my ( $to, $subject, $message, $bcc ) = @_;

    my $ua      = LWP::UserAgent->new;
    my $timeout = $option->{'lwp'}->{'timeout'} // 5;
    my $agent   = $option->{'lwp'}->{'agent'};
    $ua->agent($agent) if defined $agent;
    $ua->timeout($timeout);

    my $url = $option->{"email_rest_url"};
    warn "Use REST email service: $url\n" if $debug >= 1;

    my %form = (
        'token'   => encode_utf8( $option->{"email_token"} ),
        'to'      => encode_utf8($to),
        'subject' => encode_utf8($subject),
        'message' => encode_utf8($message),
        'bcc'     => encode_utf8($bcc),
    );
    warn Dumper( \%form ) if $debug >= 3;

    my $res = $ua->post( $url, \%form );

    # Check the outcome of the response
    if ( !$res->is_success ) {
        my $err = "HTTP error: " . $res->status_line . "\n";
        $err .= $res->content . "\n" if $debug >= 1;
        die $err;
    }

    my $content = $res->content;
    my $json    = new JSON;
    my $obj     = $json->decode($content);

    warn "$content" if $debug >= 1;
    if ( $obj->{'status'} ) {
        die $obj->{'message'} . "\n";
    }
}

#
# run call back request
# Note: the callback function must be run async and response
# in less than 5 seconds - we don't wait until the file
# was downloaded from the remote service
#
sub run_callback {
    my ( $cb_id, $download_url ) = @_;

    my $ua      = LWP::UserAgent->new;
    my $timeout = $option->{'lwp'}->{'timeout'} // 5;
    my $agent   = $option->{'lwp'}->{'agent'};
    $ua->agent($agent) if defined $agent;
    $ua->timeout($timeout);

    #
    # every callback id is mapped to an URL as
    # 'customer1' => 'http://api.customer.com/cb?url='
    #
    my $callback_url = $option->{"cb_id"}->{$cb_id};
    if ( !defined $callback_url ) {
        die "callback id=$cb_id is not configured, give up";
    }
    elsif ( $callback_url !~ m,^https?://[a-z0-9\_\-\.]+\.[a-z]+/,i ) {
        die "callback id '$callback_url' does not look like an URL, give up";
    }

    my $url = $callback_url . $download_url;

    my $res = $ua->get($url);
    warn "run callback service: $url\n" if $debug >= 1;

    # Check the outcome of the response
    if ( !$res->is_success ) {
        my $err = "HTTP error: " . $res->status_line . "\n";
        $err .= $res->content . "\n" if $debug >= 1;
        die $err;
    }
}

# check if we need to run a pbf2osm converter
sub cached_format {
    my $file     = shift;
    my $pbf_file = shift;

    my $to = $spool->{'download'} . "/" . basename($file);
    if ( -e $file && -s $file ) {
        warn "File $file already exists, skip...\n" if $debug >= 1;
        return 1;
    }
    elsif ( -e $to && -s $to ) {

        # re-generate garmin if there is a newer PBF file
        if ( $pbf_file && -e $pbf_file ) {
            my $newer = $utils->file_mtime_diff( $to, $pbf_file );
            if ( $newer < 0 ) {
                warn "file $to already exists, ",
                  "but a new $pbf_file is here since ", abs($newer),
                  " seconds. Rebuild.\n"
                  if $debug >= 1;
                return 0;
            }
        }
        warn "Converted file $to already exists, skip...\n" if $debug >= 1;

        warn "symlink $file => $to\n" if $debug >= 2;
        symlink( $to, $file ) or die "symlink $to -> $file: $!\n";

        return 1;
    }

    return 0;
}

# reorder PBFs by size and compute time, smalles first
sub reorder_pbf {
    my $json      = shift;
    my $test_mode = shift;

    return @$json if $test_mode;

    my %hash;
    my %format = (
        'osm.pbf' => 0,
        'osm.gz'  => 1,
        'osm.bz2' => 1.2,
        'osm.xz'  => 2.5,

        'shp.zip'             => 1.3,
        'obf.zip'             => 10,
        'bbbike-perltk.zip'   => 1.2,
        'mapsforge-osm.zip'   => 15,
        'organicmaps-osm.zip' => 1.2,

        'garmin-osm.zip'             => 3,
        'garmin-osm-ascii.zip'       => 3,
        'garmin-osm-latin1.zip'      => 3,
        'garmin-cycle.zip'           => 3,
        'garmin-cycle-ascii.zip'     => 3,
        'garmin-cycle-latin1.zip'    => 3,
        'garmin-leisure.zip'         => 3.5,
        'garmin-leisure-ascii.zip'   => 3.5,
        'garmin-leisure-latin1.zip'  => 3.5,
        'garmin-bbbike.zip'          => 3,
        'garmin-bbbike-ascii.zip'    => 3,
        'garmin-bbbike-latin1.zip'   => 3,
        'garmin-onroad.zip'          => 1.5,
        'garmin-onroad-ascii.zip'    => 1.5,
        'garmin-onroad-latin1.zip'   => 1.5,
        'garmin-ontrail.zip'         => 1.7,
        'garmin-ontrail-ascii.zip'   => 1.7,
        'garmin-ontrail-latin1.zip'  => 1.7,
        'garmin-oseam.zip'           => 1.5,
        'garmin-oseam-ascii.zip'     => 1.5,
        'garmin-oseam-latin1.zip'    => 1.5,
        'garmin-opentopo.zip'        => 1.6,
        'garmin-opentopo-ascii.zip'  => 1.6,
        'garmin-opentopo-latin1.zip' => 1.6,

        'svg-google.zip'    => 5,
        'svg-hiking.zip'    => 5,
        'svg-osm.zip'       => 5,
        'svg-urbanight.zip' => 5,
        'svg-wireframe.zip' => 5,
        'svg-cadastre.zip'  => 5,

        'png-google.zip'    => 5,
        'png-hiking.zip'    => 5,
        'png-osm.zip'       => 5,
        'png-urbanight.zip' => 5,
        'png-wireframe.zip' => 5,
        'png-cadastre.zip'  => 5,

        'o5m.gz'  => 1.1,
        'o5m.xz'  => 0.9,
        'o5m.bz2' => 1.2,

        'opl.xz'        => 1.3,
        'geojson.xz'    => 1.31,
        'geojsonseq.xz' => 1.32,
        'text.xz'       => 1.33,
        'sqlite.xz'     => 1.34,

        'mbtiles-basic.zip'        => 10,
        'mbtiles-openmaptiles.zip' => 10,

        'csv.gz'  => 0.42,
        'csv.xz'  => 0.2,
        'csv.bz2' => 0.45,

        'srtm-europe.osm.pbf'           => 1,
        'srtm-europe.garmin-srtm.zip'   => 1.5,
        'srtm-europe.obf.zip'           => 10,
        'srtm-europe.mapsforge-osm.zip' => 2,

        'srtm.osm.pbf'           => 1,
        'srtm.garmin-srtm.zip'   => 1.5,
        'srtm.obf.zip'           => 10,
        'srtm.mapsforge-osm.zip' => 2,
    );

    foreach my $json_file (@$json) {

        my $json_text = read_data($json_file);
        my $json      = new JSON;
        my $obj       = $json->decode($json_text);
        json_compat($obj);

        my $pbf_file = $obj->{'pbf_file'};
        my $format   = $obj->{'format'};

        my $st = stat($pbf_file) or die "stat $pbf_file: $!\n";
        my $size = $st->size * $format{$format};

        $hash{$json_file} = $size;
    }

    my @json = sort { $hash{$a} <=> $hash{$b} } keys %hash;
    if ( $debug >= 2 ) {
        warn "Number of json files: " . scalar(@$json) . "\n";
        warn join "\n", ( map { "$_ $hash{$_}" } @$json ), "";
    }

    return @json;
}

sub copy_to_trash {
    my $file = shift;

    my $trash_dir = $spool->{'trash'};

    my $to = "$trash_dir/" . basename($file);

    unlink($to);
    warn "keep copy of json file: $to\n" if $debug >= 3;
    link( $file, $to ) or die "link $file => $to: $!\n";
}

# move file from one partion to another
sub move {
    my ( $from, $to ) = @_;

    my $tempfile = File::Temp->new( "template" => "$to.XXXXXXXXXX" );
    my $real_from = -l $from ? readlink($from) : $from;

    warn "from=$from real_from to=$to\n" if $debug >= 1;

    my @system = ( "/bin/mv", "-f", $real_from, $tempfile );
    system(@system) == 0
      or die "system failed @{[ join(' ', @system) ]}: $!\n";

    rename( $tempfile, $to ) or die "rename $tempfile => $to: $!\n";

    unlink($from);
    symlink( $to, $from ) or die "symlink $to -> $from: $!\n";
}

#
# check if we override a fresh file
# this is a harmless race condition (waste of CPU time)
#
sub check_download_cache {
    my $file = shift;
    my $time = shift;    # time when the script started

    return 0 if !-e $file;
    my $st = stat($file) or return 0;

    my $expire = 30 * 60;    # N minutes

    my $diff_time = $time - $st->mtime;
    if ( $diff_time > $expire ) {
        warn "Oops, override a cache file which is "
          . "$diff_time seconds old (limit $expire): $file\n"
          if $debug >= 1;
        return 1;
    }

    return 0;
}

# prepare to sent mail about extracted area
sub convert_send_email {
    my %args             = @_;
    my $json             = $args{'json'};
    my $send_email       = $args{'send_email'};
    my $keep             = $args{'keep'};
    my $alarm            = $args{'alarm'};
    my $test_mode        = $args{'test_mode'};
    my $planet_osm       = $args{'planet_osm'};
    my $planet_osm_mtime = $args{'planet_osm_mtime'};
    my $extract_time     = $args{'extract_time'};
    my $wait_time        = $args{'wait_time'};
    my $start_time       = $args{'start_time'};

    # all scripts are in these directory
    my $dirname = dirname($0);

    my @unlink;
    my @json = reorder_pbf( $json, $test_mode );

    my $job_counter   = 0;
    my $error_counter = 0;
    foreach my $json_file (@json) {
        my $time = time();

        eval {
            _convert_send_email(
                'json_file'        => $json_file,
                'send_email'       => $send_email,
                'test_mode'        => $test_mode,
                'planet_osm'       => $planet_osm,
                'planet_osm_mtime' => $planet_osm_mtime,
                'extract_time'     => $extract_time,
                'wait_time'        => $wait_time,
                'start_time'       => $start_time,
                'alarm'            => $alarm
            );
        };

        if ($@) {
            warn "$@";
            $error_counter++;
        }
        else {
            my $obj      = get_json($json_file);
            my $pbf_file = $obj->{'pbf_file'};
            push @unlink, $pbf_file;

            $job_counter++;
            copy_to_trash($json_file) if $keep;

            # unlink json file if done right now
            unlink($json_file) or die "unlink json_file=$json_file: $!\n";
        }

        warn "Running convert and email time: ", time() - $time, " seconds\n"
          if $#json > 0 && $debug;
    }

    # unlink temporary .pbf files after all files are proceeds
    foreach my $file (@unlink) {
        if ( -e $file ) {
            unlink($file) or die "unlink pbf file=$file: $!\n";
        }
    }

    warn "number of email/callback sent: $job_counter\n"
      if $send_email && $debug >= 1;

    return $error_counter;
}

# mkgmap.jar description limit of 50 bytes
sub mkgmap_description {
    my $city = shift;
    $city = "" if !defined $city;
    my $octets = encode_utf8($city);

    # count bytes, not characters
    if ( length($octets) > 50 ) {
        my $data = substr( $octets, 0, 50 );
        $city = decode_utf8( $data, Encode::FB_QUIET );
    }

    return $city;
}

# XXX: see ../lib/Extract/CGI.pm
# call back URL
sub script_url {
    my $option = shift;
    my $obj    = shift;

    my $coords = "";
    if ( scalar( @{ $obj->{'coords'} } ) > 100 ) {
        $coords = "0,0,0";
        warn "Coordinates to long for URL, skipped\n" if $debug >= 2;
    }
    else {
        $coords = join '|', ( map { "$_->[0],$_->[1]" } @{ $obj->{'coords'} } );
    }
    my $layers = $obj->{'layers'} || "";
    my $city   = $obj->{'city'}   || "";
    my $lang   = $obj->{'lang'}   || "";
    my $ref    = $obj->{'ref'}    || "";

    my $script_url =
        $option->{'pro'}
      ? $option->{"script_homepage_pro"}
      : $option->{"script_homepage"};

    my $uri = URI->new($script_url);
    $uri->query_form(
        "sw_lng" => $obj->{"sw_lng"},
        "sw_lat" => $obj->{"sw_lat"},
        "ne_lng" => $obj->{"ne_lng"},
        "ne_lat" => $obj->{"ne_lat"},
        "format" => $obj->{"format"}
    );

    $uri->query_param( "coords", $coords ) if $coords ne "";
    $uri->query_param( "layers", $layers ) if $layers && $layers !~ /^B/;
    $uri->query_param( "city",   $city )   if $city ne "";
    $uri->query_param( "coords", $coords ) if $coords ne "";
    $uri->query_param( "ref",    $ref )    if $ref ne "";
    $uri->query_param( "lang",   $lang )   if $lang ne "";

    return $uri->as_string;
}

sub get_nice_level_converter {
    my %args = @_;

    my $format     = $args{'format'};
    my $nice_level = $args{'nice_level'};

    # run converter as mapsforge with lower priority
    my $nice_level_converter = 0;

    if ( exists $option->{"nice_level_converter_format"}{$format} ) {
        $nice_level_converter =
          $option->{"nice_level_converter_format"}{$format};
    }

    # garmin catch all
    elsif ( $format =~ /garmin-/
        && exists $option->{"nice_level_converter_format"}{"garmin"} )
    {
        $nice_level_converter =
          $option->{"nice_level_converter_format"}{"garmin"};
    }

    # mapsforge catch all
    elsif ( $format =~ /mapsforge-/
        && exists $option->{"nice_level_converter_format"}{"mapsforge"} )
    {
        $nice_level_converter =
          $option->{"nice_level_converter_format"}{"mapsforge"};
    }

    # osmand catch all
    elsif ( $format =~ /obf/
        && exists $option->{"nice_level_converter_format"}{"obf"} )
    {
        $nice_level_converter = $option->{"nice_level_converter_format"}{"obf"};
    }

    # xz catch all
    elsif ( $format =~ /\.xz$/
        && exists $option->{"nice_level_converter_format"}{"xz"} )
    {
        $nice_level_converter = $option->{"nice_level_converter_format"}{"xz"};
    }

    elsif ( exists $option->{"nice_level_converter"} ) {
        $nice_level_converter = $option->{"nice_level_converter"};
    }
    else {
        $nice_level_converter = $nice_level + 3;
    }

    return $nice_level_converter;
}

sub _convert_send_email {
    my %args             = @_;
    my $json_file        = $args{'json_file'};
    my $send_email       = $args{'send_email'};
    my $alarm            = $args{'alarm'};
    my $test_mode        = $args{'test_mode'};
    my $planet_osm       = $args{'planet_osm'};
    my $extract_time     = $args{'extract_time'};
    my $wait_time        = $args{'wait_time'};
    my $start_time       = $args{'start_time'};
    my $planet_osm_mtime = $args{'planet_osm_mtime'};

    my $obj2 = get_json($json_file);
    &set_alarm( $alarm, $obj2->{'pbf_file'} . " " . $obj2->{'format'} );

    # all scripts are in these directory
    my $dirname = dirname($0);

    my @unlink;

    my $obj       = get_json($json_file);
    my $format    = $obj->{'format'};
    my $pbf_file  = $obj->{'pbf_file'};
    my $poly_file = $obj->{'poly_file'};
    my $city      = mkgmap_description( $obj->{'city'} );
    my $lang      = $obj->{'lang'} || "en";
    my @system;

    # parameters for osm2XXX shell scripts
    $ENV{BBBIKE_EXTRACT_URL} = &script_url( $option, $obj );
    $ENV{BBBIKE_EXTRACT_COORDS} =
      qq[$obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}];
    $ENV{'BBBIKE_EXTRACT_LANG'} = $lang;

    $ENV{'BBBIKE_EXTRACT_GARMIN_VERSION'} =
      $option->{pbf2osm}->{garmin_version};
    $ENV{'BBBIKE_EXTRACT_MBTILES_VERSION'} =
      $option->{pbf2osm}->{mbtiles_version};
    $ENV{'BBBIKE_EXTRACT_MAPERITIVE_VERSION'} =
      $option->{pbf2osm}->{maperitive_version};
    $ENV{'BBBIKE_EXTRACT_OSMAND_VERSION'} =
      $option->{pbf2osm}->{osmand_version};
    $ENV{'BBBIKE_EXTRACT_MAPSFORGE_VERSION'} =
      $option->{pbf2osm}->{mapsforge_version};
    $ENV{'BBBIKE_EXTRACT_BBBIKE_VERSION'} =
      $option->{pbf2osm}->{bbbike_version};
    $ENV{'BBBIKE_EXTRACT_SHAPE_VERSION'} = $option->{pbf2osm}->{shape_version};
    $ENV{'BBBIKE_EXTRACT_ORGANICMAPS_VERSION'} =
      $option->{pbf2osm}->{organicmaps_version};

    ###################################################################
    # converted file name
    my $file = $pbf_file;
    warn "pbf file size $pbf_file: @{[ file_size_mb($pbf_file) ]} MB\n"
      if $debug >= 1;
    $obj->{"pbf_file_size"} = file_size($pbf_file);

    # run converter as mapsforge with lower priority
    my $nice_level_converter = get_nice_level_converter(
        'format'     => $format,
        'nice_level' => $nice_level
    );

    # convert .pbf to .osm if requested
    my @nice = ( "nice", "-n", $nice_level_converter );
    my $time = time();

# OSM XML extracts
# Note: we skip double ".osm.osm.pbf" in file names, and use a single ".osm.pbf"
    if ( $format =~ /^(srtm\.|srtm-europe\.)?osm\.(xz|gz|bz2)$/ ) {
        my $ext = $2;
        $file =~ s/\.pbf$/.$ext/;
        if ( !cached_format( $file, $pbf_file ) ) {
            @system = ( @nice, "$dirname/pbf2osm", "--$ext", $pbf_file );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # OSM extracts as csv, text, json etc.
    elsif ( $format =~
        /^(o5m|opl|csv|geojsonseq|geojson|text|sqlite)\.(xz|gz|bz2)$/ )
    {
        my $type = $1;
        my $ext  = $2;
        $file =~ s/\.pbf$/.$type.$ext/;
        if ( !cached_format( $file, $pbf_file ) ) {
            @system = ( @nice, "$dirname/pbf2osm", "--$type-$ext", $pbf_file );
            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # Garmin
    elsif ( $format =~ /garmin-([a-z0-9\-]+)\.zip$/
        && exists $formats->{$format} )
    {
        my $style      = $1;
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.garmin/garmin/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system = ( @nice, "$dirname/pbf2osm", "--garmin-$style", $pbf_file,
                $city );
            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # MBTiles
    elsif ( $format =~ /mbtiles-([a-z0-9\-]+)\.zip$/
        && exists $formats->{$format} )
    {
        my $style      = $1;
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.mbtiles/mbtiles/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system = (
                @nice, "$dirname/pbf2osm", "--mbtiles-$style", $pbf_file, $city
            );
            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # SVG / PNG
    elsif ( $format =~
        /^(svg|png)-(google|hiking|osm|urbanight|wireframe|cadastre).zip$/ )
    {
        my $type       = $1;
        my $style      = $2;
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.$type/$type/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system =
              ( @nice, "$dirname/pbf2osm", "--$type-$style", $pbf_file, $city );
            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # Shapefiles
    elsif ( $format eq 'shp.zip' ) {
        $file =~ s/\.pbf$/.$format/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system =
              ( @nice, "$dirname/pbf2osm", "--shape", $pbf_file, $city );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # Osmand
    elsif ( $format eq 'obf.zip' || $format =~ /^[a-z\-]+\.obf.zip$/ ) {
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.obf/obf/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system =
              ( @nice, "$dirname/pbf2osm", "--osmand", $pbf_file, $city );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # BBBike perl/tk program
    elsif ( $format eq 'bbbike-perltk.zip' ) {
        $file =~ s/\.pbf$/.$format/;
        $file =~ s/.zip$/.$lang.zip/ if $lang =~ /^(de)$/;

        if ( !cached_format( $file, $pbf_file ) ) {
            @system =
              ( @nice, "$dirname/pbf2osm", "--bbbike-perltk", $pbf_file,
                $city );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # Mapsforge
    elsif ($format =~ /^mapsforge-(osm)\.zip$/
        || $format =~ /^[a-z\-]+\.mapsforge-(osm)\.zip$/ )
    {
        my $style      = $1;
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.mapsforge/mapsforge/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system = (
                @nice, "$dirname/pbf2osm", "--mapsforge-$style", $pbf_file,
                $city
            );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # organicmaps mobile app
    elsif ($format =~ /^organicmaps-(osm)\.zip$/
        || $format =~ /^[a-z\-]+\.organicmaps-(osm)\.zip$/ )
    {
        my $style      = $1;
        my $format_ext = $format;
        $format_ext =~ s/^[a-z\-]+\.organicmaps/organicmaps/;

        $file =~ s/\.pbf$/.$format_ext/;
        $file =~ s/.zip$/.$lang.zip/ if $lang ne "en";

        if ( !cached_format( $file, $pbf_file ) ) {
            @system = (
                @nice, "$dirname/pbf2osm", "--organicmaps-$style", $pbf_file,
                $city
            );

            warn "@system\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0 or die "system @system failed: $?";
        }
    }

    # cleanup poly file after successfull convert
    if ( -f $poly_file ) {
        push @unlink, $poly_file;
    }
    else {
        warn
"Poly file no longer exists, maybe already removed for the same area: $poly_file\n"
          if $debug >= 2;
    }

    next if $test_mode;

    my $convert_time = time() - $time;
    $obj->{"convert_time"} = $convert_time;
    $obj->{"extract_time"} = $extract_time;
    $obj->{"wait_time"}    = $wait_time;
    $obj->{"load_average"} = &get_loadavg;

    ###################################################################
    # copy for downloading in /download
    my $to = $spool->{'download'} . "/" . basename($pbf_file);

    &check_download_cache( $to, $start_time );
    warn "move $pbf_file => $to\n" if $debug >= 2;
    &move( $pbf_file, $to );

    my $aws = Extract::AWS->new( 'option' => $option, 'debug' => $debug );
    $aws->aws_s3_put( 'file' => $to );

    my $file_size = file_size_mb($to) . " MB";
    warn "generated file size $to: $file_size\n" if $debug >= 1;

    ###################################################################
    # .osm.gz or .osm.bzip2 files?
    if ( $file ne $pbf_file ) {
        $to = $spool->{'download'} . "/" . basename($file);
        &check_download_cache( $to, $start_time );

        $aws->aws_s3_put( 'file' => $file );
        move( $file, $to );

        $file_size = file_size_mb($to) . " MB";
        warn "file size $to: $file_size\n" if $debug >= 1;
    }

    my $server_status =
        $option->{'pro'}
      ? $option->{"server_status_url_pro"}
      : $option->{"server_status_url"};

    my $url = $server_status . "/" . basename($to);
    if ( $option->{"aws_s3_enabled"} ) {
        $url = $option->{"aws_s3"}->{"homepage"} . "/" . $aws->aws_s3_path($to);
    }

    my $checksum_md5 = checksum( $to, "md5" );
    $obj->{"checksum_md5"} = $checksum_md5;

    # unlink temporary .pbf files after all files are proceeds
    if (@unlink) {
        warn "Unlink temp files: " . join( "", @unlink ) . "\n"
          if $debug >= 2;
        unlink(@unlink) or die "unlink temp files: @unlink: $!\n";
    }

    $msg = get_msg( $obj->{"lang"} || "en" );

    # record the file size of the format
    $obj->{"format_size"} = file_size($to);

    ###################################################################
    # display uncompressed image file size
    if ( $option->{show_image_size} && $to =~ /\.zip$/ ) {
        $file_size .= " " . M("zip archive") . ", ";

        my $prog = dirname($0) . "/extract-disk-usage.sh";
        open my $fh, "$prog $to |" or die open "open $prog $to";

        my $du = -1;
        while (<$fh>) {
            chomp;
            $du = $_;
        }

        $file_size .= kb_to_mb( $du * 1024 ) . " MB " . M("uncompressed");
        warn "image file size $to: $file_size\n" if $debug >= 1;

        $obj->{"image_size_du"} = $du * 1024;
    }

    ###################################################################
    # mail

    my $square_km = large_int(
        square_km(
            $obj->{"sw_lat"}, $obj->{"sw_lng"},
            $obj->{"ne_lat"}, $obj->{"ne_lng"}
        ),
        $obj->{'lang'}
    );

    next if !$send_email;

    my $script_url = &script_url( $option, $obj );
    my $database_update = gmctime($planet_osm_mtime) . " UTC";

    my $text = M("EXTRACT_EMAIL");
    my $granularity;
    if ( grep { /^granularity=10000$/ } @{ $option->{"osmosis_options"} } ) {
        $granularity = "10,000 (1.1 meters)";
    }
    elsif ( grep { /^granularity=1000$/ } @{ $option->{"osmosis_options"} } ) {
        $granularity = "1,000 (11 cm)";
    }
    elsif ( grep { /^granularity=100$/ } @{ $option->{"osmosis_options"} } ) {
        $granularity = "100 (1.1 cm)";
    }
    else {
        $granularity = "full";
    }

    # here we can put any optional messages, at once
    my $optional_message = "";

    if ( $obj->{"route"} ne "" && $obj->{"appid"} eq "gpsies1" ) {
        $optional_message =
            " Route: "
          . "https://www.gpsies.com/map.do?fileId="
          . $obj->{"route"};
    }

    my $message = sprintf(
        $text,
        $obj->{'city'},
        $url,
        $obj->{'city'},
qq[$obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}],
        $script_url,
        $square_km,
        $granularity,    #$osmosis_options,
        $obj->{"format"},
        $file_size,
        $checksum_md5,
        $database_update,
        $optional_message
    );

#        my $message = <<EOF;
#Hi,
#
#your requested OpenStreetMap area "$obj->{'city'}" was extracted from planet.osm
#To download the file, please click on the following link:
#
#  $url
#
#The file will be available for the next 48 hours. Please download the
#file as soon as possible.
#
# Name: $obj->{"city"}
# Coordinates: $obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}
# Script URL: $script_url
# Square kilometre: $square_km
# Granularity: 10,000 (1.1 meters)
# Format: $obj->{"format"}
# File size: $file_size
# MD5 checksum: $checksum
# Last planet.osm database update: $database_update
# License: OpenStreetMap License
#
#We appreciate any feedback, suggestions and a donation!
#You can support us via PayPal or bank wire transfer.
#https://www.BBBike.org/community.html
#
#Sincerely, the BBBike extract Fairy
#
#--
#https://www.BBBike.org - Your Cycle Route Planner
#EOF

    my $subject =
        "BBBike extract: area '"
      . $obj->{'city'}
      . "', format="
      . $obj->{'format'}
      . " is ready for download";
    my @args = ( $obj->{'email'}, $subject, $message, $option->{'bcc'} );

    my $email_rest_enabled = $option->{"email_rest_enabled"};
    my $callback_enabled   = $option->{"callback_enabled"};

    warn "email_rest_enabled: $email_rest_enabled\n" if $debug >= 2;
    warn "callback_enabled: $callback_enabled\n"     if $debug >= 2;

    # use the email rest service only for domains which match a configured list
    # e.g. outlook.com
    if ( $email_rest_enabled && exists $option->{"email_rest_domain_only"} ) {
        my $domain_only = $option->{"email_rest_domain_only"};
        if ( ref $domain_only eq 'ARRAY' && scalar(@$domain_only) > 0 ) {

            my @res = &check_domain_only( $obj->{'email'}, $domain_only );

            if (@res) {
                warn "email_rest_domain_only matched: $obj->{'email'}: ",
                  join( ',', @res ), "\n"
                  if $debug >= 1;
            }
            else {
                warn "email_rest disabled by domain: $obj->{'email'}: ",
                  join( ',', @res ), "\n"
                  if $debug >= 1;
                $email_rest_enabled = 0;
            }
        }
    }

    # callback URL
    if ( $callback_enabled && $obj->{'cb_id'} ) {
        eval { run_callback( $obj->{'cb_id'}, $url ) };
        if ($@) {
            $option->{'email_failure_fatal'} ? die "$@" : warn "$@";
        }
    }

    # email via REST service
    elsif ($email_rest_enabled) {
        eval { send_email_rest(@args); };
        if ($@) {
            $option->{'email_failure_fatal'} ? die "$@" : warn "$@";
        }
    }

    # sent email locally with smtp
    else {
        eval { send_email_smtp(@args); };
        if ($@) {
            $option->{'email_failure_fatal'} ? die "$@" : warn "$@";
        }
    }

    $obj->{'download_url'} = $url;
    store_json( $json_file, $obj );
}

# check if an email address match a keyword
sub check_domain_only {
    my $to          = shift;
    my $domain_only = shift;

    # domains only
    $to =~ s/.*?\@//;

    return if !defined $domain_only || ref $domain_only ne 'ARRAY';
    my @domain_only = @$domain_only;

    return if scalar(@domain_only) <= 0;

    my @list;
    foreach my $k (@domain_only) {
        push @list, $k if $to =~ /$k/;
    }

    return @list;
}

#
# pbf2pbf postprocess
# e.g. make sure that lat,lon are in valid range -180 .. +180
#
sub fix_pbf {
    my $files     = shift;
    my $test_mode = shift;

    # all scripts are in these directory
    my $dirname = dirname($0);
    my $pbf2pbf = "$dirname/pbf2pbf";

    my @nice = ( "nice", "-n", $nice_level + 1 );
    my @system;
    if ( $option->{"pbf2pbf_postprocess"} ) {
        warn "Run pbf2pbf post process\n" if $debug >= 1;

        foreach my $pbf (@$files) {
            @system = ( @nice, $pbf2pbf, $pbf );
            warn "Fix pbf $pbf\n" if $debug >= 2;
            @system = 'true' if $test_mode;

            system(@system) == 0
              or die "system @system failed: $?";
        }
    }
}

sub get_msg {
    my $language = shift || $option->{'language'};

    my $file = $option->{'message_path'} . "/msg.$language.json";
    if ( !-e $file ) {
        warn "Language file $file not found, ignored\n" . qx(pwd);
        return {};
    }

    warn "Open message file $file for language $language\n" if $debug >= 1;
    my $json_text = read_data($file);

    my $json = new JSON;
    my $json_perl = eval { $json->decode($json_text) };
    die "json $file $@" if $@;

    warn Dumper($json_perl) if $debug >= 3;
    return $json_perl;
}

sub M {
    my $key = shift;

    my $text;
    if ( $msg && exists $msg->{$key} ) {
        $text = $msg->{$key};

        #} elsif ($msg_en && exists $msg_en->{$key}) {
        #    warn "Unknown translation local lang $lang: $key\n";
        #    $text = $msg_en->{$key};
    }
    else {
        if ( $debug >= 1 && $msg ) {
            warn "Unknown translation: $key\n"
              if $debug >= 2 || $language ne "en";
        }
        $text = $key;
    }

    if ( ref $text eq 'ARRAY' ) {
        $text = join "\n", @$text, "\n";
    }

    return $text;
}

sub cleanup_jobdir {
    my %args    = @_;
    my $job_dir = $args{'job_dir'};

    my $spool  = $args{'spool'};
    my $json   = $args{'json'};
    my $errors = $args{'errors'};

    # keep a copy of failed request in trash can
    my $keep = $args{'keep'} || 0;

    my $failed_dir = $spool->{'failed'};
    warn "Cleanup job dir: $job_dir\n" if $debug >= 2;

    my @system;
    if ( !-d $job_dir ) {
        warn "Oops, $job_dir not found\n";
        return;
    }

    system( 'ls', '-la', $job_dir ) if $debug >= 3;

    if ( $errors && $keep ) {
        my $to_dir = "$failed_dir/" . basename($job_dir);
        warn "Keep job dir: $to_dir\n" if $debug >= 1;

        @system = ( 'rm', '-rf', $to_dir );
        system(@system) == 0
          or die "system @system failed: $?";
        @system = ( 'mv', '-f', $job_dir, $failed_dir );
        system(@system) == 0
          or die "system @system failed: $?";

    }
    else {
        @system = ( 'rm', '-rf', $job_dir );
        system(@system) == 0
          or die "system @system failed: $?";
    }
}

sub set_alarm {
    my $time = shift;
    my $message = shift || "";

    $time = $alarm if !defined $time;

    $SIG{ALRM} = sub {
        my $pgid = getpgrp();

        warn "Time out alarm $time\n";

        # sends a hang-up signal to all processes in the current process group
        # and kill running java processes
        local $SIG{HUP} = "IGNORE";
        kill "HUP", -$pgid;
        sleep 0.5;

        local $SIG{TERM} = "IGNORE";
        kill "TERM", -$pgid;
        sleep 0.5;

        local $SIG{INT} = "IGNORE";
        kill "INT", -$pgid;
        sleep 0.5;

        warn "Send a hang-up to all childs.\n";

        #exit 1;
    };

    warn "set alarm time to: $time seconds $message\n" if $debug >= 1;
    alarm($time);
}

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}		debug level, default: $debug
--nice-level={0..20}	nice level for osmconvert, default: $option->{nice_level}
--job={1..4}		job number for parallels runs, default: $option->{max_jobs}
--timeout=1..86400	time out, default $option->{"alarm"}
--send-email={0,1}	send out email, default: $option->{"send_email"}
--planet-osm=/path/to/planet.osm.pbf  default: $option->{"planet"}->{"planet.osm"}
--spool-dir=/path/to/spool 	      default: $option->{spool_dir}
--test-mode		do not execude commands

pause file: $option->{"pause_file"} for $option->{"pause_seconds"} seconds
EOF
}

sub run_jobs {
    my %args       = @_;
    my $max_jobs   = $args{'max_jobs'};
    my $send_email = $args{'send_email'};
    my $max_areas  = $args{'max_areas'};
    my $files      = $args{'files'};
    my $test_mode  = $args{'test_mode'};

    my @files = @$files;
    my $lockfile;
    my $lockmgr;
    my $e_lock = Extract::LockFile->new( 'debug' => $debug );

    warn "Start job at: @{[ gmctime() ]} UTC\n" if $debug >= 1;

    #############################################################
    # semaphore for parsing the jobs
    # run only one extract.pl script at once while parsing
    #
    my $lockfile_extract = $spool->{'running'} . "/extract.pid";

    my $lockmgr_extract =
      $e_lock->create_lock( 'lockfile' => $lockfile_extract, 'wait' => 1 )
      or die "Cannot get lockfile $lockfile_extract, give up\n";

    # find a free job
    my $job_number;
    foreach my $number ( 1 .. $max_jobs ) {
        my $file = $spool->{'running'} . "/job${number}.pid";
        $job_number = $number;

        # lock pid
        if ( $lockmgr =
            $e_lock->create_lock( 'lockfile' => $file, max => $max_jobs ) )
        {
            $lockfile = $file;
            last;
        }
    }

    # Oops, all jobs are in use, give up
    if ( !$lockfile ) {
        $e_lock->remove_lock(
            'lockfile' => $lockfile_extract,
            'lockmgr'  => $lockmgr_extract
        );
        die "Cannot get lock for jobs 1..$max_jobs\n" . qx(uptime);
    }

    warn "Use lockfile $lockfile for extract\n" if $debug >= 1;

    my ( $list, $planet_osm ) = parse_jobs(
        'files'      => \@files,
        'dir'        => $spool->{'confirmed'},
        'max'        => $max_areas,
        'job_number' => $job_number,
        'lockfile'   => $lockfile_extract,
    );

    my @list = @$list;
    warn "job list: @{[ scalar(@list) ]}\n" if $debug >= 1;

    if ( !@list ) {
        print "Nothing to do for users\n" if $debug >= 2;

        # unlock jobN pid
        $e_lock->remove_lock( 'lockfile' => $lockfile, 'lockmgr' => $lockmgr );

        $e_lock->remove_lock(
            'lockfile' => $lockfile_extract,
            'lockmgr'  => $lockmgr_extract
        );

        exit 0;
    }

    warn "run jobs: " . Dumper( \@list ) if $debug >= 3;

    my $key     = get_job_id(@list);
    my $job_dir = $spool->{'running'} . "/$key";

    my ( $poly, $json, $wait_time ) = create_poly_files(
        'job_dir' => $job_dir,
        'list'    => \@list,
        'spool'   => $spool,
    );

    # EOF semaphone lock /extract.pid (cron job)
    $e_lock->remove_lock(
        'lockfile' => $lockfile_extract,
        'lockmgr'  => $lockmgr_extract
    );
    ############################################################

    my $stat = stat($planet_osm) or die "cannot stat $planet_osm: $!\n";

    # be paranoid, give up after N hours (java bugs?)
    &set_alarm( $alarm, "osmconvert" );

    ###########################################################
    # main
    my ( $system, $new_pbf_files, $tempfiles ) = run_extracts(
        'spool'      => $spool,
        'poly'       => $poly,
        'planet_osm' => $planet_osm
    );
    my @system = @$system;

    ###########################################################

    my $time      = time();
    my $starttime = $time;
    warn "Run ", join " ", @system, "\n" if $debug > 2;
    @system = 'true' if $test_mode;

    system(@system) == 0
      or die "system @system failed: $?";

    my $extract_time = time() - $time;
    warn "Running extract time: $extract_time seconds\n" if $debug >= 1;

    if ( !$option->{'osmconvert_enabled'} ) {
        &fix_pbf( $new_pbf_files, $test_mode );
        warn "Running fix pbf time: ", time() - $time, " seconds\n"
          if $debug >= 1;
    }

    # send out mail
    $time = time();
    my $errors = &convert_send_email(
        'json'             => $json,
        'send_email'       => $send_email,
        'alarm'            => $option->{alarm_convert},
        'test_mode'        => $test_mode,
        'planet_osm'       => $planet_osm,
        'planet_osm_mtime' => $stat->mtime,
        'extract_time'     => $extract_time,
        'wait_time'        => $wait_time,
        'start_time'       => $starttime,
        'keep'             => 1
    );

    warn "Total format convert and email check time: ", time() - $time,
      " seconds\n"
      if $debug >= 1;
    warn "Total time: ", time() - $starttime,
      " seconds, for @{[ scalar(@list) ]} job(s)\n"
      if $debug >= 1;
    warn "Number of errors: $errors\n" if $errors;

    # unlock jobN pid
    $e_lock->remove_lock( 'lockfile' => $lockfile, 'lockmgr' => $lockmgr );

    &cleanup_jobdir(
        'job_dir' => $job_dir,
        'spool'   => $spool,
        'json'    => $json,
        'keep'    => 1,
        'errors'  => $errors
    );

    if ( scalar @$tempfiles ) {
        unlink(@$tempfiles);
    }

    return $errors;
}

sub pause_mode {
    my $seconds = $option->{'pause_seconds'};
    my $file    = $option->{'pause_file'};

    return 0 if !-e $file;

    my $st = stat($file) or return 0;

    if ( time - $st->mtime < $seconds ) {
        warn "pause due $file is less than $seconds sec old\n";
        return 1;
    }

    unlink($file);
    return 0;
}

######################################################################
# main
#

# current running parallel job number (1..4)
my $max_jobs = $option->{'max_jobs'};
my $help;
my $timeout;
my $max_areas  = $option->{'max_areas'};
my $send_email = $option->{'send_email'};
my $spool_dir =
  $option->{'pro'} ? $option->{'spool_dir_pro'} : $option->{'spool_dir'};
my $test_mode = 0;

GetOptions(
    "debug=i"      => \$debug,
    "nice-level=i" => \$nice_level,
    "job=i"        => \$max_jobs,
    "timeout=i"    => \$timeout,
    "max-areas=i"  => \$max_areas,
    "send-email=i" => \$send_email,
    "planet-osm=s" => \$planet_osm,
    "spool-dir=s"  => \$spool_dir,
    "help"         => \$help,
    "test-mode!"   => \$test_mode,
) or die usage;

# we have to set the debug level late, after GetOptions()
$Extract::Utils::debug = $debug;

die usage if $help;

exit(0) if &pause_mode;

die "Max jobs: $max_jobs out of range!\n" . &usage
  if $max_jobs < 1 || $max_jobs > 32;
die "Max areas: $max_areas out of range 1..64!\n" . &usage
  if $max_areas < 1 || $max_areas > 64;

$option->{"planet"}->{"planet.osm"} = $planet_osm;

if ( $option->{"osmconvert_enabled"} && $max_areas != 1 ) {
    warn "Reset max_areas to 1 for osmconvert\n" if $debug >= 1;
    $max_areas = 1;
}

# full path for spool directories
while ( my ( $key, $val ) = each %$spool ) {
    $spool->{$key} = "$spool_dir/$val";
}

# get a list of waiting jobs Extract::Utils::get_jobs
my @files = get_jobs( $spool->{'confirmed'}, 256 );

if ( !scalar(@files) ) {
    print "Nothing to do in $spool->{'confirmed'}\n" if $debug >= 2;
    exit 0;
}

if ( defined $timeout ) {
    die "Timeout: $timeout out of range!\n" . &usage
      if ( $timeout < 1 || $timeout > 86_400 );
    $alarm = $timeout;
}

my $loadavg = &get_loadavg;
if ( $loadavg > $option->{max_loadavg} ) {
    my $max_loadavg_jobs = $option->{max_loadavg_jobs};
    if ( $max_loadavg_jobs >= 1 ) {
        warn
"Load avarage $loadavg is to high, reset max jobs to: $max_loadavg_jobs\n"
          if $debug >= 1;
        &program_output( $option->{'loadavg_status_program'} ) if $debug >= 1;

        $max_jobs = $max_loadavg_jobs;
    }

    else {
        warn "Load avarage $loadavg is to high, give up!\n";
        program_output( $option->{'loadavg_status_program'} );
        exit(1);
    }
}

my $errors = &run_jobs(
    'test_mode'  => $test_mode,
    'max_jobs'   => $max_jobs,
    'send_email' => $send_email,
    'max_areas'  => $max_areas,
    'files'      => \@files
);

# load average when the job is done
&get_loadavg;
exit($errors);

1;
