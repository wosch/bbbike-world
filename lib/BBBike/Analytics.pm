#!/usr/local/bin/perl
#
# Copyright (C) 2008-2015 Wolfram Schneider. All rights reserved.
#
# BBBikeAnalytics - analytics code

package BBBike::Analytics;

use strict;
use warnings;

our %option = ( 'tracker_id' => "UA-286675-19" );

sub new {
    my $class = shift;
    my %args  = @_;

    my $self = { %option, %args };

    bless $self, $class;

    return $self;
}

sub google_analytics {
    my $self = shift;
    my $q    = $self->{'q'};

    my $url = $q->url( -base => 1 );

    if ( $url !~ m,^https?://(www|extract|download)[1-9]?\., ) {
        return "";    # devel installation
    }

    my $tracker_id = $self->{'tracker_id'};

    return <<EOF;

<script type="text/javascript">
//<![CDATA[
  var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
  document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
  //]]>
  </script><script type="text/javascript">
//<![CDATA[
  try {
  var pageTracker = _gat._getTracker("$tracker_id");
  pageTracker._trackPageview();
  } catch(err) {}
  //]]>
</script>

EOF
}

1;
