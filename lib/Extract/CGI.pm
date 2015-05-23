#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# helper functions for extract.cgi

package Extract::CGI;

use CGI qw(escapeHTML);
use Data::Dumper;

use lib qw(world/lib);

use strict;
use warnings;

###########################################################################
# config
#

our $debug = 1;

##########################
# helper functions
#

# Extract::Poly::new->('debug'=> 2, 'option' => $option)
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

    # set global debug variable
    if ( $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }

    $self->{'database'} = "world/etc/tile/tile-pbf.csv";
}

1;

__DATA__;
