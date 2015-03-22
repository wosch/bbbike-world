# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikeTest.pm - helper function for ./world/t
#
# my $test = BBBikeTest->new('size' => 5_000);
# $test->myget("http://localhost/foobar.html")
# $test->myget_401("http://localhost/auth.html")
#

package BBBikeTest;

use Test::More;
use LWP;
use LWP::UserAgent;

use strict;
use warnings;

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = { %args };

    bless $self, $class;
    
    $self->init;
    
    return $self;
}

sub init {
    my $self = shift;
    
    my $ua = LWP::UserAgent->new;
    $ua->agent("BBBike.org-Test/1.1");
    
    $self->{'ua'} = $ua;
}

sub myget_401 {
    my $self = shift;
    my $url  = shift;
    my $size = shift || $self->{'size'};

    $size = 300 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $self->{'ua'}->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is(
        $res->status_line,
        "401 Unauthorized",
        "status code 401 Unauthorized - great!"
    );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

sub myget {
    my $self = shift;
    my $url  = shift;
    my $size = shift || $self->{'size'};

    $size = 10_000 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $self->{'ua'}->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

use constant MYGET => 3;
sub myget_counter { return MYGET; }
sub myget401_counter { return MYGET; }

1;

__DATA__;
