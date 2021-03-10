#!/usr/local/bin/perl
#
# Copyright (c) Oct 2000-2021 Wolfram Schneider <wosch@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# cb.cgi - test script for async callback requests (instead email notifications)

use CGI;
use LWP;

use strict;
use warnings;

my $debug = 1;
my $q     = new CGI();
my $url   = $q->param("url");

print $q->header();
print $q->start_html( "-title" => 'bbbike extracts callback test script' );

print qq{\n<div>\n};

if ( defined $url ) {
    my $ua      = LWP::UserAgent->new;
    my $timeout = 5;
    $ua->timeout($timeout);

    warn "run callback service: $url\n" if $debug >= 1;
    my $res = $ua->head($url);

    # Check the outcome of the response
    if ( !$res->is_success ) {
        my $err = "HTTP error: " . $res->status_line . "\n";
        $err .= $res->content . "\n" if $debug >= 1;
        print "<p>$err</p>\n";
    }
    else {
        print "Size: ", $res->content_length;
    }

}
else {
    print "missing url parameter";
}

print qq{\n</div>\n};
print $q->end_html;
