# based on the idea of http://search.cpan.org/~mons/Test-More-UTF8-0.04/lib/Test/More/UTF8.pm
#
# unfortunately, Test::More::UTF8 is not a debian package. You can use the
# version from CPAN, or use this simple rewrite

package Test::More::UTF8;

use Test::More ();
use warnings;
use strict;

sub import {
    foreach my $output_stream (qw(failure_output todo_output output)) {
        binmode Test::More->builder->$output_stream, ':utf8';
    }
}

1;

