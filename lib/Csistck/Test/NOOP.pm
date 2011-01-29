package Csistck::Test::NOOP;

use 5.010;
use strict;
use warnings;

use Csistck::Oper;
use Data::Dumper;

sub noop {
    my $args = shift;
    my $result = undef;

    if (ref $args eq "HASH") {
        if (defined $args->{result}) {
            $result = $args->{result};
        }
    } 
    else {
        $result = $args;
    }

    return sub {
        if ($result) {
            okay("NOOP passes");
        }
        else {
            fail("NOOP failed");
        }
    };
}

1;
