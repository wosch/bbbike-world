# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikeAds.pm - advertising module

package BBBike::Ads;

use strict;
use warnings;

our (
    $enable_google_adsense,        $enable_google_adsense_start,
    $enable_google_adsense_street, $enable_google_adsense_linkblock,
    $enable_google_adsense_street_linkblock
);

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
}

sub adsense_start_page {
    my $file = "/usr/local/www/etc/bbbike/adsense_start_page.js";

    return if !$enable_google_adsense || !-f $file;
    return
      if defined $enable_google_adsense_start && !$enable_google_adsense_start;

    open( FH, $file ) or return;

    my $data;
    while (<FH>) {
        $data .= $_;
    }

    print <<EOF;
<hr />
<br />
<div id="adsense_start_page">
$data
</div>
EOF
}

sub adsense_street_page {
    my $file = "/usr/local/www/etc/bbbike/adsense_street_page.js";

    return if !$enable_google_adsense || !-f $file;
    return
      if defined $enable_google_adsense_street
          && !$enable_google_adsense_street;

    open( FH, $file ) or return;

    my $data;
    while (<FH>) {
        $data .= $_;
    }

    print <<EOF;
<hr />
<div id="adsense_street_page">
$data
</div>
<br />
<br />
EOF
}

sub adsense_linkblock {
    my $file = "/usr/local/www/etc/bbbike/adsense_linkblock.js";

    return if !$enable_google_adsense || !-f $file;
    return
      if defined $enable_google_adsense_linkblock
          && !$enable_google_adsense_linkblock;

    open( FH, $file ) or return;

    my $data;
    while (<FH>) {
        $data .= $_;
    }

    print <<EOF;
<div id="adsense_linkblock">
$data
</div>
EOF
}

sub adsense_street_linkblock {
    my $file = "/usr/local/www/etc/bbbike/adsense_street_linkblock.js";

    return if !$enable_google_adsense || !-f $file;
    return
      if defined $enable_google_adsense_street_linkblock
          && !$enable_google_adsense_street_linkblock;

    open( FH, $file ) or return;

    my $data;
    while (<FH>) {
        $data .= $_;
    }

    print <<EOF;
<div id="adsense_street_linkblock">
$data
</div>
EOF
}

1;
