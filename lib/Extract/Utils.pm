#!/usr/local/bin/perl
# Copyright (c) 2012-2017 Wolfram Schneider, https://bbbike.org
#
# extract helper functions

package Extract::Utils;

use Encode qw/encode_utf8/;
use Digest::MD5 qw(md5_hex);
use GIS::Distance::Lite;
use JSON;
use File::Basename;
use File::stat;
use Data::Dumper;

require Exporter;
use base qw/Exporter/;
our @EXPORT = qw(save_request complete_save_request check_queue
  Param large_int square_km read_data file_mtime_diff
  file_size file_size_mb kb_to_mb get_json
  get_loadavg program_output random_user get_jobs
  json_compat touch_file store_data store_json checksum
  file_lnglat download_url);

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

# Extract::Utils::new->('q'=> $q, 'debug' => $debug)
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

sub parse_json_file {
    my $self = shift;

    my $file      = shift;
    my $non_fatal = shift;

    warn "Open json file '$file'\n" if $debug >= 2;

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
    my $json_text = $json->pretty->canonical->encode($obj);

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
    my $data  = $qq->param($param);
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

# cat file
sub read_data {
    my $file = shift;

    warn "open file '$file'\n" if $debug >= 3;

    my $fh = new IO::File $file, "r" or die "open $file: $!\n";
    binmode $fh, ":utf8";
    my $data;

    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;
    return $data;
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

# file size in KB
sub file_size {
    my $file = shift;

    my $st = stat($file) or die "stat $file: $!\n";

    return $st->size;
}

# file size in x.y MB
sub file_size_mb {
    my $file = shift;

    return kb_to_mb( file_size($file) );
}

# scale file size in x.y MB
sub kb_to_mb {
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

sub get_json {
    my $json_file = shift;
    my $json_text = read_data($json_file);
    my $json      = new JSON;
    my $obj       = $json->decode($json_text);
    json_compat($obj);

    warn "json: $json_file\n" if $debug >= 3;
    warn "json: $json_text\n" if $debug >= 3;

    return $obj;
}

sub get_loadavg {
    my @loadavg = ( qx(uptime) =~ /([\.\d]+),?\s+([\.\d]+),?\s+([\.\d]+)/ );

    warn "Current load average is: $loadavg[0]\n" if $debug >= 1;
    return $loadavg[0];
}

# display output of a program to STDERR
sub program_output {
    my $program = shift;
    my $fh = shift || \*STDERR;

    if ( -e $program && -x $program ) {
        open( OUT, "$program |" ) or die "$program: $!\n";
        print $fh "$program:\n";
        while (<OUT>) {
            print $fh $_;
        }
        close OUT;
    }
}

# get a list of email addresses, and return a random list
sub random_user {
    my @list = @_;

    my %hash = map { $_ => rand() } @list;

    @list = sort { $hash{$a} <=> $hash{$b} } keys %hash;

    if ( $debug >= 2 ) {
        warn join " ", @list, "\n";
    }

    return @list;
}

# get a list of json config files from a directory
sub get_jobs {
    my $dir = shift;

    # does not make sense to parse all files, the first $max is good enough
    my $max = shift;
    if ( !defined $max || $max <= 0 || $max > 10_000 ) {
        $max = 1024;
        warn "Reset max. json file parsing to $max\n" if $debug >= 2;
    }

    my $d = IO::Dir->new($dir);
    if ( !defined $d ) {
        warn "error directory $dir: $!\n";
        return ();
    }

    my @data;
    while ( defined( $_ = $d->read ) ) {
        next if !/\.json$/;

        if ( !-r "$dir/$_" ) {
            warn "Cannot read file $dir/$_: $!\n";
            next;
        }
        push @data, $_;

        if ( scalar(@data) >= $max ) {
            warn "Found $max waiting jobs, stop parsing\n" if $debug >= 1;
            last;
        }
    }
    undef $d;

    return @data;
}

# legacy
sub json_compat {
    my $obj = shift;

    # be backward compatible with old *.json files
    if ( !( exists $obj->{'coords'} && ref $obj->{'coords'} eq 'ARRAY' ) ) {
        $obj->{'coords'} = [];
    }
    return $obj;
}

# refresh mod time of file, to keep files in cache
sub touch_file {
    my $file      = shift;
    my $test_mode = shift;

    my @system = ( "touch", $file );

    warn "touch $file\n" if $debug >= 1;
    @system = 'true' if $test_mode;

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

sub store_json {
    my ( $file, $obj ) = @_;

    my $file_tmp = "$file.tmp";
    my $json     = new JSON;
    my $data     = $json->canonical->pretty->encode($obj);

    store_data( $file_tmp, $data );
    rename( $file_tmp, $file ) or die "rename $file: $!\n";
}

# compute SHA2 checksum for extract file
sub checksum {
    my $file = shift;
    my $type = shift || 'sha256';

    die "file $file does not exists\n" if !-f $file;

    my @checksum_command = $type eq 'md5' ? qw/md5sum/ : qw/shasum -a 256/;

    if ( my $pid = open( C, "-|" ) ) {
    }

    # child
    else {
        exec( @checksum_command, $file ) or die "Alert! Cannot fork: $!\n";
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

##################################
# storage

# file prefix depending on input PBF file, e.g. "planet_"
sub get_file_prefix {
    my $obj    = shift;
    my $option = shift;

    my $file_prefix = $option->{'file_prefix'} // 'planet_';
    my $format      = $obj->{'format'};

    # depending on the format (e.g. SRTM data) we may use a different planet
    if ( exists $option->{'planet'}->{$format} ) {
        $format =~ s/\..*/_/;
        $file_prefix = $format if $format;
    }

    warn "Use file prefix: '$file_prefix'\n" if $debug >= 2;
    return $file_prefix;
}

# store lng,lat in file name
sub file_lnglat {
    my $obj    = shift;
    my $option = shift;

    my $file = get_file_prefix($obj);
    my $coords = $obj->{coords} || [];

    # rectangle
    if ( !scalar(@$coords) ) {
        $file .= "$obj->{sw_lng},$obj->{sw_lat}_$obj->{ne_lng},$obj->{ne_lat}";
    }

    # polygon
    else {
        my $c = join '|', ( map { "$_->[0],$_->[1]" } @$coords );
        my $first = $coords->[0];

        my $md5 =
          substr( md5_hex($c), 0, 8 )
          ;    # first 8 characters of a md5 sum is enough
        $file .= join "_", ( $first->[0], $first->[1], $md5 );
    }

    return $file;
}

# store lng,lat in file name
sub download_url {
    my $obj    = shift;
    my $option = shift;

    my $ext = $obj->{'format'};

# Note: we skip double ".osm.osm.pbf" in file names, and use a single ".osm.pbf"
    $ext = "osm.$ext" if $ext !~ /^osm\./;

    my $url =
      $option->{'homepage'} . "/" . &file_lnglat( $obj, $option ) . "." . $ext;
    warn "download_url=$url\n" if $debug >= 2;

    return $url;
}

1;

__DATA__;
