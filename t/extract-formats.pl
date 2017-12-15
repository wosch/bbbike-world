#!/usr/local/bin/perl
# Copyright (c) Nov 2015-2017 Wolfram Schneider, https://bbbike.org
#
# extract-formats.pl - test all extract formats

use lib qw(world/lib);
use Extract::Config;
use CGI qw(escape);

use strict;
use warnings;

my $debug     = 1;
my $random    = 1;
my $with_lang = 1;    # test with random lang

my $formats = $Extract::Config::formats;
my $server  = $ENV{'BBBIKE_DEV_SERVER'} || 'https://dev3.bbbike.org';
my $email   = $ENV{'BBBIKE_TEST_EMAIL'} || 'Nobody';
my $sw_lng  = -72.211;
my $sw_lat  = -13.807;
my $ne_lng  = -71.732;
my $ne_lat  = -13.235;

# list of supported languages
my @lang = ( "en", "de", "fr", "" );
my @words = (
    "Saarbrücken",                            "Berlin",
    "北京市",                               "Москва",
    "กรุงเทพมหานคร", "Łódz", "北京市 กรุงเทพมหานคร Москва Łódz 北京市"
);

sub message {
    print
qq{# please run now: ./world/t/extract-formats.pl | xargs -P2 -n1 -0 /bin/sh -c >/dev/null\0};
}

sub get_random_element {
    my $list = shift;

    my $i = int( rand( scalar(@$list) ) );

    return @$list[$i];
}

sub generate_urls {

    foreach my $key ( keys %$formats ) {
        next if $key =~ /^png-/;

        my $city = "etest";
        my $lang = "";

        if ($with_lang) {
            $lang = get_random_element( \@lang );

            if ($lang) {

                # put some random words into the city
                $city .= "+" . escape( get_random_element( \@words ) );
                $lang = "&lang=$lang";
            }
        }

        print qq{curl -sSf "$server/cgi/extract.cgi}
          . qq{?sw_lng=$sw_lng&sw_lat=$sw_lat}
          . ( $random ? int( rand(1_000_000) ) : "" )
          . qq{&ne_lng=$ne_lng&ne_lat=$ne_lat}
          . ( $random ? int( rand(1_000_000) ) : "" )
          . $lang
          . qq{&email=$email&as=1.933243109431466&pg=0.9964839602712444&coords=&oi=1}
          . qq{&city=$city&submit=extract&format=$key"\0};
    }
}

######################################################################
# main
#
&message;
&generate_urls;

1;
