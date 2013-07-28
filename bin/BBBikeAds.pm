#!/usr/bin/perl -w
# -*- perl -*-

# Author:  Wolfram Schneider
#
# Copyright (C) 2005,2006,2007,2008 Slaven Rezic. All rights reserved.
# Copyright (C) 2008-2011 Wolfram Schneider. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@users.sourceforge.net
# WWW:  http://bbbike.sourceforge.net
#

package BBBikeAds;

use strict;
use warnings;

our (
    $enable_google_adsense,        $enable_google_adsense_start,
    $enable_google_adsense_street, $enable_google_adsense_linkblock,
    $enable_google_adsense_street_linkblock
);

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
