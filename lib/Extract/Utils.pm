#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# extract config and libraries

package Extract::Utils;

use Encode qw/encode_utf8 decode_utf8/;
use Digest::MD5 qw(md5_hex);
use GIS::Distance::Lite;
use JSON;
use File::Basename;
use File::stat;
use Data::Dumper;

require Exporter;
use base qw/Exporter/;
our @EXPORT =
  qw(save_request complete_save_request check_queue Param large_int square_km);

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
    my $self = shift;

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
    my $self = shift;

    my @files = @_;

    my %hash = map { $_ => rand() } @files;

    return sort { $hash{$a} <=> $hash{$b} } keys %hash;
}

# compare 2 files and return the modification diff time in seconds
sub file_mtime_diff {
    my $self = shift;

    my $file1 = shift;
    my $file2 = shift;

    my $st1 = stat($file1) or die "stat $file1: $!\n";
    my $st2 = stat($file2) or die "stat $file2: $!\n";

    return $st1->mtime - $st2->mtime;
}

###########################################################################
# from extract.cgi
#

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

sub check_queue {
    my %args = @_;
    my $obj  = $args{'obj'};

    my $spool_dir_confirmed =
      $args{'spool_dir_confirmed'};    #"$spool_dir/" . $spool->{'confirmed'};

    # newest files from confirmed spool
    my @files = `ls -t $spool_dir_confirmed`;

    # argh!
    if ($?) {
        warn "opendir '$spool_dir_confirmed' failed: $?\n";
        return ( 10000, 10000 );       # fake error
    }

    my $mail_error = "";

    my $email_counter = 0;
    my $ip_counter    = 0;
    my $counter       = 1000;

    my $self = new Extract::Utils;
    foreach my $file (@files) {
        chomp $file;
        next if $file !~ /\.json$/;

        # check only the first 1000 files
        last if $counter-- < 0;

        my $perl = $self->parse_json_file("$spool_dir_confirmed/$file");
        if ( $perl->{"email"} eq $obj->{"email"} ) {
            $email_counter++;
        }
        if ( $perl->{"ip_address"} eq $obj->{"ip_address"} ) {
            $ip_counter++;
        }
    }

    warn qq[E-Mail spool counter: $obj->{"email"} => $email_counter, ],
      qq[ip address: $obj->{"ip_address"} => $ip_counter\n]
      if $debug >= 1;

    return ( $email_counter, $ip_counter );
}

### get coordinates from a string or a file handle
#sub extract_coords {
#    my $coords = shift;
#
#    if ( ref $coords ne "" ) {
#        my $fh_file = $coords;
#
#        binmode $fh_file, ":utf8";
#        local $/ = "";
#        my $data = <$fh_file>;
#        undef $fh_file;
#        $coords = $data;
#    }
#
#    return $coords;
#}

sub Param {
    my $qq    = shift;
    my $param = shift;
    my $data  = decode_utf8( $qq->param($param));
    $data = "" if !defined $data;

    $data =~ s/^\s+//;
    $data =~ s/\s+$//;
    $data =~ s/[\t\n]+/ /g;
    return $data;
}

# ($lat1, $lon1 => $lat2, $lon2);
sub square_km {
    my ( $x1, $y1, $x2, $y2, $factor ) = @_;
    $factor = 1 if !defined $factor;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    return int( $height * $width * $factor );
}

# 240000 -> 240,000
sub large_int {
    my $text = reverse shift;
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

1;

__DATA__;
