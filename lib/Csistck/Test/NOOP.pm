package Csistck::Test::NOOP;

use 5.010;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw/noop/;

use Csistck::Oper;
use Csistck::Test;

sub noop {
    my $args = shift;
    my $result = undef;

    # Set result
    if (ref $args eq "HASH") {
        if (defined $args->{result}) {
            $result = $args->{result};
        }
    } 
    else {
        $result = $args;
    }

    return Csistck::Test->new(
        sub { noop_check($result); },
        sub { noop_check($result); },
        "NOOP test"
    );
}

sub noop_check {
    my $result = shift;

    die("Set to failure") unless ($result);
}

1;
