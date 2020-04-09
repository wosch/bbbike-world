#!/usr/local/bin/perl
#
# Copyright (c) 2012-2015 Wolfram Schneider, https://bbbike.org
#
# Extract::Locale.pm - translations

package Extract::Locale;

use CGI qw/-utf-8 unescape escapeHTML/;
use CGI::Carp;

use IO::File;
use JSON;
use Data::Dumper;
use File::stat;
use File::Basename;
use HTTP::Date;
use Locale::Util;

require Exporter;
@EXPORT = qw(M);

# print M("help");
# print qq/foobar @{[ M("Last update") ]}: $date/;

use strict;
use warnings;

###########################################################################
# config

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

our $option = {
    'language'            => "en",
    'supported_languages' => [qw/en de fr ru/],
    'message_path'        => "../world/etc/extract",
};

# global variables
our $debug = 0;
my $msg;    # translations
my $language;

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {%args};

    bless $self, $class;

    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    my $q    = $self->{'q'};

    if ( defined $q && defined $q->param('debug') ) {
        $debug = int( $q->param('debug') );
    }

    # override default values from new('language' => "de")
    foreach my $key (%$option) {
        if ( exists $self->{$key} && defined $self->{$key} ) {
            $option->{$key} = $self->{$key};
        }
    }

    warn Dumper($option) if $debug >= 2;
    warn Dumper($self)   if $debug >= 2;

    $language = $self->get_language;
    $msg      = $self->get_msg($language);
}

# EOF config
###########################################################################

# cut&paste from extract.cgi
sub M {
    my $key = shift;

    my $text;
    if ( $msg && exists $msg->{$key} ) {
        $text = $msg->{$key};
    }
    else {
        if ( $debug >= 1 && $msg ) {
            warn "Unknown language '$language' translation: $key\n"
              if $debug >= 2 || $language ne "en";
        }
        $text = $key;
    }

    if ( ref $text eq 'ARRAY' ) {
        $text = join "\n", @$text, "\n";
    }

    return $text;
}

sub get_msg {
    my $self = shift;

    my $language = shift || $option->{'language'};

    my $file = $option->{'message_path'} . "/msg.$language.json";
    if ( !-e $file ) {
        warn "Language file $file not found, ignored\n" . qx(pwd);
        return {};
    }

    warn "Open message file $file for language $language\n" if $debug >= 1;
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

    warn Dumper($json_perl) if $debug >= 3;
    return $json_perl;
}

sub http_accept_language {
    my $self = shift;
    my $q    = $self->{'q'};

    my $requested_language = $q->http('Accept-language') || "";

    return "" if !$requested_language;

    my @lang = Locale::Util::parse_http_accept_language($requested_language);
    warn "Accept-language: " . join( ", ", @lang ) if $debug >= 2;

    foreach my $l (@lang) {
        if ( grep { $l eq $_ } @{ $option->{supported_languages} } ) {
            warn "Select language by browser: $l\n" if $debug >= 1;
            return $l;
        }
    }

    return "";
}

sub language_links {
    my $self = shift;
    my %args = @_;
    my $q    = $self->{'q'};

    my $with_separator = $args{'with_separator'};
    my $prefix         = $args{'prefix'};
    my $postfix        = $args{'postfix'};

    my $sep = ' | ';

    my $qq   = CGI->new($q);
    my $data = qq{<span id="language">\n};

    if ( defined $prefix ) {
        $data .= $prefix;
    }

    my $cookie_lang =
         $q->cookie( -name => "lang" )
      || $self->http_accept_language
      || "";

    my $counter = 0;
    foreach my $l ( @{ $option->{'supported_languages'} } ) {
        $data .= $sep if $counter++ && $with_separator;

        if ( $l ne $language ) {
            $l eq $option->{'language'} && !$cookie_lang
              ? $qq->delete("lang")
              : $qq->param( "lang", $l );

            $data .=
                qq{<a href="}
              . $qq->url( -query => 1, -relative => 1 )
              . qq{">$l</a>\n};
        }
        else {
            $data .=
qq{<span id="active_language">$l</span> <!-- active language -->\n};
        }

    }

    if ( defined $postfix ) {
        $data .= $postfix;
    }

    $data .= qq{</span> <!-- language -->\n};

    return $data;
}

sub get_language {
    my $self = shift;
    my $q    = $self->{'q'};

    # validate config
    if ( !grep { $_ eq $option->{"language"} }
        @{ $option->{'supported_languages'} } )
    {
        warn
"Unknown default language, reset to first value: @{[ $option->{'language'} ]}\n";
        $option->{"language"} = $option->{'supported_languages'}->[0];
    }

    my $language = $option->{'language'};
    return $language if !defined $q;

    my $lang =
         $q->param("lang")
      || $q->param("language")
      || $q->cookie( -name => "lang" )
      || $self->http_accept_language;

    return $language if !defined $lang;

    if ( grep { $_ eq $lang } @{ $option->{'supported_languages'} } ) {
        warn "get language: $lang\n" if $debug >= 1;
        return $lang;
    }

    # default language
    else {
        warn "default language: $language\n" if $debug >= 1;
        return $language;
    }
}

1;

__DATA__;
